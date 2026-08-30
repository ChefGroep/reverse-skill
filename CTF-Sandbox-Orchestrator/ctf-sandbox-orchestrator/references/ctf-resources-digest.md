# CTF Resources Digest

> Curated from [awesome-ctf-resources](https://github.com/devploit/awesome-ctf-resources) and [awesome-ctf](https://github.com/apsdehal/awesome-ctf)
> Classified by CTF challenge type; only the most practical tools and resources are kept.

---

## General frameworks

| Tool | Purpose | Link |
|------|------|------|
| Pwntools | Exploit development framework (Python) | https://github.com/Gallopsled/pwntools |
| ctf-tools | One-shot CTF tool installer | https://github.com/zardus/ctf-tools |
| Ciphey | AI-assisted auto-decryption | https://github.com/ciphey/ciphey |
| CyberChef | Online encode/decode and crypto | https://gchq.github.io/CyberChef/ |

---

## Web

### Tools
| Tool | Purpose |
|------|------|
| Burp Suite | HTTP interception/replay/scanning |
| SQLMap | SQL injection |
| XSStrike | XSS detection |
| dirsearch | Directory discovery |
| JWT_Tool | JWT attacks |
| SSRFmap | SSRF exploitation |

### Common exam points
- SQL injection (union/blind/time-based/stacked)
- XSS (reflected/stored/DOM)
- SSRF (internal network probing / cloud metadata)
- File upload (bypassing extension/MIME/content checks)
- Deserialization (PHP/Java/Python pickle)
- Template injection (SSTI)
- JWT forging / key confusion

### Payload references
- https://github.com/swisskyrepo/PayloadsAllTheThings
- https://book.hacktricks.wiki/

---

## Reverse

### Tools
| Tool | Purpose |
|------|------|
| IDA Pro / Ghidra | Decompilation |
| radare2 / r2 | CLI analysis |
| angr | Symbolic execution |
| Frida | Dynamic hooking |
| GDB + pwndbg | Debugging |
| uncompyle6 | Python decompilation |
| jadx | Android decompilation |
| dnSpy | .NET decompilation |

### Common exam points
- Algorithm recovery (crypto/encoding/custom)
- Anti-debug / anti-VM bypass
- Packers / obfuscation (UPX/VMProtect/OLLVM)
- Constraint solving via symbolic execution
- Dynamic hooking to bypass checks
- Go/Rust reversing (symbol recovery)

---

## Pwn

### Tools
| Tool | Purpose |
|------|------|
| Pwntools | Exploit writing |
| GDB + pwndbg/GEF | Debugging |
| ROPgadget | ROP chain construction |
| one_gadget | libc one-shot gadgets |
| checksec | Protection detection |
| LibcSearcher | libc version identification |

### Common exam points
- Stack overflow (ret2text/ret2libc/ret2shellcode/ROP)
- Heap exploitation (UAF/double free/tcache/fastbin)
- Format strings (arbitrary read/write)
- Integer overflow
- Kernel pwn (privilege escalation / race conditions)
- Sandbox escape (seccomp bypass)

### Common payload pattern
```python
# ret2libc template
from pwn import *
elf = ELF('./vuln')
libc = ELF('./libc.so.6')
p = process('./vuln')
# leak libc base → calculate system/binsh → overwrite ret
```

---

## Crypto

### Tools
| Tool | Purpose |
|------|------|
| SageMath | Math computation |
| RsaCtfTool | RSA auto-attacks |
| hashcat/john | Hash cracking |
| CyberChef | Encode/decode |
| z3 (SMT solver) | Constraint solving |

### Common exam points
- RSA (small public exponent / common modulus / Wiener / Coppersmith)
- AES (ECB / CBC padding oracle / bit flipping)
- Classical ciphers (Caesar/Vigenere/substitution)
- Hash length extension attacks
- Elliptic curves (ECDSA nonce reuse)
- Lattice crypto (LLL/CVP)

---

## Forensics

### Tools
| Tool | Purpose |
|------|------|
| Volatility | Memory forensics |
| Autopsy/Sleuth Kit | Disk forensics |
| Wireshark | Traffic analysis |
| binwalk | Firmware/file extraction |
| foremost | File recovery |
| exiftool | Metadata extraction |

### Common exam points
- Memory dump analysis (processes/passwords/malicious code)
- PCAP traffic analysis (HTTP/DNS/TCP reassembly)
- Filesystem analysis (deleted-file recovery / hidden partitions)
- Log analysis (web logs / system logs)
- Disk image analysis

---

## Misc/Stego

### Tools
| Tool | Purpose |
|------|------|
| StegSolve | Image steganography analysis |
| zsteg | PNG/BMP steganography |
| steghide | JPEG steganography |
| Audacity | Audio analysis |
| strings/xxd | Basic analysis |
| file/binwalk | File type identification |

### Common exam points
- LSB steganography (least significant image bits)
- File header repair/splicing
- QR codes / barcodes
- Audio spectrogram steganography
- ZIP fake encryption / known-plaintext attacks
- Encoding identification (Base64/Hex/Morse/Braille)

---

## Online platforms

| Platform | Trait | Link |
|------|------|------|
| CTFTime | Event calendar + writeups | https://ctftime.org/ |
| HackTheBox | Hands-on lab machines | https://www.hackthebox.com/ |
| TryHackMe | Guided learning | https://tryhackme.com/ |
| PicoCTF | Beginner friendly | https://picoctf.org/ |
| pwnable.kr | Pwn focused | http://pwnable.kr/ |
| cryptopals | Crypto focused | https://cryptopals.com/ |
| OverTheWire | Wargame series challenges | https://overthewire.org/ |
| Root-Me | Mixed challenges | https://www.root-me.org/ |

---

## Writeup resources

| Resource | Link |
|------|------|
| CTFTime Writeups | https://ctftime.org/writeups |
| 0xdf hacks stuff | https://0xdf.gitlab.io/ |
| LiveOverflow (YouTube) | https://www.youtube.com/c/LiveOverflow |
| John Hammond (YouTube) | https://www.youtube.com/c/JohnHammond010 |
| IppSec (HTB walkthroughs) | https://www.youtube.com/c/ippsec |
