# Package Boundary

The published MoonBit module is the reusable framework surface, not the
repository's development workspace.

Included in release artifacts:

- root facade modules such as `mbt_on_rails.mbt`
- framework packages under `src/`
- generated package interfaces
- README, license, and docs

Excluded from release artifacts:

- `.github/`
- `app/`
- `cmd/`
- `examples/`
- `scripts/`
- `tests/`

`moon.mod.json` owns the publish-time `exclude` list. CI and release validation
run `scripts/validate_package_boundary.sh`, which packages the module and fails
if non-production paths appear in the artifact or required framework files are
missing.

Examples remain in the repository as runnable documentation and integration
smoke coverage. Tests import example packages directly instead of re-exporting
demo helpers from the root package, keeping the public package surface focused
on framework APIs.
