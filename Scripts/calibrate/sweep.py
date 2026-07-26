#!/usr/bin/env python3
"""Threshold sweep and constant generation — CLAUDE.md §6.2a steps 4-6.

Merges the labelled set with the two gate probes, sweeps every cutoff, prints the
precision/recall tradeoff, checks that Gate 1 performs evenly across skin tones, then
writes the constants files with their provenance.

    python3 Scripts/calibrate/sweep.py \
        --labels calibration/labels.csv \
        --gate1 calibration/gate1.csv \
        --gate3 calibration/gate3.csv \
        [--write]

Without --write it only reports. With --write it regenerates:
    DestinyLines/Core/Calibration/GateThresholds.swift
    supabase/functions/_shared/thresholds.ts

Objectives (§6.2a step 5) — deliberately asymmetric:
  Gate 1 is PERMISSIVE. A false negative rejects a real palm and loses a user; a false
  positive costs $0.0002 at Gate 3. We take the highest cutoff that still keeps palm
  recall at or above --gate1-min-recall.
  Gate 3 is STRICT. A false positive means a nonsense reading — the failure that drives
  refunds and one-star reviews. We take the lowest cutoff reaching --gate3-min-precision.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SWIFT_OUT = REPO / "DestinyLines" / "Core" / "Calibration" / "GateThresholds.swift"
TS_OUT = REPO / "supabase" / "functions" / "_shared" / "thresholds.ts"
GATE3_TS = REPO / "supabase" / "functions" / "_shared" / "gate3.ts"

# A stratum this far below overall recall is a fairness failure, not noise (§6.2a).
FAIRNESS_TOLERANCE = 0.05


def read_csv(path: Path) -> list[dict]:
    with path.open() as handle:
        return list(csv.DictReader(handle))


def load(labels_path: Path, gate1_path: Path, gate3_path: Path) -> list[dict]:
    labels = {row["filename"]: row for row in read_csv(labels_path)}
    gate1 = {row["filename"]: row for row in read_csv(gate1_path)} if gate1_path.exists() else {}
    gate3 = {row["filename"]: row for row in read_csv(gate3_path)} if gate3_path.exists() else {}

    merged = []
    for name, row in labels.items():
        label = row.get("label", "").strip().lower()
        if label not in {"palm", "not_palm"}:
            sys.exit(f"{name}: label must be 'palm' or 'not_palm', got {label!r}")
        entry = {
            "filename": name,
            "is_palm": label == "palm",
            "skin_tone": (row.get("skin_tone") or "unspecified").strip(),
            "gate1": None,
            "gate3": None,
        }
        raw1 = (gate1.get(name) or {}).get("gate1_confidence")
        if raw1 not in (None, "", "ERROR"):
            entry["gate1"] = float(raw1)
        raw3 = (gate3.get(name) or {}).get("gate3_confidence")
        is_palm3 = (gate3.get(name) or {}).get("gate3_is_palm")
        if raw3 not in (None, "", "ERROR") and is_palm3 not in (None, "", "ERROR"):
            # A "not a palm" verdict is evidence AGAINST, however confident the model is.
            entry["gate3"] = float(raw3) if int(is_palm3) == 1 else 0.0
        merged.append(entry)
    return merged


def metrics(rows: list[dict], key: str, threshold: float) -> dict:
    scored = [r for r in rows if r[key] is not None]
    tp = sum(1 for r in scored if r["is_palm"] and r[key] >= threshold)
    fp = sum(1 for r in scored if not r["is_palm"] and r[key] >= threshold)
    fn = sum(1 for r in scored if r["is_palm"] and r[key] < threshold)
    tn = sum(1 for r in scored if not r["is_palm"] and r[key] < threshold)
    precision = tp / (tp + fp) if tp + fp else 0.0
    recall = tp / (tp + fn) if tp + fn else 0.0
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
    return {
        "threshold": threshold,
        "tp": tp, "fp": fp, "fn": fn, "tn": tn,
        "precision": precision, "recall": recall, "f1": f1,
        "n": len(scored),
    }


def sweep(rows: list[dict], key: str) -> list[dict]:
    return [metrics(rows, key, t / 100) for t in range(0, 101, 5)]


def print_table(title: str, sweep_rows: list[dict]) -> None:
    print(f"\n{title}")
    print(f"{'cutoff':>7} {'prec':>7} {'recall':>7} {'F1':>7} {'TP':>5} {'FP':>5} {'FN':>5} {'TN':>5}")
    for m in sweep_rows:
        print(
            f"{m['threshold']:>7.2f} {m['precision']:>7.3f} {m['recall']:>7.3f} "
            f"{m['f1']:>7.3f} {m['tp']:>5} {m['fp']:>5} {m['fn']:>5} {m['tn']:>5}"
        )


def specificity(m: dict) -> float:
    """Share of non-palms correctly rejected."""
    denominator = m["tn"] + m["fp"]
    return m["tn"] / denominator if denominator else 0.0


def choose_gate1(rows: list[dict], min_recall: float, min_specificity: float) -> dict | None:
    """Highest cutoff admitting >= `min_recall` of palms while still rejecting things.

    The specificity floor matters: without it, a stratum the detector handles badly drags
    the viable cutoff down to ~0, where every image passes. That scores perfect recall,
    hides the bias from the fairness check, and ships a "gate" that gates nothing. When no
    cutoff satisfies both, the honest answer is to refuse and go collect more images.
    """
    viable = [
        m for m in sweep(rows, "gate1")
        if m["recall"] >= min_recall and specificity(m) >= min_specificity and m["threshold"] > 0
    ]
    return max(viable, key=lambda m: m["threshold"]) if viable else None


def choose_gate3(rows: list[dict], min_precision: float) -> dict | None:
    """Lowest cutoff whose accepted set is at least `min_precision` true palms."""
    viable = [m for m in sweep(rows, "gate3") if m["precision"] >= min_precision and m["tp"] > 0]
    return min(viable, key=lambda m: m["threshold"]) if viable else None


def fairness_report(rows: list[dict], threshold: float) -> tuple[bool, list[str]]:
    """Gate 1 recall per skin-tone stratum.

    A detector that under-performs on darker skin silently rejects those users more
    often. Without this check you would not find out (§6.2a).
    """
    palms = [r for r in rows if r["is_palm"] and r["gate1"] is not None]
    overall = sum(1 for r in palms if r["gate1"] >= threshold) / len(palms) if palms else 0.0

    def median(values: list[float]) -> float:
        ordered = sorted(values)
        mid = len(ordered) // 2
        if not ordered:
            return 0.0
        return ordered[mid] if len(ordered) % 2 else (ordered[mid - 1] + ordered[mid]) / 2

    overall_median = median([r["gate1"] for r in palms])

    lines = [f"  overall palm recall: {overall:.3f} (n={len(palms)}, median score {overall_median:.3f})"]
    ok = True
    strata = sorted({r["skin_tone"] for r in palms})
    for tone in strata:
        subset = [r for r in palms if r["skin_tone"] == tone]
        recall = sum(1 for r in subset if r["gate1"] >= threshold) / len(subset)
        tone_median = median([r["gate1"] for r in subset])
        flag = ""
        if recall < overall - FAIRNESS_TOLERANCE:
            flag = "  <-- FAILS: materially worse recall"
            ok = False
        # Compare score distributions too. Recall alone can look fine at a low cutoff
        # while the detector is in fact much less confident on this stratum — latent
        # bias that would surface the moment the threshold moves.
        elif tone_median < overall_median - 0.20:
            flag = "  <-- FAILS: much lower confidence distribution"
            ok = False
        if len(subset) < 10:
            flag += "  (stratum too small to trust)"
        lines.append(
            f"  {tone:>16}: recall {recall:.3f} (n={len(subset)}, median {tone_median:.3f}){flag}"
        )

    if strata == ["unspecified"]:
        lines.append("  WARNING: no skin_tone labels — the fairness check did not run.")
        ok = False
    return ok, lines


def production_model() -> str:
    match = re.search(r'GATE3_MODEL\s*=\s*"([^"]+)"', GATE3_TS.read_text())
    return match.group(1) if match else "unknown"


def write_constants(gate1: dict, gate3: dict, dataset_size: int, model: str) -> None:
    today = dt.date.today().isoformat()

    SWIFT_OUT.write_text(f'''// GENERATED FILE — do not edit by hand.
//
// Rewritten by `python3 Scripts/calibrate/sweep.py`. The provenance below is what makes
// these numbers defensible; a threshold without it is a guess (CLAUDE.md §6.2a).

import Foundation

/// Evidence behind a threshold. `calibrated == false` means the value is a placeholder
/// and MUST NOT ship to the App Store.
struct ThresholdProvenance {{
    let calibrated: Bool
    let date: String?
    let model: String?
    let datasetSize: Int?
    let precision: Double?
    let recall: Double?
    let note: String
}}

enum GateThresholds {{

    /// Gate 1 — on-device hand detection. Chosen as the highest cutoff that still admits
    /// the required share of real palms, because a false negative loses a user while a
    /// false positive costs $0.0002 at Gate 3 (§6.2a step 5).
    static let gate1Confidence: Float = {gate1["threshold"]:.2f}

    static let gate1Provenance = ThresholdProvenance(
        calibrated: true,
        date: "{today}",
        model: "VNDetectHumanHandPoseRequest",
        datasetSize: {dataset_size},
        precision: {gate1["precision"]:.4f},
        recall: {gate1["recall"]:.4f},
        note: "Measured over {gate1["n"]} scored images; TP {gate1["tp"]}, FP {gate1["fp"]}, FN {gate1["fn"]}, TN {gate1["tn"]}."
    )

    /// Gate 3 — server-side palm classifier. Mirrored in
    /// supabase/functions/_shared/thresholds.ts, which the Edge Function actually reads;
    /// both files are written by the same sweep so they cannot drift.
    static let gate3Confidence: Double = {gate3["threshold"]:.2f}

    static let gate3Provenance = ThresholdProvenance(
        calibrated: true,
        date: "{today}",
        model: "{model}",
        datasetSize: {dataset_size},
        precision: {gate3["precision"]:.4f},
        recall: {gate3["recall"]:.4f},
        note: "Measured over {gate3["n"]} scored images; TP {gate3["tp"]}, FP {gate3["fp"]}, FN {gate3["fn"]}, TN {gate3["tn"]}."
    )

    /// True when every gate threshold carries measured evidence. Asserted by the test
    /// suite so an uncalibrated build cannot quietly reach release.
    static var allCalibrated: Bool {{
        gate1Provenance.calibrated && gate3Provenance.calibrated
    }}
}}
''')

    TS_OUT.write_text(f'''// GENERATED FILE — do not edit by hand.
//
// Rewritten by `python3 Scripts/calibrate/sweep.py`. The provenance block below is
// what makes these numbers defensible; a threshold without it is a guess (§6.2a).

export interface ThresholdProvenance {{
  calibrated: boolean;
  date: string | null;
  model: string | null;
  datasetSize: number | null;
  precision: number | null;
  recall: number | null;
  note: string;
}}

/// Gate 3 is the STRICT gate: a false positive means a nonsense reading, the failure
/// that generates refunds and one-star reviews (§6.2a step 5).
export const GATE3_CONFIDENCE_THRESHOLD = {gate3["threshold"]:.2f};

export const GATE3_PROVENANCE: ThresholdProvenance = {{
  calibrated: true,
  date: "{today}",
  model: "{model}",
  datasetSize: {dataset_size},
  precision: {gate3["precision"]:.4f},
  recall: {gate3["recall"]:.4f},
  note:
    "Measured over {gate3["n"]} scored images; TP {gate3["tp"]}, FP {gate3["fp"]}, FN {gate3["fn"]}, TN {gate3["tn"]}.",
}};
''')
    print(f"\nwrote {SWIFT_OUT.relative_to(REPO)}")
    print(f"wrote {TS_OUT.relative_to(REPO)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--labels", type=Path, default=REPO / "calibration" / "labels.csv")
    parser.add_argument("--gate1", type=Path, default=REPO / "calibration" / "gate1.csv")
    parser.add_argument("--gate3", type=Path, default=REPO / "calibration" / "gate3.csv")
    parser.add_argument("--gate1-min-recall", type=float, default=0.98)
    parser.add_argument("--gate1-min-specificity", type=float, default=0.50,
                        help="floor on non-palms rejected, so Gate 1 cannot degenerate to accept-all")
    parser.add_argument("--gate3-min-precision", type=float, default=0.99)
    parser.add_argument("--write", action="store_true", help="regenerate the constants files")
    args = parser.parse_args()

    if not args.labels.exists():
        sys.exit(
            f"missing {args.labels}\n"
            "The labelled set is owner-supplied data (CLAUDE.md §14). See "
            "Scripts/calibrate/README.md for the collection spec."
        )

    rows = load(args.labels, args.gate1, args.gate3)
    palms = sum(1 for r in rows if r["is_palm"])
    print(f"dataset: {len(rows)} images ({palms} palm / {len(rows) - palms} not_palm)")

    if len(rows) < 200:
        print(f"WARNING: §6.2a asks for 200+ images; this set has {len(rows)}.")

    have_gate1 = any(r["gate1"] is not None for r in rows)
    have_gate3 = any(r["gate3"] is not None for r in rows)

    gate1_choice = gate3_choice = None
    fair = True

    if have_gate1:
        print_table("GATE 1 — on-device hand detection (bias: permissive)", sweep(rows, "gate1"))
        gate1_choice = choose_gate1(rows, args.gate1_min_recall, args.gate1_min_specificity)
        if gate1_choice:
            print(
                f"\n  chosen cutoff {gate1_choice['threshold']:.2f} "
                f"(precision {gate1_choice['precision']:.3f}, recall {gate1_choice['recall']:.3f})"
            )
            print("\nGATE 1 fairness by skin tone:")
            fair, lines = fairness_report(rows, gate1_choice["threshold"])
            print("\n".join(lines))
        else:
            print(
                f"\n  NO cutoff satisfies recall >= {args.gate1_min_recall} AND "
                f"specificity >= {args.gate1_min_specificity}.\n"
                "  Usually means one stratum scores far below the rest: the only cutoff\n"
                "  admitting those palms also admits everything else. Collect more images\n"
                "  for the weak stratum rather than lowering the floor."
            )
    else:
        print("\nGATE 1: no probe data (run Gate1Calibrate.swift)")

    if have_gate3:
        print_table("GATE 3 — palm classifier (bias: strict)", sweep(rows, "gate3"))
        gate3_choice = choose_gate3(rows, args.gate3_min_precision)
        if gate3_choice:
            print(
                f"\n  chosen cutoff {gate3_choice['threshold']:.2f} "
                f"(precision {gate3_choice['precision']:.3f}, recall {gate3_choice['recall']:.3f})"
            )
        else:
            print(f"\n  NO cutoff reaches precision >= {args.gate3_min_precision}")
    else:
        print("\nGATE 3: no probe data (run gate3_calibrate.py)")

    if not args.write:
        print("\n(report only — pass --write to regenerate the constants)")
        return

    if not (gate1_choice and gate3_choice):
        sys.exit("\nrefusing to write: both gates need a viable cutoff first")
    if not fair:
        sys.exit(
            "\nrefusing to write: Gate 1 is materially worse on at least one skin-tone "
            "stratum, or the set is not stratified. Shipping this would reject those "
            "users more often (§6.2a). Collect more images for the weak stratum."
        )

    write_constants(gate1_choice, gate3_choice, len(rows), production_model())
    print("\nNext: `xcodegen generate` is not needed, but redeploy the Edge Function:")
    print("  supabase functions deploy analyze-palm")


if __name__ == "__main__":
    main()
