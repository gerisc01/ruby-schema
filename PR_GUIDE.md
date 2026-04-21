# Pull Request Guide

---

## Philosophy

PRs in this project serve two purposes: keeping a readable history of *why* things changed, and making it easy to decide whether a version bump is warranted. Since this is a published gem, every merged PR should be able to answer the question "what does a caller need to know about this change?" — even if the answer is "nothing."

---

## Starting a Feature

Before writing code, define the PR boundary. A good PR answers one question: **"What is the smallest coherent change to the library?"**

For a gem, the natural split is usually along the architecture layers:

- **Schema core** — changes to `Schema`, `Field`, `Validators`, `FieldHelpers`, `TypeRef`
- **Field type mixins** — changes to `BaseFields`, `TopLevelFields`, `ArrayFields`, `HashFields`
- **Storage layer** — changes to `SchemaTypeStorage`, `LocalCache`, `LocalFilesDb`, `CrudMethods`
- **Test-only** — no source changes, no version bump needed

If a change touches only one of these layers, it's usually one PR. If it touches two layers because they're inherently coupled (e.g. a new field option that requires both a `Field` attribute and a change to how `TopLevelFields` generates a setter), that's fine — but call it out in the description.

**Hard limits — if a PR crosses these, split it:**
- More than ~4-5 source files changed (not counting test files)
- Both a new feature and a bug fix in the same PR
- Schema core and storage changes in the same PR unless they're tightly coupled
- A breaking change mixed with a non-breaking change

---

## Scope Creep

The most common trap: noticing something adjacent while working on a feature and fixing it in the same branch.

**The rule:** If it wasn't broken when the branch started, it doesn't go in this PR.

Note it and handle it as a follow-up. The exception is a single-line fix in a file you're already modifying for the feature — that's fine to include, but call it out explicitly in the PR description and consider whether it affects the version bump decision.

---

## Branch Naming

```
feature/<short-description>     # New field option, new type support, new storage behavior
fix/<short-description>         # Bug fix
refactor/<short-description>    # No behavior change
test/<short-description>        # Tests only
```

Examples: `feature/extra-attrs-field-option`, `fix/array-subtype-validation`, `refactor/validators-module`

---

## Version Bump Decision

This is the most important judgment call for a gem PR. Make this decision explicitly, not as an afterthought.

**Major (x.0.0) — breaking change for callers:**
- Removing a public method or changing its signature
- Changing validation behavior in a way that would cause previously-valid code to fail
- Changing the format of `to_schema_object` output
- Renaming a class or module that callers reference directly

**Minor (0.x.0) — new capability, backward compatible:**
- New field option (e.g. `extra_attrs`)
- New custom type support
- New filter option on `list`/`get`
- New CRUD method or schema accessor
- New storage behavior that callers opt into

**Patch (0.0.x) — bug fix, no API change:**
- Fixing incorrect validation logic
- Fixing a crash for an edge case
- Fixing storage behavior that was unintentionally wrong

**No bump — internal only:**
- Test-only changes
- Documentation updates
- Refactors with no behavior change
- Ruby version upgrade with no gem API change

**When in doubt:** if a caller upgrading to this version would need to change their code, it's major. If they'd need to know about it but wouldn't need to change anything, it's minor. If they'd never notice, it's patch or nothing.

**Batching:** If several related changes are in flight that together constitute a minor or major bump, individual PRs can be marked "no bump — part of batch." The bump goes on the PR that completes the batch. Note this explicitly in the PR description.

---

## PR Description Template

When you're ready to commit, ask Claude to generate the PR description. It will produce a title and body in this format.

**Title** (80 characters max):
```
<type>: <short description of what changed and why>
```
Common types: `fix`, `feat`, `refactor`, `test`, `chore`. The description should complete the sentence "This commit will…" — e.g. `fix: correct subtype validation for nested array type refs`.

**Body:**
```markdown
## What
[1-3 sentences on what changed and why. Focus on intent, not mechanics.]

## How it fits together
[Which layer(s) were touched and how they connect. For example:
"Field gets a new `extra_attrs` attribute; TopLevelFields passes it through
to the setter; FieldHelpers includes it in to_schema_object output."
This is the section that answers "how do all the bits connect?" without
requiring the reviewer to trace through the code.]

## Files changed
[Grouped by layer — schema core, field type mixins, storage, tests.
One line per file with a note on what changed in it.]

## Version bump
[Major / Minor / Patch / None — and one sentence on why.
If "none" because this is part of a batch, say so and name the batch.]

## Docs
[For each doc file, state whether it was updated and why, or why no update
was needed. Claude generates this section automatically — see rules below.
Example: "README.md updated: added new `extra_attrs` field option to the
field options table. CLAUDE.md: no changes needed, no structural change."]

## Out of scope / follow-up
[Anything noticed but intentionally left out of this PR.]

## Testing
[What was tested and how — e.g., "Added unit tests covering the new
validation path. Ran full rake test suite." or "Covered by existing
array_fields_test.rb — no new tests needed."]
```

The *How it fits together*, *Version bump*, and *Docs* sections are the most important ones for this project.

---

## Documentation Rules (Claude: apply when generating a PR description)

When generating a PR description, look at the files changed and apply these rules to produce the `## Docs` section. Do not skip this — even a "no changes needed" conclusion must be stated explicitly.

**`README.md` — update and note it if any of these changed:**
- A field option was added, removed, or its behavior changed → update the Field Options table
- A generated method was added, removed, or renamed (`add_*`, `upsert_*`, getters, setters) → update the Instance Methods section
- A new type or custom type hook was added → update the Types section
- Type ref or nested schema behavior changed → update those sections
- Storage filter options (`since`, `include_deleted`) changed → update the Storage / Filtering section
- The `apply_schema` or storage setup flow changed → update Quick Start or Storage setup

**`CLAUDE.md` — update and note it if any of these changed:**
- A source file was added, moved, or removed → update the Module Map
- A new layer or abstraction was introduced → update the Architecture diagram
- The data flow through the system changed (validation pipeline, set/get path, save!/list path) → update Key Data Flows
- A non-obvious design decision was made or reversed → update that section
- A new test file was added → update the Test Map

**If neither doc needs updating:** write one sentence saying why — e.g. "No doc changes needed: internal refactor with no public API or structural change." The point is that the check was done, not skipped.

---

## Reviewing Your Own PRs

Before merging:

1. **Does the diff tell a coherent story?** If you have to jump around to understand what's happening, the PR may need to be split.
2. **Is there anything in the diff you don't recognize?** Stray changes, debug output, or accidentally included files should be cleaned up.
3. **Does the version bump match the actual change?** Re-read the bump decision with fresh eyes — it's easy to underestimate a breaking change.
4. **Did you complete the documentation check above?** The `## Docs` line should be present in the PR description.
5. **Does the PR description still match the diff?** If scope shifted during development, update the description before merging.

---

## What Claude Can Help With

At any point during a feature:

- **"Is this getting too big?"** — Describe what you've changed so far and what's left; get a recommendation on whether to split.
- **"What's the version bump for this?"** — Describe what changed; Claude will walk through the decision.
- **"What would the PR description look like?"** — Provide the branch and a brief summary; Claude will draft the full description from the code.
- **"Is this in scope?"** — Describe the thing you noticed and the original feature goal; get a recommendation on whether it belongs in this PR.
- **"What might break for callers?"** — Describe the change; Claude will identify API surface implications.
