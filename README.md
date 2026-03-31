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

## Fast Incremental Development

The full `mvn clean verify` cycle compiles every module, assembles jlink images,
and builds native installers — this takes minutes and is only needed for
distribution builds. For day-to-day development you can **run and debug the
application directly from IntelliJ** with incremental compilation that takes
seconds, even when editing source in any subproject (tinkar-core, komet, etc.).

### One-time setup

1. **Do one full build** so all dependencies are resolved and compiled:

   ```bash
   mvn clean install -DskipTests -T4
   ```

2. **Open `ike-komet-desktop-ws`** as a Maven project in IntelliJ (if not
   already). IntelliJ will import all subproject modules.

3. **Verify Project SDK** is set to Java 25 with preview features enabled:
   **File > Project Structure > Project > SDK** and
   **File > Project Structure > Project > Language level** = "25 (Preview)".

### Run configurations

The workspace includes shared IntelliJ run configurations in `.run/`:

| Configuration | Type | Use case |
|---|---|---|
| **devKomet** | Shell Script | Workspace-aware launch — builds module path from `target/classes` across all subprojects |
| **devKomet (Debug)** | Shell Script | Same, with JDWP debug agent on port 5005 |
| **Komet (Dev)** | Application | Direct IntelliJ launch (may fail with Maven 4 module resolution — see note below) |
| **Komet (Dev Debug)** | Application | Same, but use the Debug button for breakpoints |
| **launchKomet** | Shell Script | Runs the jlink standard image (requires full Maven build) |
| **debugKomet** | Shell Script | Runs the jlink debug image with JDWP suspended on port 8000 |
| **profileKomet** | Shell Script | Runs the jlink profile image with JProfiler agent on port 8849 |

For fast iteration, use **devKomet** or **devKomet (Debug)**. The others
launch pre-built jlink images and are useful for testing the packaged
application.

> **Maven 4 + IntelliJ note:** The "Komet (Dev)" Application-type run
> configurations rely on IntelliJ's JPMS module resolution, which does not
> correctly handle Maven 4 workspaces where subprojects use `root="true"`.
> This causes "Module is not in dependencies" errors. The **devKomet** Shell
> Script configurations bypass this limitation by constructing the module path
> directly from `target/classes` directories and staged dependency JARs.

### The devKomet launcher

The `bin/devKomet.sh` script is the workspace-aware dev launcher. It constructs
the correct JPMS `--module-path` by:

1. Scanning `komet-desktop/target/jlink-module-path/` for the authoritative set
   of dependency JARs (staged by `maven-dependency-plugin` during the build)
2. For each JAR that corresponds to a workspace module with a compiled
   `target/classes/module-info.class`, substituting the `target/classes`
   directory — so IntelliJ's incremental compilation is picked up immediately
3. Using the original JAR for external dependencies and any workspace modules
   not yet compiled locally

```bash
# Standard launch
bin/devKomet.sh

# Debug (JDWP on port 5005, suspend=n)
bin/devKomet.sh --debug

# Debug with suspend (waits for debugger attachment)
bin/devKomet.sh --debug-suspend

# Profile (JProfiler agent on port 8849)
bin/devKomet.sh --profile
```

JVM arguments (heap size, `--add-opens`, `--add-exports`, etc.) are declared in
the `dev-config` section of `workspace.yaml`.

### The fast iteration workflow

```
Edit code in any subproject  →  Click Run (devKomet)  →  App launches
        (tinkar-core, komet, komet-desktop, etc.)
```

When you click **Run** on the "devKomet" configuration, IntelliJ:

1. **Runs "Build Project"** (configured as a before-launch action), which
   incrementally compiles only the `.java` files you changed — across all
   modules in the workspace (tinkar-core, rocks-kb, komet, komet-desktop, etc.)
2. **Executes `bin/devKomet.sh`**, which builds the module path from the freshly
   compiled `target/classes` directories and launches the app with the required
   `--add-opens`, `--add-exports`, and `--enable-preview` flags
3. **Skips** jlink, jpackage, resource filtering, and every other Maven phase

This means you can edit a class in `tinkar-core`, click Run, and see the change
reflected in the running desktop app in seconds.

### Debugging across subprojects

Use **devKomet (Debug)** and attach IntelliJ's debugger via
**Run > Attach to Process** or a Remote JVM Debug configuration on port 5005:

- Set breakpoints in any module — `tinkar-core`, `komet`, `komet-desktop`, etc.
- Step into cross-module calls seamlessly
- Evaluate expressions and inspect variables
- Use **Hot Reload** (Build > Recompile) for some changes without restarting

### When you still need a full Maven build

| Scenario | Command |
|---|---|
| First build / clean slate | `mvn clean install -DskipTests -T4` |
| Testing the jlink runtime image | `mvn clean verify -DskipTests -T4` then use the `launchKomet` run config |
| Building the native installer | `mvn clean verify -T4` (runs jpackage in the `verify` phase) |
| After changing `pom.xml` or dependencies | `mvn clean install -DskipTests -T4`, then **Reload Maven Projects** in IntelliJ |
| Running the full test suite | `mvn clean verify -T4` |

### Tips

- **Reload Maven Projects** (Ctrl+Shift+O / Cmd+Shift+I) after any POM change
  so IntelliJ picks up new dependencies.
- If IntelliJ reports unresolved modules after `ike:init` clones a new repo, do
  a `mvn clean install -DskipTests -T4` followed by a Maven reimport.
- The dev run configurations allocate up to 42 GB heap (`-Xmx42g`). Edit the VM
  options in the run configuration if your machine has less RAM.

## Build Profiles

Activate profiles with `-P<name>` on the Maven command line, or toggle them in
IntelliJ's Maven tool window under **Profiles**.

| Profile | Activation | Description |
|---|---|---|
| `jlink-standard` | Manual | Builds the standard jlink runtime image |
| `jlink-debug` | Manual | Builds the debug jlink image (JDWP on port 8000, suspended) |
| `jlink-profile` | Manual | Builds the profiling jlink image (JProfiler + JDWP) |
| `create-desktop-installer` | Default (on) | Runs jpackage to create native installers (.pkg / .rpm / .msi) |
| `scenic-view` | Manual | Adds ScenicView for JavaFX scene graph debugging |
