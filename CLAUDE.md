# IKE Workspace

Multi-project Maven 4 aggregator workspace for IKE.

## Build Standards

Build standards are distributed as a zip artifact from `ike-pipeline/ike-build-standards` and unpacked to `.claude/standards/` during the Maven `validate` phase.

- **DO NOT edit** files in `.claude/standards/` — they are build artifacts, overwritten on every build
- **DO NOT commit** `.claude/standards/` to git — it must be in `.gitignore`
- **To update standards**: edit in `ike-pipeline/ike-build-standards/src/main/standards/`, release ike-pipeline, then rebuild

After building, read `.claude/standards/` for project conventions (IKE-MAVEN.md, IKE-JAVA.md, MAVEN.md, etc.).

## Build

```bash
mvn clean verify -DskipTests -T4   # compile + javadoc, skip tests
mvn clean verify -T4                # full build with tests
```

## Key Conventions

- All projects use Maven 4 with POM modelVersion 4.1.0
- Parent: `network.ike:ike-parent` (from ike-pipeline)
- Versions declared only at multi-module root, not in submodules
- `<subprojects>` (not `<modules>`) for Maven 4.1.0 aggregation
- All projects use `--enable-preview` (Java 25)
- Always include a timestamp on completion messages so builds can be verified
