# Attack Chain Playbook Cheatsheet

> Pick the matching playbook by target type. Each playbook defines the standard path from initial access to goal achieved.

---

## Playbook 1: External Web Application → Domain Controller

```
1. Subdomain enumeration + port scanning
2. Web fingerprinting → find known-vulnerable components
3. Exploit to obtain webshell / RCE
4. Internal network info gathering (ipconfig/ifconfig, arp, net user)
5. Build tunnels (frp/chisel/ssh)
6. Internal network scan (live hosts, open ports)
7. Credential acquisition (mimikatz/hashdump/config files)
8. Lateral movement (PTH/WMI/PsExec)
9. Domain info gathering (BloodHound)
10. Domain privesc (Kerberoasting/DCSync/constrained delegation)
11. Obtain domain controller privileges
```

**Key tool chain**: subfinder → httpx → nuclei → sqlmap/sstimap → frp → nmap → mimikatz → crackmapexec → bloodhound → certipy

---

## Playbook 2: Phishing → Internal Network Penetration

```
1. Target employee info gathering (LinkedIn/Maimai)
2. Craft phishing emails (spoofed sender / legitimate subject)
3. Build payloads (macro documents/LNK/ISO/HTML smuggling)
4. Send phishing emails
5. Wait for callback (C2 beacon)
6. Local info gathering + privesc
7. Credential extraction
8. Lateral movement
9. Persistence
10. Goal achieved
```

**Key tool chain**: theHarvester → gophish → msfvenom/cobalt-strike → mimikatz → bloodhound

---

## Playbook 3: Physical-Access Pentest → Internal Network

```
1. Physical recon (WiFi signals, access control types, USB ports)
2. WiFi attack (Fluxion rogue hotspot / WPA cracking)
   or BadUSB implant (Rubber Ducky keystroke injection)
   or network implant (Raspberry Pi / LAN Turtle)
3. Obtain internal network access point
4. Internal network scan
5. Then continue with Playbook 1 steps 5-11
```

**Key tool chain**: fluxion/aircrack-ng → rubber-ducky → frp → nmap → crackmapexec

---

## Playbook 4: Cloud Environment Penetration

```
1. Cloud asset discovery (subdomains → CNAME → cloud provider)
2. Bucket enumeration (S3/OSS/Blob public access)
3. SSRF → cloud metadata (169.254.169.254)
4. Obtain temporary credentials (AK/SK/Token)
5. Cloud API enumeration (IAM/EC2/Lambda/RDS)
6. Privilege escalation (PassRole/AssumeRole)
7. Lateral movement (cross-account/cross-region)
8. Data acquisition
```

**Key tool chain**: subfinder → nuclei(ssrf) → aws-cli → pacu → ScoutSuite

---

## Playbook 5: Bug Bounty / SRC Rapid Wins

```
1. Asset collection (subdomains + ports + JS files)
2. Fingerprinting → rapid known-vuln validation (nuclei)
3. Parameter discovery (arjun/paramspider)
4. Test class by class:
   - IDOR/privilege escalation (change ID/change role)
   - SSRF (internal network probing/cloud metadata)
   - SQL injection (sqlmap)
   - XSS (xsstrike)
   - File upload (bypass detection)
   - Logic flaws (payment/CAPTCHA/password reset)
5. Write PoC + submit report
```

**Key tool chain**: subfinder → httpx → nuclei → arjun → sqlmap → xsstrike → burpsuite

---

## Playbook 6: AD CS Certificate Attack

```
1. Discover AD CS services (certipy find)
2. Identify vulnerable templates (ESC1-ESC8)
3. Request malicious certificates
4. Authenticate as the target user with the certificate
5. Obtain NTLM hash or TGT
6. DCSync to export all credentials
```

**Key tool chain**: certipy → rubeus → mimikatz → secretsdump

---

## Generic Decision Matrix

| Current State | Next Step Priority |
|---------|-------------|
| Only the target domain | Subdomain enumeration → port scan → web fingerprint |
| Have a web vulnerability | Obtain shell → internal network info gathering |
| Have a low-privilege shell | Privesc → credential extraction |
| Have one internal machine | Build tunnel → internal scan → lateral |
| Have domain user credentials | BloodHound → find attack paths |
| Have domain admin hash | DCSync → Golden Ticket |
| Have cloud AK/SK | Enumerate permissions → privesc → data acquisition |
| Phishing callback live | Local privesc → credentials → lateral |
| Physical-access entry | Internal scan → same as above |
