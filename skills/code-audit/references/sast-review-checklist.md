# Code Audit Checklist (Condensed)

- [ ] List of all external input entry points
- [ ] Authorization/auth-middleware coverage
- [ ] Is the multi-tenant ID bound to the session
- [ ] Deserialization / pickle / YAML load
- [ ] SSRF egress and protocol restrictions
- [ ] Secret and token storage
- [ ] File upload paths and types
- [ ] Dangerous exec/system/Runtime
