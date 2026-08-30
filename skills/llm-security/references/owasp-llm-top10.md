# OWASP LLM & Agentic AI Top 10 (2025-2026)

## OWASP Top 10 for LLM Applications v2.0 (2025)

| # | Risk | Core issue | Testing direction |
|---|------|---------|---------|
| LLM01 | Prompt Injection | Manipulating model behaviour through crafted input | Direct injection, indirect injection, encoding bypass |
| LLM02 | Sensitive Information Disclosure | PII/API key/training data leakage | Prompt extraction, output analysis |
| LLM03 | Supply Chain | Poisoned models/libraries/datasets | Model provenance verification, dependency scanning |
| LLM04 | Data & Model Poisoning | Backdoors in training/fine-tuning data | Data provenance, behavioural anomaly detection |
| LLM05 | Improper Output Handling | Output leading to XSS/SQLi/RCE | Downstream system injection testing |
| LLM06 | Excessive Agency | Over-broad tools/autonomy causing real harm | Permission audit, human-in-the-loop testing |
| LLM07 | System Prompt Leakage | Extracting hidden instructions/secrets/business logic | Cascading extraction, canary tokens |
| LLM08 | Vector & Embedding Weaknesses | RAG pipeline attacks, embedding inversion | Retrieval poisoning, semantic similarity attacks |
| LLM09 | Misinformation | Hallucinations constituting security risk in high-stakes settings | Factuality verification, confidence calibration |
| LLM10 | Unbounded Consumption | DoS/Denial-of-Wallet | Token consumption testing, rate limits |

## OWASP Top 10 for Agentic Applications (ASI 2026)

| # | Risk | Core harm | Testing direction |
|---|------|---------|---------|
| ASI01 | Agent Goal Hijack | Hijacking goals through malicious input/tool output | Instruction override, goal tampering |
| ASI02 | Tool Misuse & Exploitation | Unintended use of legitimate tools | Tool-chain chaining, parameter injection |
| ASI03 | Identity & Privilege Abuse | Agent acting beyond its authorization | Credential theft, delegation chain testing |
| ASI04 | Agentic Supply Chain | Real-time risk from MCP descriptors/third-party tools | Dynamic supply-chain scanning |
| ASI05 | Unexpected Code Execution | Prompt→tool→script RCE chain | Multi-layer code execution testing |
| ASI06 | Memory & Context Poisoning | Long-term memory/embedding poisoning | Memory persistence attacks |
| ASI07 | Insecure Inter-Agent Communication | Tampering with agent-to-agent communication | Man-in-the-middle, replay attacks |
| ASI08 | Cascading Failures | Single point of failure triggering system-wide collapse | Failure propagation testing |
| ASI09 | Human-Agent Trust Exploitation | Manipulating human operators into approving dangerous operations | Authority bias / urgency testing |
| ASI10 | Rogue Agents | Agent self-replication/persistent malicious behaviour | Persistence and backdoor detection |

## Real-world distribution

Share of issues found during real assessments:
- LLM01 Prompt Injection: ~45%
- LLM06 Sensitive Info Disclosure: ~20%
- LLM08 Excessive Agency: ~15%
- Remaining 7 items: ~20%

## Key defence principles

1. Separate planning from execution — the model that interprets intent ≠ the model that performs actions
2. Bind identity/purpose/scope/ttl — never use broad environment-wide permissions
3. Log everything — tool calls/memory/communications as first-class security telemetry
4. Blast-radius control — circuit breakers/rollback/emergency stop take priority over convenience
5. Treat all natural-language input (including retrieved content) as untrusted
6. Output is equally untrusted — sanitize before rendering/executing/querying

## EU/NL regulatory lens

When an assessment touches AI systems deployed in the EU:
- EU AI Act: GPAI model providers and high-risk AI deployers must document model provenance, evaluation, and systemic-risk mitigations — your findings feed directly into that technical documentation.
- GDPR / Autoriteit Persoonsgegevens: LLM02-class findings (PII leakage) map to Art. 32/33 obligations; report suspected personal-data breaches on time.
- NIS2: affected essential/important entities must treat agentic tool abuse as a supply-chain and incident-management concern.
