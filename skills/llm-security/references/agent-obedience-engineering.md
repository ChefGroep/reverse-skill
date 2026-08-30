# AI Agent Obedience Engineering — Making the AI Actually Work After Reading the Workflow

> Source: 2026 synthesis from multiple public write-ups (Anthropic Skill Engineering, Microsoft Code Words, Strands Steering Hooks, Gradient Flow Harness Engineering)
> Applies to: AI coding agents (Claude Code / Codex / Cursor / Cline / Windsurf / Kiro, etc.) that only acknowledge instead of executing after reading README/RULES.md, skip steps, or omit critical actions on their own initiative

---

## Core problem diagnosis

The root cause of an agent "reading the workflow but not doing the work" is not insufficient model capability — it is that **natural-language instructions leave room for semantic escape**:

| Root cause | Explanation |
|------|------|
| **Context attention decay** | Content in the middle of a long document is down-weighted by LLM attention; the agent effectively only "sees" the beginning and the end |
| **Semantic override** | When optimizing for "helpfulness", the model creatively reinterprets explicit instructions (e.g. reading MUST DO X as "advised to do X") |
| **Passive language read as optional** | "Ready for next step → invoke X" is treated as a suggestion rather than an instruction |
| **Stateless enforcement** | Without an external state machine validating workflow order, the agent can skip steps without being detected |
| **Silent state rot** | The agent produces structurally correct but semantically wrong results; errors accumulate silently |

---

## Technique 1: Critical-first placement (Critical-First Pattern)

**Put "what to do next" first; put context after it.**

```
WRONG (agent ignores):
  [70 lines of project background and tool list]
  → "Next step: run bootstrap to install missing tools"

CORRECT (agent executes):
  "## EXECUTE NOW: run `bootstrap-reverse.ps1` to check for and install missing tools
   → when done, read routing.md to decide which skill to enter"
  [then the project background and tool list]
```

**Rationale**: LLMs assign the highest attention weight to the start and end of a prompt. Middle content can be ignored entirely.

**Application to this project**:
- The "routing entry" section of RULES.md should come after the trigger keywords and before the execution principles
- The first section of every SKILL.md should be "execute immediately", not "applicable scenarios"

---

## Technique 2: Directive over suggestive language (Directive Over Suggestive)

Replace all "suggestive" language with RFC 2119-grade directive language:

| Weak language (agent may skip) | Strong language (agent is forced to execute) |
|---|---|
| "You could try..." | **MUST**: you must execute... |
| "Ready for next step → invoke X" | **NOW**: invoke X immediately; do not wait for confirmation |
| "Suggested: read routing.md first" | **REQUIRED**: you must finish reading routing.md before entering any submodule |
| "If tools are missing you could bootstrap" | **NO EXCUSE**: when tools are missing, the only correct action is to call bootstrap; manual installation and guessing are forbidden |
| "Remember to update the field-journal" | **CHECKLIST ENFORCED**: tick every Checklist item after the task; you may not claim the task is finished while any item is open |
| "You should..." | **MUST** / **MUST NOT** |

**Key pattern**:
```
MUST — violation = task failure
MUST NOT — violation = security breach
SHOULD — deviation requires a stated reason
MAY — genuinely optional
```

---

## Technique 3: Excuse rebuttal table (Excuse Rebuttal Table)

**This is the most critical patch in this project.** When meeting resistance, AI agents automatically generate "reasonable excuses" to skip steps. List the common excuses in advance and rebut each one:

| Common agent excuse | Rebuttal (enforced) |
|---|---|
| "This step can be skipped; I'll go straight to..." | **Skipping is forbidden.** Every step in the behaviour chain is required. If you believe a step can be skipped, output the concrete reason first and let the user decide. |
| "In my judgement, this is not necessary" | **Your judgement does not apply here.** List the specific criteria you used to judge, and explain why those criteria justify skipping an explicitly written step. |
| "The user probably doesn't need this" | **Never decide on the user's behalf.** Present all options to the user, mark the recommendation, but never hide the alternatives. |
| "I already know how to do this; I don't need to read X" | **Read X before acting.** Even if you are sure you know how, X may contain constraints specific to this task. Reading it takes 2 seconds. |
| "To save time, I can skip... in parallel" | **The correct way to save time is to parallelize independent steps, not to skip steps.** If two steps are independent, run them in parallel; if they depend on each other, run them in order. |
| "I've used this tool before; I know the path" | **Guessing paths is forbidden.** You must obtain the actual path from tool-index; installation locations differ per machine. |
| "The task is basically done; no checklist needed" | **The only definition of task completion is a fully ticked Checklist.** A task with unticked Checklist items is not complete. |
| "I couldn't find tool-index, so I'll just guess paths" | **A missing file is 100× safer than a guessed wrong path.** When tool-index is missing, first run refresh-tool-index.ps1 to generate it. |
| "The user didn't explicitly ask for a report, so I won't write one" | **A report is the default behaviour, not optional.** After a security task you must produce a report unless the user explicitly says "no report". |
| "This is too simple to record in the journal" | **Simple tasks still have pitfalls worth recording.** At minimum log: target type + what you used + anything unexpected — one line is enough. |
| "The user asked me to redo the import table/step N, but I did a different, more useful step instead" | **Redo = redo the exact step that was named** (or a legitimate prerequisite path confirmed by the user). MUST update the corresponding Evidence; passing off unrelated steps is forbidden; silent skipping is forbidden. Unpacking is a **prerequisite** for a readable IAT, not a **substitute** for import-table Evidence. |
| "The user said: for the packed sample, don't unpack yet, just look at the import table; I hand over the junk (obfuscated) table and call it done" | **Feasibility latch:** when X is blocked, you MUST state the blocker, propose a recommended order, and **ask the user to confirm**. If the user insists, execute and mark `quality=unreadable/packed`; using junk-table output to draw capability-negating conclusions is forbidden. |
| "The unpacked binary crashes instantly; I keep grinding on file patches on disk" | **Patch 6:** log E-self-check-crash / E-iat-repair-fail and switch to dynamic analysis (breakpoints on CreateFile/GetFileSize). Endless static on-disk patching is forbidden. |
| "The IAT won't repair; I'll statically try a few more packer tools to stall" | **IAT repair iron rule:** prefer automatic/semi-automatic repair; if the tool errors out or the repaired binary still will not run → stop static IAT work immediately, log E-iat-repair-fail, and switch to dynamic API breakpoints to capture the real imports. Endless static grinding is forbidden. |
| ".NET / no import table, the hard gate does not apply, I'll skip it" | **Equivalent anchors still MUST:** for .NET, write the dnSpy/IL/metadata summary into the E-imports semantic slot; DLL/SYS files must additionally carry E-exports. Empty passes are forbidden. |


**How to use it**: place this table near the end of RULES.md or another instruction file (a high-attention zone). The agent sees the rebuttals before it starts looking for excuses.

---

## Technique 4: The five skill-engineering patterns (Anthropic 2026, official)

| Pattern | Use case | Key technique |
|---|---|---|
| **Linear Flow** | Clearly ordered processes (deployment, installation) | Provide safe defaults; use negative instructions ("MUST NOT use --force") |
| **Decision Tree** | Platform navigation, fault diagnosis | Tree-style navigation + progressive loading from `references/` |
| **Iterative Loop** | TDD, review-fix cycles | Hard rules up front + **excuse rebuttal table** to block shortcuts |
| **Baton Loop** | Multi-session, multi-agent collaboration | Externalize state into `next-prompt.md` (MUST write it before exiting) |
| **Multi-Phase + Checkpoints** | Multi-day complex workflows | Orchestrator "parent" skill + human Go/No-Go checkpoints, with time costs noted |

**Mapping to this project**:
- Full behaviour chain = Linear Flow (15 steps executed in order)
- Routing matrix = Decision Tree (three-axis matching)
- Checklist = Multi-Phase Checkpoint (every step must be ticked)
- Field Journal = Baton Loop (cross-session state externalization)

---

## Technique 5: In-band enforced self-verification (Steering Hooks idea)

Do not rely on AI "self-discipline"; embed self-verification instructions in the prompt instead:

```
Before every "task complete" claim, you MUST first self-check:
1. Did I skip any step in the behaviour chain? Which one?
2. Did I guess any tool path? If so, what is the actual tool-index path?
3. Are all Checklist items ticked? For unticked ones, why?
4. If the answer to any of the above is "skipped"/"unticked", the task is not complete;
   return to the corresponding step and redo it. Do not declare completion.
```

This makes the agent audit itself before saying "done" — more immediate than external validation.

---

## Technique 6: Opaque identifiers (Code Words) — for API/tool parameters

Microsoft research (2026) found: semantic parameter names trigger the model's tendency to "helpfully optimize".

```
WRONG: { "query": "...", "top": 9 }        → 68.4% parameter adherence rate
CORRECT: { "query": "...", "code": "alpha" } → 100% parameter adherence rate
```

**Where to apply it**:
- When passing exact configuration through bootstrap scripts, use short codes instead of semantic parameters
- For tool-call parameters that need strong guarantees, use code-word mapping

---

## Technique 7: Dual-AI review loop (Dual Validation)

```
AI A (executor) produces the output
  ↓
AI B (reviewer) checks it against the rules
  ↓ passes
Delivered to the user
  ↓ fails
Returned to AI A for correction, citing the specific violations
```

**Application in this project**:
- Embed a "self-review" step in RULES.md: before producing the report, the agent checks each Checklist item against its own output
- If any item turns out to be incomplete, return to the corresponding step and finish it yourself

---

## Technique 8: Context window layout optimization

LLM attention distribution (high → low):
```
[First 10%] ████████████ ← highest attention; place "act immediately" instructions
[Middle 80%]  ████░░░░░░░░ ← declining attention; place reference material
[Last 10%]  ████████████ ← attention recovers; place "never skip" rules and the Checklist
```

**Concrete application**:
1. **First 10%**: execute-now instructions + trigger keywords
2. **Middle 80%**: detailed workflow, reference links, tool lists
3. **Last 10%**: excuse rebuttal table + hard Checklist + forbidden-behaviour list

---

## Practical prompt templates

### Template A: forced-start template (embed at the top of RULES.md)

```markdown
## CRITICAL: after reading this document you must immediately execute the following (do not just acknowledge — actually execute)

1. **NOW**: detect the directory this file lives in → that is the package root
2. **NOW**: if this is first use, write these rules into the global configuration (see the global injection section)
3. **NEXT**: read `skills/SKILL.md` → `skills/routing.md` → decide which sub-skill to enter
4. **NEXT**: read `skills/tool-index.md` to confirm tool status
5. **THEN**: start executing the actual task; do not remain in a "read" state

If you only reply "read it", "done", or "understood" without actually executing the steps above,
you have failed. The user needs tools installed, code analyzed, vulnerabilities verified —
not an acknowledgement message.
```

### Template B: submodule entry template (embed at the top of every SKILL.md)

```markdown
## ACTION REQUIRED (execute immediately after reading; do not wait)

After reading this file:
1. Confirm you understand this skill's applicable scenarios
2. Check whether this machine has the required tools (read `../tool-index.md`)
3. If tools are missing → call bootstrap
4. If tools are present → start step 1 of the workflow
5. If you are unsure → list the concrete questions; do not stay silent
```

### Template C: task-completion self-check template (embed at the end of every SKILL.md)

```markdown
## Task Completion Self-Check (MUST confirm item by item before claiming completion)

□ I actually executed every step in the behaviour chain (no skipping)
□ I guessed no tool paths (all came from tool-index.md)
□ I produced reproducible commands/scripts/reports (not just descriptions of steps)
□ I updated the field-journal (if I hit pitfalls)
□ I ran the post-completion Checklist (report + diagrams + lessons written back)
```

---

## Forbidden behaviours (additional, from the agent-obedience perspective)

- Forbidden to read RULES.md and only reply "understood, please give me the specific task"
  → Correct behaviour: perform global injection → read SKILL.md → read routing.md → determine the entry point
- Forbidden to claim "steps 1-4 are done" when you only read them
  → Correct behaviour: distinguish "document read" from "operation executed"; only the latter produces real side effects
- Forbidden to say "task complete" without having executed the Checklist
  → The Checklist is the only definition of task completion
- Forbidden to substitute "based on my experience" for reading tool-index
  → Paths differ per machine; consulting tool-index is the only way to locate them

---

## Summary: if you can only change one thing

**Add an "act immediately" instruction block at the very top of RULES.md**, using bold, CRITICAL, NOW and other strong directive words.

This is the change with the highest return on effort. Most agents' "not doing the work" behaviour comes from automatically slipping into "wait for user instructions" mode after finishing a file. A forced "act immediately" instruction breaks that pattern.

If you can change a second thing: **add the excuse rebuttal table**. Agents start hunting for excuses to stop at the first obstacle; close those excuses off in advance.
