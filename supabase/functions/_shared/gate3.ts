// Gate 3 (palm classifier) definition — CLAUDE.md §6.2.
//
// This file is the SINGLE SOURCE OF TRUTH for the classifier's model, prompt, and
// schema. analyze-palm imports it, and the offline calibration harness
// (Scripts/calibrate/gate3_calibrate.py) parses it, so a threshold can never be
// measured against a prompt that differs from the one in production.
//
// If you change the model or the prompt, the thresholds are invalidated: re-run the
// calibration sweep before shipping (§6.2a).

export const GATE3_MODEL = "gpt-5.4-nano";

export const GATE3_PROMPT =
  "Decide if the image is a clear photo of a human PALM (palmar side, lines visible). Backs of hands are not palms.";

export const GATE3_SCHEMA = {
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
} as const;
