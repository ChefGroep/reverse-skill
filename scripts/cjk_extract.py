#!/usr/bin/env python3
"""Extract every line containing CJK from a file -> JSON {lineno: line}."""
import json, re, sys

CJK = re.compile(r'[\u3000-\u303F\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\uFF00-\uFFEF\u3040-\u30FF\uAC00-\uD7AF]')

src, out = sys.argv[1], sys.argv[2]
text = open(src, encoding='utf-8').read()
lines = text.split('\n')
entries = {}
for i, line in enumerate(lines, 1):
    if CJK.search(line):
        entries[str(i)] = line
with open(out, 'w', encoding='utf-8') as fh:
    json.dump(entries, fh, ensure_ascii=False, indent=1)
print(f"{src}: {len(entries)} CJK lines -> {out}")
