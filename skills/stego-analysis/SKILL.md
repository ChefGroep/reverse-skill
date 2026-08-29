---
name: stego-analysis
description: |
  Steganography detection and extraction for images, audio, video, documents,
  text and binaries: LSB bitplane analysis in PNG/BMP, JPEG DCT (steghide),
  zsteg/stegsolve workflows, audio spectrograms, whitespace and zero-width
  characters, appended-data-after-EOF, binwalk extraction. Use for CTF
  forensics challenges, hidden malware payloads, and evidence recovery in
  authorized investigations (steganografie, verborgen data).
---

# stego-analysis

Steganografie-detectie en -extractie. Werkt uitsluitend op lokaal aanwezig
materiaal (offline sample preset); geen uploads naar online decoders.

## ACTION REQUIRED（读完后立刻执行）

1. `NOW`: bepaal dat het materiaal lokaal is (`offline-sample` preset bij
   `case-init.sh`); online-decoders (AperiSolve e.d.) zijn verboden —
   materiaal verlaat de host niet.
2. `NOW`: bepaal bestandstype exact (Fase 1) vóór enige toolkeuze.
3. `NEXT`: check `../tool-index.md`; ontbrekende tools → bootstrap of
   apt-hint; paden nooit gokken.
4. `ACT`: volg de type-matrix in Fase 2; elke extractie met command + output
   als evidence vastleggen (`../ops/evidence-finding-path.md`).

## Toepassingsgebied

- CTF forensics (verborgen payload in afbeelding/audio/document).
- Malware-triage: payload verstopt in certificate-afbeeldingen, banner-JPEGs.
- Bewijsrecoverie in geautoriseerd onderzoek (verborgen bericht, exfil-kanaal).

## Fase 1 — Triage

```bash
file sample.*
binwalk sample.*                  # ingebedde bestanden/compressie
strings -n 8 sample.* | head -50
exiftool sample.* 2>/dev/null || identify -verbose sample.png 2>/dev/null | head -40
# bestandsgrootte vs verwachte: append na EOF?
python3 - <<'PY'
import sys
d=open(sys.argv[1],'rb').read()
print("grootte:",len(d))
for magic,name in [(b'\x50\x4b\x03\x04','ZIP'),(b'\x1f\x8b\x08','GZIP'),(b'BZh','BZIP2'),(b'\xfd7zXZ','XZ'),(b'Rar!','RAR'),(b'\x89PNG','PNG'),(b'\xff\xd8\xff','JPEG')]:
    i=d.rfind(magic)
    if i>0: print(f"{name} magic op offset {i}")
PY
```

Vergelijk met een clean referentiebestand van hetzelfde type/formaat indien beschikbaar.

## Fase 2 — Type-matrix

### PNG / BMP
- `zsteg -a sample.png` (Linux: zie tool-index; anders LSB-script hieronder).
- LSB-bitplanen handmatig:

```bash
python3 - <<'PY'
from PIL import Image
im=Image.open("sample.png"); px=list(im.getdata())
for ch,name in enumerate("RGB"):
    bits="".join(str(p[ch]&1) for p in px[:8192])
    bs=bytes(int(bits[i:i+8],2) for i in range(0,len(bits)-7,8))
    print(name, bs[:64])
PY
```
- Alpha-kanaal, R/G/B-planen afzonderlijk; `stegsolve` (GUI, alleen eigen desktop).
- Palette-PNG: kleurvolgorde-permutatie checken.

### JPEG
- `steghide extract -sf sample.jpg` (leeg wachtwoord eerst, dan wachtwoordlijst
  `$SECLISTS_PATH/Passwords/` top-10k, met fork-limiet).
- Metadata volledig dumpen; thumbnail-animatie (embedded PNG in EXIF).
- Appended data na EOI-marker (`\xff\xd9`) — python-rfind-geen-EOF-check.

### GIF / WebP
- Frame-count vs zichtbare frames; per-frame delay-kanalen; trailer-append.

### Audio (WAV/MP3/FLAC)
- Spectrogram: `ffmpeg -i sample.wav -lavfi showspectrumpic out.png` — boodschap
  in de tijd/frequentie is hier zichtbaar.
- LSB in 16-bit WAV (python wave-module, zelfde bitplane-script).
- `steghide` op WAV; morse/dtmf in spectrogram handmatig decoderen.

### Video
- `ffmpeg -i in.mp4 frame_%04d.png` → frames diffen; metadata; audio-spoor apart.

### Documenten (PDF/Office)
- PDF: `qpdf --qdf` of python-pikepdf → streams, objecten, onzichtbare tekst.
- Office: unzip → xml scannen op `w:vanish`, verborgen sheets, wb-hidden.

### Tekst
- Whitespace: trailing spaces/tabs → binary (snow-stijl, eigen python).
- Zero-width: `python3 -c "print([hex(ord(c)) for c in open('msg.txt').read() if ord(c)>0x2000])"`.

### Binaries / ELF
- Strings na EOF; binwalk-extract; base64-blobs tussen markers.

## Fase 3 — Known-secret / brute

- `steghide` met seclists-wachtwoorden (limiteer tot top-10k, timebox 10 min).
- CRC-mismatch check (PNG chunk-CRC's die niet kloppen wijzen op manipulatie).
- Bij gevonden wachtwoord: direct als evidence incl. bron-bestand hash.

## Fase 4 — Rapportage

- Extractieketen reproduceerbaar: elk command exact zoals gedraaid.
- Gevonden payload: hash (sha256), type, inhoud-samenvatting; nooit rechtstreeks
  uitvoeren — eerst triage via `../malware-analysis/SKILL.md` als het uitvoerbaar is.

## Grenzen

- Alleen lokaal materiaal; geen online stego-diensten.
- Payloads van derden niet uitvoeren zonder sandbox (`../ops/sandbox-profile.md`).
