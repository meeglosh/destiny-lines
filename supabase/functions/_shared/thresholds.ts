// GENERATED FILE — do not edit by hand.
//
// Rewritten by `python3 Scripts/calibrate/sweep.py --write`. The provenance block below
// is what makes these numbers defensible; a threshold without it is a guess (§6.2a).

export interface ThresholdProvenance {
  calibrated: boolean;
  date: string | null;
  model: string | null;
  datasetSize: number | null;
  precision: number | null;
  recall: number | null;
  note: string;
}

/// Gate 3 is the STRICT gate: a false positive means a nonsense reading, the failure
/// that generates refunds and one-star reviews (§6.2a step 5).
export const GATE3_CONFIDENCE_THRESHOLD = 0.75;

export const GATE3_PROVENANCE: ThresholdProvenance = {
  calibrated: false,
  date: null,
  model: null,
  datasetSize: null,
  precision: null,
  recall: null,
  note:
    "PROVISIONAL — not calibrated. Awaiting the labelled evaluation set (CLAUDE.md §14). " +
    "Run Scripts/calibrate/sweep.py --write to replace this file with measured values.",
};
