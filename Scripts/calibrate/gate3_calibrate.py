#!/usr/bin/env python3
"""Gate 3 calibration probe — CLAUDE.md §6.2a step 3.

Runs the production palm classifier over a folder of images and records the RAW
confidence for each, not a pass/fail verdict, so one API pass supports the whole
threshold sweep.

The model, prompt, and schema are parsed out of supabase/functions/_shared/gate3.ts
rather than duplicated here. If that parse fails this script aborts: measuring a
threshold against a prompt that differs from production would produce a number that
looks calibrated and isn't.

    export OPENAI_API_KEY=sk-...
    python3 Scripts/calibrate/gate3_calibrate.py calibration/images > calibration/gate3.csv

Cost: ~$0.0002 per image (§6.2), so a 250-image set is about five cents.
"""

from __future__ import annotations

import base64
import csv
import io
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GATE3_TS = REPO / "supabase" / "functions" / "_shared" / "gate3.ts"
OPENAI_URL = "https://api.openai.com/v1/chat/completions"
EXTENSIONS = {".jpg", ".jpeg", ".png", ".heic"}


def load_production_config() -> tuple[str, str, dict]:
    """Read model/prompt/schema from the Edge Function's shared definition."""
    if not GATE3_TS.exists():
        sys.exit(f"missing {GATE3_TS}; cannot confirm the production classifier config")
    source = GATE3_TS.read_text()

    model = re.search(r'GATE3_MODEL\s*=\s*"([^"]+)"', source)
    prompt = re.search(r'GATE3_PROMPT\s*=\s*\n?\s*"((?:[^"\\]|\\.)*)"', source)
    schema = re.search(r"GATE3_SCHEMA\s*=\s*(\{.*?\})\s*as const;", source, re.S)
    if not (model and prompt and schema):
        sys.exit(
            "could not parse GATE3_MODEL/PROMPT/SCHEMA from gate3.ts.\n"
            "Refusing to guess: a threshold measured against the wrong prompt is not a "
            "calibration. Fix the parse or the file, then re-run."
        )

    # The schema literal is TS-ish but JSON-compatible once keys are quoted.
    raw = schema.group(1)
    raw = re.sub(r"(\w+)\s*:", lambda m: f'"{m.group(1)}":', raw)
    raw = raw.replace(",\n}", "\n}").replace(",}", "}")
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        sys.exit(f"could not parse GATE3_SCHEMA as JSON: {exc}")

    return model.group(1), prompt.group(1).encode().decode("unicode_escape"), parsed


def prepare_image(path: Path) -> str:
    """Match the client pipeline (§6.3): 1024px long edge, JPEG q≈0.8.

    Gate 3 sees the uploaded image, so calibrating on the original would measure a
    different input than production ever gets.
    """
    try:
        from PIL import Image
    except ImportError:
        sys.exit("Pillow required: python3 -m pip install --user Pillow")

    with Image.open(path) as im:
        im = im.convert("RGB")
        long_edge = 1024
        scale = min(1.0, long_edge / max(im.size))
        if scale < 1.0:
            im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
        buffer = io.BytesIO()
        im.save(buffer, format="JPEG", quality=80)
    return base64.b64encode(buffer.getvalue()).decode()


def classify(path: Path, api_key: str, model: str, prompt: str, schema: dict) -> dict:
    body = {
        "model": model,
        "max_completion_tokens": 100,
        "response_format": {
            "type": "json_schema",
            "json_schema": {"name": "palm_check", "strict": True, "schema": schema},
        },
        "messages": [
            {"role": "system", "content": prompt},
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{prepare_image(path)}",
                            "detail": "low",
                        },
                    }
                ],
            },
        ],
    }
    request = urllib.request.Request(
        OPENAI_URL,
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        payload = json.load(response)
    return json.loads(payload["choices"][0]["message"]["content"])


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: gate3_calibrate.py <image-directory>")

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        sys.exit("set OPENAI_API_KEY")

    model, prompt, schema = load_production_config()
    print(f"gate3: model={model}", file=sys.stderr)

    directory = Path(sys.argv[1])
    images = sorted(p for p in directory.iterdir() if p.suffix.lower() in EXTENSIONS)
    if not images:
        sys.exit(f"no images in {directory}")

    writer = csv.writer(sys.stdout)
    writer.writerow(["filename", "gate3_is_palm", "gate3_confidence", "gate3_reason"])

    for index, path in enumerate(images, 1):
        for attempt in range(3):
            try:
                verdict = classify(path, api_key, model, prompt, schema)
                writer.writerow(
                    [
                        path.name,
                        int(bool(verdict.get("is_palm"))),
                        verdict.get("confidence", ""),
                        verdict.get("reason", ""),
                    ]
                )
                break
            except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as exc:
                if attempt == 2:
                    writer.writerow([path.name, "ERROR", "", str(exc)[:60]])
                else:
                    time.sleep(2 * (attempt + 1))
        sys.stdout.flush()
        if index % 25 == 0:
            print(f"gate3: {index}/{len(images)}", file=sys.stderr)

    print(f"gate3: done ({len(images)} images)", file=sys.stderr)


if __name__ == "__main__":
    main()
