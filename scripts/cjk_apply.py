#!/usr/bin/env python3
"""Apply {lineno: english_line} map back onto the source file (line-level replace)."""
import json, sys

src, mapf = sys.argv[1], sys.argv[2]
m = json.load(open(mapf, encoding='utf-8'))
lines = open(src, encoding='utf-8').read().split('\n')
changed = missing = 0
for k, v in m.items():
    i = int(k) - 1
    if 0 <= i < len(lines):
        if v != lines[i]:
            lines[i] = v
            changed += 1
    else:
        missing += 1
open(src, 'w', encoding='utf-8').write('\n'.join(lines))
print(f"{src}: applied {changed}/{len(m)} (out-of-range: {missing})")
