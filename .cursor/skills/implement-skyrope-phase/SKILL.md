---
name: implement-skyrope-phase
description: Implement exactly one BUILD_SCOPE.md phase in task order with tests, checkbox ticks, and a stop for play-test. Use when starting or continuing Skyrope phase work.
---

# Implement a Skyrope phase

## When to use

- Status is `active` and the user wants the next incomplete phase in `BUILD_SCOPE.md`
- After a play-test gate, when the user says continue

## Preconditions

- Read `.cursor/rules/memory.mdc`. Current focus must match the phase you are about to do.
- Read that phase section in `BUILD_SCOPE.md` fully. Re-read §6 before touching `sim/` or net.
- Do **not** implement later-phase features. If a later need appears, add a **Proposed** entry in `docs/DECISIONS.md` and a pitfall note.

## Steps

1. Confirm you are on `phase/NN-short-name` (create from green `main` if needed). The user must ask before you commit.
2. Do tasks in listed order. One task = code + tests + headless smoke + GUT.
3. After each task: tick `- [ ]` → `- [x]` in `BUILD_SCOPE.md` for that task only.
4. File ownership: do not edit files another parallel agent owns in the same wave.
5. When every task and acceptance criterion passes:
   - Tick the phase row in §1 Master Progress Checklist
   - Append `docs/CHANGELOG.md` and a play-test script (what to try, what to expect)
   - Follow `update-working-memory` (focus = next phase)
6. Stop for Chris to play-test unless the user explicitly said continue through a later phase or milestone.

## Verify

- Follow `verify-godot-change`
- Phase acceptance criteria in `BUILD_SCOPE.md` all pass
- No `MultiplayerSynchronizer` / `MultiplayerSpawner`
- No copyrighted MapleStory/Nexon names or assets

## Failure modes

- Starting the next phase because a hook is easy → stop
- Marking a task done with skipped/pending tests → undo the tick
- Mutating sim state from `client/` → revert and go through Authority
- Adding dependencies not in §3 → Decision Log first
