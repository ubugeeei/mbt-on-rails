<!--
PR title format: area(scope): imperative summary  (e.g. security(http): default-deny external schemes)
Keep this PR focused. Split unrelated changes into separate PRs.
-->

## Summary

<!-- What is changing, in two or three lines. -->

## Why

<!-- The motivating problem; link the issue it closes. -->

Closes #<issue-number>

## Notes for the reviewer

<!-- Anything non-obvious about the diff: ordering, migration steps, intentional incompatibilities, follow-ups deferred to another PR. -->

## Test plan

- [ ] `moon info && moon fmt && git diff --exit-code` clean
- [ ] `scripts/check_moon_warnings.sh` clean (zero MoonBit warnings)
- [ ] `moon build` and `moon test` on the default target
- [ ] `moon build --target js && moon test --target js`
- [ ] `moon build --target wasm-gc && moon test --target wasm-gc`
- [ ] `moon build --target native && moon test --target native`
- [ ] New / updated public tests cover the change (list which test files in `tests/public/` were touched)

## Public API impact

<!-- If `mbt_on_rails.mbt`, `pkg.generated.mbti`, or `tests/public/prelude.mbt` changed, summarise the surface delta here. Removing or renaming a public symbol is a breaking change. -->
