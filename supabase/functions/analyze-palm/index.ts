// analyze-palm (CLAUDE.md §6.5): the reading pipeline core.
//
// Order of operations, cheapest first, with the R2 delete guaranteed by `finally`:
//   auth → key-prefix check → entitlement → GATE 2 moderation → GATE 3 classifier
//   → reading call → persist → delete image.
// Rejections never consume the free reading or count against the ceiling (§6.2).

import { adminClient, json, userFromRequest } from "../_shared/auth.ts";
import { deleteR2Object, presignR2, r2ConfigFromEnv } from "../_shared/r2.ts";

// ------------------------------------------------------------------ constants

// One constant, per §7.1. Bake-off pending (owner item) before launch.
const READING_MODEL = "gpt-5.4-mini";
const CLASSIFIER_MODEL = "gpt-5.4-nano";

// $/1M tokens, kept in-function so historical usage_events rows stay accurate
// when prices change (§7.5). Update alongside model changes.
const RATES: Record<string, { input: number; cachedInput: number; output: number }> = {
  "gpt-5.4-mini": { input: 0.75, cachedInput: 0.075, output: 4.50 },
  "gpt-5.4-nano": { input: 0.20, cachedInput: 0.02, output: 1.25 },
};

// Gate 3 confidence threshold. PROVISIONAL pending the §6.2a calibration run —
// Gate 3 is deliberately the strict gate (a false positive means a nonsense reading).
const GATE3_CONFIDENCE_THRESHOLD = 0.75;

// Fair-use ceiling (§7.5).
const MONTHLY_PREMIUM_CEILING = 150;

// Output cap so a runaway generation cannot bill unbounded output (§7.5).
const MAX_OUTPUT_TOKENS = 3000;

const OPENAI = "https://api.openai.com/v1";

// ------------------------------------------------------------------ reading schema

const readingSchema = {
  type: "object",
  additionalProperties: false,
  required: ["version", "tier", "summary", "lines", "timeline", "key_insights", "is_palm"],
  properties: {
    version: { type: "integer" },
    tier: { type: "string", enum: ["free", "premium"] },
    // Refusal marker: model sets false when the image is not a human palm.
    is_palm: { type: "boolean" },
    summary: { type: "string" },
    lines: {
      type: "object",
      additionalProperties: false,
      required: ["life", "head", "heart", "fate"],
      properties: Object.fromEntries(
        ["life", "head", "heart", "fate"].map((k) => [k, {
          type: "object",
          additionalProperties: false,
          required: ["title", "subtitle", "body", "traits"],
          properties: {
            title: { type: "string" },
            subtitle: { type: "string" },
            body: { type: "string" },
            traits: { type: "array", items: { type: "string" } },
          },
        }]),
      ),
    },
    timeline: {
      type: "object",
      additionalProperties: false,
      required: ["near_future", "this_year", "long_term"],
      properties: {
        near_future: { type: "string" },
        this_year: { type: ["string", "null"] },
        long_term: { type: ["string", "null"] },
      },
    },
    key_insights: { type: "array", items: { type: "string" } },
  },
} as const;

// Static system prompt. Kept byte-identical across calls with the image last,
// so prompt caching applies to the prefix (§7.5).
const SYSTEM_PROMPT = `You are Madame Seraphine, the resident palm reader of the Destiny Lines carnival booth — warm, theatrical, kind, and speaking in the second person with vintage-carnival flair.

READ THE ACTUAL HAND. Study the visible line depth, length, breaks, forks, chains, islands, mounts, and finger proportions in the photograph, and reference specific observed features so the reading feels earned rather than generic.

HARD RULES:
- This is entertainment. Never present readings as fact or advice.
- Never mention death, lifespan, illness, diagnosis, pregnancy, medical matters, financial outcomes, investments, or legal matters.
- Keep everything warm, hopeful, and specific to what you see.
- If the image is not a clear human palm, set is_palm to false and leave other fields as empty strings or empty arrays.

TIER RULES (the "tier" field you are given):
- free: summary ~60 words; each line body ~40 words; traits: empty arrays; timeline: only near_future (set this_year and long_term to null); exactly 2 key_insights.
- premium: summary ~150 words; each line body 120-180 words with 3-5 traits; all three timeline entries ~100 words each; exactly 4 key_insights.

Line subtitles are fixed copy:
- life: "Your vitality and major life changes."
- head: "Your mind, intellect and decision making."
- heart: "Your emotions, love and relationships."
- fate: "Your path, purpose and destiny."

Set version to 1 and echo the given tier.`;

// ------------------------------------------------------------------ handler

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  const user = await userFromRequest(req);
  if (!user) return json({ code: "unauthenticated" }, 401);

  let objectKey: string;
  try {
    const body = await req.json();
    objectKey = body.objectKey;
  } catch {
    return json({ code: "bad_request" }, 400);
  }

  // A user must not be able to analyze another user's object (§6.5).
  if (typeof objectKey !== "string" || !objectKey.startsWith(`palms/${user.id}/`)) {
    return json({ code: "forbidden" }, 403);
  }

  const db = adminClient();
  const r2 = r2ConfigFromEnv();

  // The delete in `finally` is the §6.1 guarantee: every exit path below —
  // success, rejection, timeout, parse failure, throw — ends with the image gone.
  try {
    // ---- Entitlement, BEFORE spending anything (§6.5).
    const { data: profile } = await db
      .from("profiles")
      .select("free_readings_used, subscription_status, subscription_expires_at")
      .eq("id", user.id)
      .single();
    if (!profile) return json({ code: "no_profile" }, 403);

    const subscribed = (profile.subscription_status === "active" ||
      profile.subscription_status === "trial") &&
      (!profile.subscription_expires_at ||
        new Date(profile.subscription_expires_at) > new Date());

    if (!subscribed && profile.free_readings_used >= 1) {
      return json({ code: "payment_required" }, 402);
    }

    // Fair-use ceiling for subscribers (§7.5).
    if (subscribed) {
      const monthStart = new Date();
      monthStart.setUTCDate(1);
      monthStart.setUTCHours(0, 0, 0, 0);
      const { count } = await db
        .from("readings")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id)
        .gte("created_at", monthStart.toISOString());
      if ((count ?? 0) >= MONTHLY_PREMIUM_CEILING) {
        return json({
          code: "rate_limited",
          message: "Even destiny must catch its breath. Return next month for more readings.",
        }, 429);
      }
    }

    const tier = subscribed ? "premium" : "free";
    const imageURL = await presignR2(r2, "GET", objectKey, 300);

    // ---- GATE 2: safety moderation, every upload, no exceptions (§6.2).
    const modResponse = await openai("/moderations", {
      model: "omni-moderation-latest",
      input: [{ type: "image_url", image_url: { url: imageURL } }],
    });
    const flagged = modResponse.results?.[0]?.flagged === true;

    if (flagged) {
      await db.from("moderation_events").insert({
        user_id: user.id, gate: "safety", outcome: "rejected", reason: "flagged",
      });
      await recordStrike(db, user.id);
      // Generic code only — a specific rejection is a probing oracle (§6.2).
      return json({ code: "rejected", reason: "flagged" }, 422);
    }
    await db.from("moderation_events").insert({
      user_id: user.id, gate: "safety", outcome: "passed",
    });

    // ---- GATE 3: cheap palm classifier (§6.2).
    const gate3 = await openai("/chat/completions", {
      model: CLASSIFIER_MODEL,
      max_completion_tokens: 100,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "palm_check",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            required: ["is_palm", "confidence", "reason"],
            properties: {
              is_palm: { type: "boolean" },
              confidence: { type: "number" },
              reason: {
                type: "string",
                enum: ["no_hand", "back_of_hand", "too_dark", "too_blurry", "partial", "ok"],
              },
            },
          },
        },
      },
      messages: [
        {
          role: "system",
          content:
            "Decide if the image is a clear photo of a human PALM (palmar side, lines visible). Backs of hands are not palms.",
        },
        {
          role: "user",
          content: [{ type: "image_url", image_url: { url: imageURL, detail: "low" } }],
        },
      ],
    });

    logUsage(db, user.id, CLASSIFIER_MODEL, tier, gate3.usage);
    const verdict = JSON.parse(gate3.choices[0].message.content);

    if (!verdict.is_palm || verdict.confidence < GATE3_CONFIDENCE_THRESHOLD) {
      const reason = verdict.reason === "ok" ? "partial" : verdict.reason;
      await db.from("moderation_events").insert({
        user_id: user.id, gate: "classifier", outcome: "rejected", reason,
      });
      return json({ code: "rejected", reason }, 422);
    }
    await db.from("moderation_events").insert({
      user_id: user.id, gate: "classifier", outcome: "passed", reason: "ok",
    });

    // ---- The reading call. detail:"high" explicitly — never auto (§7.1a).
    const completion = await openai("/chat/completions", {
      model: READING_MODEL,
      max_completion_tokens: MAX_OUTPUT_TOKENS,
      response_format: {
        type: "json_schema",
        json_schema: { name: "palm_reading", strict: true, schema: readingSchema },
      },
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        {
          role: "user",
          content: [
            { type: "text", text: `tier: ${tier}` },
            { type: "image_url", image_url: { url: imageURL, detail: "high" } },
          ],
        },
      ],
    });

    logUsage(db, user.id, READING_MODEL, tier, completion.usage);

    const reading = JSON.parse(completion.choices[0].message.content);

    // Model-level refusal marker (non-palm slipped through the gates).
    if (reading.is_palm === false) {
      await db.from("moderation_events").insert({
        user_id: user.id, gate: "classifier", outcome: "rejected", reason: "no_hand",
      });
      return json({ code: "rejected", reason: "no_hand" }, 422);
    }
    delete reading.is_palm;

    // ---- Persist, then count the free reading ONLY on success (§6.5).
    await db.from("readings").insert({ user_id: user.id, tier, content: reading });
    if (!subscribed) {
      await db.from("profiles")
        .update({ free_readings_used: profile.free_readings_used + 1 })
        .eq("id", user.id);
    }

    return json({ reading });
  } catch (error) {
    console.error("analyze-palm failed:", error instanceof Error ? error.message : "unknown");
    return json({ code: "server_error" }, 500);
  } finally {
    // §6.1.1: the image dies here on every path. The bucket lifecycle rule is
    // only the backstop for a killed isolate.
    await deleteR2Object(r2, objectKey);
  }
});

// ------------------------------------------------------------------ helpers

async function openai(path: string, body: unknown): Promise<any> {
  const response = await fetch(`${OPENAI}${path}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OpenAI ${path} ${response.status}: ${text.slice(0, 300)}`);
  }
  return response.json();
}

/// usage_events row from the API's actual token counts (§7.5). Fire-and-forget.
function logUsage(db: any, userId: string, model: string, tier: string, usage: any) {
  if (!usage) return;
  const rate = RATES[model] ?? { input: 0, cachedInput: 0, output: 0 };
  const cached = usage.prompt_tokens_details?.cached_tokens ?? 0;
  const input = usage.prompt_tokens ?? 0;
  const output = usage.completion_tokens ?? 0;
  const cost = ((input - cached) * rate.input + cached * rate.cachedInput + output * rate.output) / 1e6;
  db.from("usage_events").insert({
    user_id: userId,
    model,
    tier,
    input_tokens: input,
    cached_tokens: cached,
    output_tokens: output,
    cost_usd: cost.toFixed(6),
  }).then(() => {});
}

/// Strike on a Gate 2 flag; 3 strikes in 24h → cooldown (§6.2). Never a permanent ban.
async function recordStrike(db: any, userId: string) {
  const dayAgo = new Date(Date.now() - 86_400_000).toISOString();
  const { count } = await db
    .from("moderation_events")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("outcome", "rejected")
    .eq("gate", "safety")
    .gte("created_at", dayAgo);

  const updates: Record<string, unknown> = {};
  const { data } = await db.from("profiles").select("moderation_strikes").eq("id", userId).single();
  updates.moderation_strikes = (data?.moderation_strikes ?? 0) + 1;
  if ((count ?? 0) + 1 >= 3) {
    updates.cooldown_until = new Date(Date.now() + 6 * 3600_000).toISOString();
  }
  await db.from("profiles").update(updates).eq("id", userId);
}
