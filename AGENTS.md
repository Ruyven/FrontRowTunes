# AGENTS.md

## Overview

This repository uses an incremental, agent-driven development workflow designed for LLM-based coding agents (e.g. Gemini CLI, Codex-style agents).

The system prioritises:

- Deterministic, repeatable builds
- Minimal diffs per iteration
- Strict step-by-step execution
- Continuous build validation

---

## Core Operating Model

The agent operates in repeated cycles:

1. Read instructions for the current task or step.
2. Make the minimal required code changes.
3. Build the project.
4. Fix any build errors until the build succeeds.
5. Run tests (if present).
6. Stop and report results.

Each cycle MUST end after completion and summary.

---

## Strict Constraints

### Version Control (HARD RULE)

The agent MUST NOT:

- Stage changes (`git add`)
- Commit changes (`git commit`)
- Push to a remote (`git push`)
- Create branches

These actions are only permitted if the user explicitly requests them.

---

### Scope Control (HARD RULE)

The agent MUST:

- Implement ONLY the requested step.
- Avoid unrelated refactors.
- Avoid feature creep.
- Avoid architectural redesign unless explicitly instructed.

---

### Stop Condition (HARD RULE)

The agent MUST STOP immediately when:

- The build succeeds, AND
- Tests pass (if tests exist), AND
- The requested step is complete.

No additional improvements or follow-up work are permitted.

---

## Mandatory Build Loop

After EVERY code modification, the agent MUST execute the following workflow.

### Step 1 — Build

Run:

    xcodebuild

If the project requires a specific workspace, project or scheme, detect and use the appropriate command.

---

### Step 2 — Fix Build Errors

If the build fails:

- Read all compiler errors.
- Identify the root cause(s).
- Apply the smallest possible corrective change.
- Do NOT perform unrelated refactoring.

Then build again:

    xcodebuild

Repeat until the build succeeds.

---

### Step 3 — Run Tests

If the repository contains tests:

Run:

    xcodebuild test

If tests fail:

- Diagnose the failure.
- Apply the smallest reasonable fix.
- Run the tests again.

Repeat until all tests pass.

---

### Step 4 — Stop

Once:

- Build succeeds
- Tests pass (if present)
- Requested task is complete

STOP immediately.

Do not continue with additional improvements or the next planned task.

Provide a concise summary containing:

- What changed
- Why it changed
- Files modified
- Any remaining risks or follow-up work

---

## Agent Optimisation Rules

To maximise efficiency and minimise unnecessary model requests:

- Batch local tool execution whenever practical.
- Prefer completing an entire build/fix/build cycle before responding.
- Use compiler output as the primary source of truth.
- Avoid asking for confirmation unless blocked.
- Minimise reasoning cycles by fixing all obvious issues discovered during a build iteration.

---

## File Modification Rules

The agent MUST:

- Prefer the smallest possible diff.
- Preserve existing APIs unless instructed otherwise.
- Avoid renaming symbols unless necessary.
- Avoid moving files unless explicitly requested.
- Preserve existing formatting and coding style where practical.

---

## Debugging Strategy

When multiple errors exist:

1. Fix the root cause before secondary errors.
2. Rebuild after each meaningful fix.
3. Avoid speculative changes.
4. Avoid cleanup while restoring build correctness.

---

## Definition of Done

A task is complete only when:

- The requested implementation is finished.
- The project builds successfully.
- Tests pass (if applicable).
- A concise summary has been provided.
- The agent has stopped.

---

## Explicit Non-Goals

Unless explicitly instructed, the agent MUST NOT:

- Refactor unrelated code.
- Optimise performance.
- Update dependencies.
- Redesign architecture.
- Modify project settings unrelated to the requested task.
- Change formatting throughout the project.

---

## Repository Behaviour

Assume this repository values:

- Small, reviewable commits.
- Predictable behaviour.
- Backwards compatibility where practical.
- Minimal changes outside the requested scope.

If there is uncertainty, choose the option that results in the smallest safe change.

---

## General Operating Principle

When in doubt:

- Read more before changing code.
- Change less rather than more.
- Build before assuming success.
- Stop once the requested work is complete.

Never continue onto the next task without explicit instruction from the user.