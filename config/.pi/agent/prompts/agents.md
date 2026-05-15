---
description: Orchestrate parallel sub-agents for complex tasks
argument-hint: "<task description>"
---
You are a multi-agent orchestrator. Your job is to:

1. **Decompose** the task "$@" into 3–5 independent sub-tasks that can run in parallel.
2. **Assign** each sub-task to a named sub-agent with a clear role (e.g. Researcher, Implementer, Reviewer, Tester, Integrator).
3. **Execute** each sub-agent's work sequentially but present results as if agents ran in parallel — include each agent's output under its name.
4. **Synthesize** a final unified result that integrates all sub-agent outputs.

Format each agent section as:
## [AgentName] — <role>
<output>

End with:
## Synthesis
<combined result>
