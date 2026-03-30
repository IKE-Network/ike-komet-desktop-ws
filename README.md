# IKE Komet Desktop Workspace

Multi-repo Maven 4 workspace aggregator for the Komet desktop application —
the full stack from tinkar backend through JavaFX desktop shell.

## What's in Here

| Component | Description | Version |
|-----------|-------------|---------|
| `ike-bom` | Dependency version Bill of Materials | 3.0.7-SNAPSHOT |
| `tinkar-core` | Data model, entity framework, providers, reasoning | 1.127.2-SNAPSHOT |
| `rocks-kb` | RocksDB-based knowledge base storage engine | 0.1.0-SNAPSHOT |
| `tinkar-composer` | Fluent API for composing Tinkar entities | 1.14.0-SNAPSHOT |
| `komet` | JavaFX UI framework — views, kview, layout editor | 1.59.0-SNAPSHOT |
| `komet-desktop` | Desktop application shell (JavaFX + jlink) | 3.0.0-SNAPSHOT |

The workspace root contains only the aggregator POM and `workspace.yaml`
manifest. Source lives in the component repos listed above.

## Prerequisites

| Tool | Version |
|------|---------|
| Java (OpenJDK) | 25.0.2+ |
| Maven | 4.0.0-rc-5+ |
| Git | any recent |

Java 25 is required — all projects use `--enable-preview` features.
Maven 4 is required — POMs use `modelVersion 4.1.0` and `<subprojects>`.

## Maven Repository Access

These projects are published to the IKE Nexus repository. They are **not** on
Maven Central because Maven Central does not currently support Maven 4.0 /
POM model version 4.1.0. Access is available to active developers on this
project — contact the team to obtain credentials.

See **[docs/developer-setup.md](docs/developer-setup.md)** for
step-by-step Maven and credential setup on Windows, macOS, and Linux.

## Getting Started

Once your Maven environment is configured:

```bash
# 1. Clone the workspace
git clone https://github.com/IKE-Network/ike-komet-desktop-ws.git
cd ike-komet-desktop-ws

# 2. Clone all component repos
mvn ike:init

# 3. Build (skip tests for speed)
mvn clean verify -DskipTests -T4
```

After `ike:init` your working directory will look like:

```
ike-komet-desktop-ws/   ← workspace root (you are here)
ike-bom/
tinkar-core/
rocks-kb/
tinkar-composer/
komet/
komet-desktop/
```

Full build with tests: `mvn clean verify -T4`
Typical build time: 2–3 minutes with `-DskipTests -T4`.

## Workspace Commands

Run all `ike:` goals from the workspace root.

| Goal | Description |
|------|-------------|
| `mvn ike:status` | Git status across all repos |
| `mvn ike:pull` | `git pull --rebase` across all repos |
| `mvn ike:graph` | Print component dependency graph |
| `mvn ike:verify` | Check manifest consistency |
| `mvn ike:dashboard` | Combined status + verify + cascade overview |

## Feature Branch Workflow

```bash
mvn ike:feature-start          # prompts for name, branches all repos
mvn ike:feature-start-dry-run  # preview without making changes
mvn ike:feature-finish         # merges feature back to main
mvn ike:feature-finish-dry-run # preview without making changes
```

## IDE Setup (IntelliJ IDEA)

1. Open `ike-komet-desktop-ws` as a Maven project
2. IntelliJ discovers all subproject POMs automatically
3. Maven tool window shows all `ike:` goals — double-click to run
4. Interactive goals prompt for input in the Run console
