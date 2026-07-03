# Core Animation Debugging Task (Resumable / Rate-Limit Safe)

You are debugging a Core Animation issue in a macOS app involving a custom `CALayer` subclass: `AnalogClockLayer`.

---

## Hard Constraints

- Do NOT spend more than **2 minutes gathering context** before producing output.
- Do NOT attempt a full repository model before writing anything.
- Always produce a **checkpointable debugging log early**.
- Prefer incremental reasoning over long silent analysis.
- If execution stalls or uncertainty is high, write findings immediately.

---

## Primary Objective

Determine why `AnalogClockLayer.position` animations always begin from `(0,0)` instead of the previous on-screen position.

Observed symptoms:

- Position is updated inside an Objective-C `CATransaction`.
- Animation always appears to start from `(0,0)`.
- This happens on every move, not just the first.
- `presentationLayer.position` reads `(0,0)` immediately before updates.
- Removing `CATransaction.flush()` in Swift did not resolve the issue.
- The layer is backed by a Swift `CALayer` subclass.

---

## Required First Action (MANDATORY)

Within the first step of analysis:

1. Create or update this file in the repository:

```
docs/clock-full-screen/analog-clock-position-animation.md
```

2. Write an initial snapshot containing:

- Known symptoms
- Current hypotheses (even if incomplete)
- List of files already inspected
- Any immediate suspicions
- Open questions

This must be done BEFORE deep investigation.

---

## Investigation Scope

Search the entire repository and identify all occurrences of:

- `AnalogClockLayer` creation
- Layer retention / ownership
- `addSublayer` usage
- `position`, `frame`, `bounds`, `anchorPoint`, `transform` mutations
- `init(layer:)` or layer copying behavior
- `layoutSublayers` or layout-driven mutations
- Any `CATransaction` usage
- Any `CABasicAnimation` or implicit animations

Include Objective-C and Swift code paths.

---

## Debugging Method (Strict)

Proceed in phases:

### Phase 1 — Fast mapping (max 2 minutes)
- Identify all relevant files and call sites
- Write them into the debugging document immediately
- Do NOT analyze deeply yet

### Phase 2 — Hypothesis generation
Produce a ranked list of hypotheses.

For each hypothesis include:
- Explanation of mechanism
- Why it matches observed symptoms
- What evidence would confirm it
- What evidence would refute it

### Phase 3 — Targeted verification
- Add logging or minimal instrumentation
- Check layer identity and hierarchy state
- Verify superlayer attachment status
- Confirm whether model vs presentation mismatch exists

### Phase 4 — Iteration
- Eliminate hypotheses based on evidence
- Update debugging document after each step

---

## Critical Checks (must explicitly verify)

- Whether the layer instance being moved is the same instance being inspected
- Whether `superlayer` is non-nil at time of animation
- Whether `presentationLayer` is nil or detached
- Whether any code resets `position` implicitly (layout or setters)
- Whether `init(layer:)` copying is producing a duplicate instance
- Whether the layer is being recreated or replaced during updates

---

## Output Requirements

You must continuously maintain:

```
docs/debugging/analog-clock-position-animation.md
```

This file must always include:

- Current best hypothesis
- Evidence table
- Eliminated hypotheses
- Latest debug outputs (logs)
- Next step to run

It should be sufficient for another LLM to resume the investigation without reading the full repository.

---

## Success Criteria

Root cause must be identified with evidence, not speculation.

The final answer must include:
- Exact cause
- Minimal fix
- Why that fix resolves `(0,0)` presentation behavior