# Defer km-based intervals and DuePoint to Phase 2

`TaskSections` and `IntervalCalculator` are intentionally time-only for Phase 1. km-based intervals (oil change every 5,000 km, tyre rotation every 10,000 km) are a Phase 2 feature; the store launch targets homeowners with time-based maintenance tasks only.

We evaluated introducing a `DuePoint` sealed class (`TimeDuePoint(DateTime)` | `KmDuePoint(int)`) now so that Phase 2 would be purely additive. We chose not to: it adds interface complexity before any km caller exists, and Phase 1 has no km tasks in the data model. One adapter does not make a real seam.

**Considered options:**
- `DuePoint` sealed class now — rejected: speculative abstraction, no second adapter, YAGNI
- `kmThreshold: int?` field on `Task` now — rejected: same reason; pollutes the model with a null field used only in Phase 2

**Phase 2 migration path:** add `kmThreshold: int?` to `Task` (new `@HiveField`), filter km tasks before `TaskSections.from()` or add a `distanceBased` section, update `IntervalCalculator` interface. All are additive changes; no existing time-based paths break.
