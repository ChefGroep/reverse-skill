#!/usr/bin/env python3
"""Verify: CJK count + remaining CJK lines per file."""
import re, sys

CJK = re.compile(r'[\u3000-\u303F\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\uFF00-\uFFEF\u3040-\u30FF\uAC00-\uD7AF]')
ok = True
for f in sys.argv[1:]:
    t = open(f, encoding='utf-8').read()
    hits = CJK.findall(t)
    print(f"{f}: CJK {len(hits)} | lines {t.count(chr(10))}")
    if hits:
        ok = False
        for n, line in enumerate(t.split('\n'), 1):
            if CJK.search(line):
                print(f"  L{n}: {line[:200]}")
print("RESULT:", "PASS" if ok else "FAIL")
