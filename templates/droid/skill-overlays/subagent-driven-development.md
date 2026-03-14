Use this workflow as delegated implementation with strong orchestration.

1. Define the plan and slice boundaries in the main thread.
2. Delegate isolated work items when the ownership boundary is clear.
3. Require each delegate to report files touched, tests run, and known uncertainties.
4. Run a separate review pass when the change is risky or the spec is tight.
5. Merge, reconcile, and validate the complete result in the main thread.

Avoid concurrent delegates on the same files unless you have explicitly partitioned the edit surface.
