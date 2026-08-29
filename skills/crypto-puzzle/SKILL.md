---
name: crypto-puzzle
description: |
  Cryptanalysis without exploit-context: classical ciphers (Caesar, Vigenère,
  substitution), XOR and repeating-key XOR, RSA attacks (small exponent,
  common modulus, Wiener, Fermat factoring, related messages), hash length
  extension, CBC padding oracles, ECB patterns, JWT/secret brute-force.
  Use for CTF crypto challenges, weak-key analysis, token crypto review.
  Not for TLS/email chain audits (email-security / dns-audit cover those).
---

# crypto-puzzle

Cryptanalyse-workflow: van ruw materiaal naar onthulde plaintext, reproduceerbaar
en met verificatie. Materiaal is lokaal; online orakels (factordb) alleen lezend
en zonder gevoelige payloads.

## ACTION REQUIRED（读完后立刻执行）

1. `NOW`: classificeer het materiaal (Fase 1) vóór toolkeuze; alles wat al een
   bekend protocol is (TLS/JWT/SAML) routeert eerst naar de bijbehorende skill.
2. `NEXT`: check `../tool-index.md` (python3, openssl, hashcat beschikbaar);
   ontbrekend → bootstrap, geen pad-gokken.
3. `ACT`: Fase 1 starten; elke stap command + output als evidence
   (`../ops/evidence-finding-path.md`).

## Fase 1 — Identificatie

- Alfabet en structuur: hex? base64-families? percentages/letterfrequentie?
- Frequentieanalyse EN en NL (e/t/a vs e/n/a) → substitutie-achtig?
- ROT-brute (26 + ROT47):

```bash
python3 -c "s='...'; [print(i, ''.join(chr((ord(c)-97+i)%26+97) if c.isalpha() else c for c in s)) for i in range(26)]"
```

- Vigenère: index of coincidence per keylengte; kasiski-herhalingen.
- Substitutie-puzzels: handmatig patroon-analyse (woordvormen `_ _ _ _` + apostrof).

## Fase 2 — XOR

```python
# single-byte
for k in range(256):
    out = bytes(b ^ k for b in data)
    if out[:4] in (b'PK\x03\x04', b'\x89PNG', b'GIF8') or all(32 <= c < 127 for c in out[:32]):
        print(hex(k), out[:64])
```

- Repeating-key XOR: keylengte via Hamming-afstand op blokken; daarna per
  kolom single-byte oplossen. (Cryptopals stijl; python standaard-bibliotheek.)
- Bekende plaintext (headers) → keystream-fragment → key-herhaling bewijzen.

## Fase 3 — RSA

Checklijst in volgorde van goedkoop naar duur:

| Poging | Voorwaarde | Route |
|---|---|---|
| n al gefactord | klein n / bekende modulus | factordb.com lookup (alleen n) |
| kleine e (3) | e klein, kort bericht | cube-root over de integers |
| common modulus | zelfde n, twee e's | gemeenschappelijke modulus-aanval |
| Wiener | d klein (e groot ~ n^0.75) | kettingbreuken convergenten |
| Fermat | p ≈ q | a=ceil(sqrt(n)) iteratie |
| related messages | twee ciphertexts, lineair verwant | Franklin-Reiter |
| partial key | deel van p/d gelekt | Coppersmith-achtige recovery |

```python
from sympy import integer_nthroot
# kleine e: m = integer_nthroot(c, e)[0] als het resultaat^e == c
```

Tools: python3+sympy; `RsaCtfTool` alleen via eigen mirror (niet standaard
geïnstalleerd); openssl voor modulus-extractie uit certificates: `openssl x509 -noout -modulus`.

## Fase 4 — Hashes en MAC

- Length extension (MD5/SHA1/SHA256 op secret-prefix): hashpumpy-route of
  python-implementatie; vereist originele MAC + message-lengte-kennis.
- JWT: header/payload base64url; `alg=none`-check; secret-brute met hashcat
  mode 16500 en `$SECLISTS_PATH/Passwords/Common-Credentials/10-million-password-list-top-1000.txt`.
- zwakke secret-obscuratie: base64/hex/xor-laagjes afpellen.

## Fase 5 — Block cipher patronen

- ECB: gelijke blokken in ciphertext (penguin-herkenning); blokgrootte bepalen.
- CBC padding oracle (alleen tegen eigen lab-doel met grant): laatste byte
  0x01 vervalsen; script stap-voor-stap, timebox.
- IV-manipulatie: eerste blok plaintext flip via IV XOR-delta.

## Verificatie en rapportage

- Elke oplossing eindigt met een onafhankelijke check: gedecrypteerde output
  opnieuw versleutelen met gevonden parameters en ciphertext vergelijken.
- Gevonden keys/secrets: in evidence alleen als sha256[:12]-fingerprint;
  de waarde zelf alleen in de kluis.
- Zwakke parameters (e=3, ECB, secret < 40 bits) worden een Finding met
  fix-advies, niet alleen een opgeloste puzzel.
