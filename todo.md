# Completed Tasks

## Phase 1: Infrastructure
- [x] Create `src/lib/mkLang.nix` helper.
- [x] Implement `flake.lib.devLangModules` automated aggregation.

## Phase 2: Refactoring
- [x] Refactored all 19 language modules to use `mkLang`.
- [x] Updated `src/profiles/dev.nix` to use dynamic imports.

# Next Steps
- [ ] Monitor build for any evaluation errors.
- [ ] Add more languages by simply dropping a `.nix` file in `src/home/packages/dev/lang/`.
