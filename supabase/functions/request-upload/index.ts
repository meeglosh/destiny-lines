// request-upload (CLAUDE.md §6.4): authenticated users get a presigned PUT slot.
// Rate limit: 5 upload URLs per user per hour; moderation cooldown enforced here.

import { adminClient, json, userFromRequest } from "../_shared/auth.ts";
import { presignR2, r2ConfigFromEnv } from "../_shared/r2.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  const user = await userFromRequest(req);
  if (!user) return json({ code: "unauthenticated" }, 401);

  const db = adminClient();

  // Moderation cooldown (§6.2 abuse handling).
  const { data: profile } = await db
    .from("profiles")
    .select("cooldown_until")
    .eq("id", user.id)
    .single();

  if (profile?.cooldown_until && new Date(profile.cooldown_until) > new Date()) {
    return json(
      { code: "cooldown", message: "The spirits need a rest. Return a little later." },
      429,
    );
  }

  // Rate limit: 5 slots per rolling hour, counted via moderation_events 'device' gate
  // markers written at slot issuance.
  const hourAgo = new Date(Date.now() - 3600_000).toISOString();
  const { count } = await db
    .from("moderation_events")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("gate", "device")
    .gte("created_at", hourAgo);

  if ((count ?? 0) >= 5) {
    return json(
      { code: "rate_limited", message: "So many futures, so fast! Give the crystal an hour." },
      429,
    );
  }

  // Record slot issuance (the client already passed Gate 1 on-device to get here).
  await db.from("moderation_events").insert({
    user_id: user.id,
    gate: "device",
    outcome: "passed",
  });

  const objectKey = `palms/${user.id}/${crypto.randomUUID()}.jpg`;
  const uploadURL = await presignR2(r2ConfigFromEnv(), "PUT", objectKey, 300);

  return json({ uploadURL, objectKey });
});
