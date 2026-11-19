#!/usr/bin/env python3
"""Run every Godot source suite with timeouts and retain machine-readable evidence."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import time

parser = argparse.ArgumentParser()
parser.add_argument('--godot', required=True)
parser.add_argument('--output', default='qa-logs')
args = parser.parse_args()
engine = str(Path(args.godot).resolve())
project = Path(__file__).resolve().parents[1] / 'game'
output = Path(args.output).resolve()
output.mkdir(parents=True, exist_ok=True)
results = []
suites = [('import', ['--editor', '--quit'])] + [(p.stem, ['--script', 'res://tests/' + p.name]) for p in sorted((project / 'tests').glob('*.gd'))]
for name, flags in suites:
    start = time.monotonic()
    try:
        proc = subprocess.run([engine, '--headless', '--path', str(project), *flags], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace', timeout=120)
        text, code = proc.stdout, proc.returncode
    except subprocess.TimeoutExpired as exc:
        text, code = 'TIMEOUT\n' + str(exc.stdout or ''), 124
    (output / (name + '.log')).write_text(text, encoding='utf-8')
    passed = code == 0 and not re.search(r'SCRIPT ERROR|Parse Error|Invalid call|^ERROR:', text, re.M)
    results.append({'suite': name, 'passed': passed, 'exit_code': code, 'seconds': round(time.monotonic()-start, 2)})
    print(('PASS ' if passed else 'FAIL ') + name, flush=True)
    if not passed:
        print(text[-6000:], flush=True)
    if name == 'import' and not passed:
        break
(output / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
print(f'{sum(r["passed"] for r in results)}/{len(results)} checks passed (including resource import)')
sys.exit(0 if len(results) == len(suites) and all(r['passed'] for r in results) else 1)
