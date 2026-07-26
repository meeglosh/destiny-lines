# Gate threshold calibration

The Gate 1 and Gate 3 cutoffs are hardcoded constants. Nothing in this system
self-calibrates — the models answer questions, they do not tune your thresholds. The only
defensible way to set them is the offline evaluation below (CLAUDE.md §6.2a).

Until it runs, `GateThresholds.allCalibrated` is `false` and the values are placeholders.

---

## 1. Collect the labelled set (owner task)

**This cannot be generated.** Synthetic or scraped images would produce numbers that look
evidence-backed and aren't, which is worse than an honest placeholder. Target **200+
images, roughly half palms and half negatives**.

Make it representative of what real users will actually send:

- **Lighting** — dim rooms, hard sun, mixed indoor colour temperature, backlit.
- **Skin tone** — the full range, and enough of each to measure (**10+ per stratum**, more
  is better). This is not a nicety: a hand detector that under-performs on darker skin
  silently rejects those users at a higher rate, and without stratified labels you will
  never find out. The sweep refuses to write constants if a stratum lags.
- **Angles and rotation**, motion blur, partial hands, busy backgrounds, gloves, rings.
- **The negatives you actually expect**: backs of hands, faces, pets, feet, screens,
  random objects.

Put every image in one folder and write `calibration/labels.csv`:

```csv
filename,label,reason,skin_tone,lighting,notes
palm_001.jpg,palm,ok,type_ii,indoor_dim,
palm_002.jpg,palm,ok,type_vi,hard_sun,ring
cat_014.jpg,not_palm,no_hand,,indoor,
dorsum_007.jpg,not_palm,back_of_hand,type_iv,outdoor,
```

- `label` — `palm` or `not_palm` (required).
- `reason` — expected rejection reason for negatives: `no_hand`, `back_of_hand`,
  `too_dark`, `too_blurry`, `partial`.
- `skin_tone` — any consistent scheme (Fitzpatrick `type_i`…`type_vi` works). Required on
  palms for the fairness check.
- `lighting`, `notes` — free text, for your own analysis.

`calibration/` is gitignored: these are photographs of people's hands. Keep them out of
the repo and off shared storage, and delete them when the sweep is done.

## 2. Run the probes

Both record **raw confidences**, not pass/fail, so one pass supports the whole sweep.

```bash
# Gate 1 — Vision, on-device model, runs locally and free
swift Scripts/calibrate/Gate1Calibrate.swift calibration/images > calibration/gate1.csv

# Gate 3 — the production classifier (~$0.0002/image, so ~$0.05 for 250)
export OPENAI_API_KEY=sk-...
python3 Scripts/calibrate/gate3_calibrate.py calibration/images > calibration/gate3.csv
```

Gate 1 runs the same request as `ImageProcessor.detectHand`; Gate 3 reads its model,
prompt, and schema from `supabase/functions/_shared/gate3.ts`, the same file the Edge
Function imports, and aborts if it cannot. A threshold measured against a different prompt
than production runs is not a calibration.

## 3. Sweep, inspect, commit

```bash
python3 Scripts/calibrate/sweep.py                 # report only
python3 Scripts/calibrate/sweep.py --write         # regenerate the constants
```

The report prints precision/recall at every cutoff for both gates, plus Gate 1 recall
broken down by skin tone. **Read it before writing** — the recommendation encodes the
§6.2a objectives but the tradeoff is a product decision:

- **Gate 1 → permissive.** Highest cutoff still admitting ≥98% of real palms
  (`--gate1-min-recall`). A false negative loses a user; a false positive costs $0.0002.
- **Gate 3 → strict.** Lowest cutoff reaching ≥99% precision (`--gate3-min-precision`).
  A false positive here means a nonsense reading — refunds and one-star reviews.

`--write` regenerates both constants files with provenance (date, model, dataset size,
measured precision/recall). It **refuses** to write if either gate has no viable cutoff,
or if Gate 1 lags on any skin-tone stratum.

Then:

```bash
supabase functions deploy analyze-palm       # ship the new Gate 3 threshold
```

and remove the `.disabled` trait from `thresholdsAreCalibratedBeforeRelease` in
`DestinyLinesTests/CalibrationTests.swift` — that test is the tripwire preventing an
uncalibrated build from reaching the App Store.

## 4. Re-run when anything changes

The thresholds are only valid for the model and prompt they were measured against.
Changing `GATE3_MODEL` or `GATE3_PROMPT` invalidates them — re-run the sweep.
