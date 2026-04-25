## Context

The repo currently builds an iOS app named Suhoor. The Subh doctrine requires a visible rename, but the first-wave app identity must retain the existing bundle identifier and local storage namespaces. Xcode project, scheme, folder, test target, app entry-point, and import changes are tightly coupled, so the rename should be performed as one focused implementation slice.

## Goals / Non-Goals

**Goals:**
- Rename build and visible product surfaces to Subh.
- Keep the app bundle identifier as `khanomar.Suhoor`.
- Keep existing persisted storage namespaces readable and untouched.
- Update test imports and Xcode references so `xcodebuild -list -project Subh.xcodeproj` succeeds.

**Non-Goals:**
- No destructive storage migration.
- No mass rewrite of domain terms that are currently persisted or tied to legacy alarm semantics.
- No bundle identifier change in this wave.

## Decisions

- Rename project/scheme/folders with filesystem moves and targeted project-file edits rather than creating a new project.
- Keep legacy storage type/key names where they protect data compatibility.
- Rename `SuhoorApp` to `SubhApp` as the visible app entry-point symbol.
- Update copy opportunistically where it is user-facing, but avoid mechanical replacement inside compatibility keys.

## Risks / Trade-offs

- [Risk] Project references can drift after folder/project renames. → Mitigation: run `xcodebuild -list -project Subh.xcodeproj`.
- [Risk] Mechanical replacement could corrupt storage keys. → Mitigation: use targeted edits and inspect remaining Suhoor references.
