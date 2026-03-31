#!/usr/bin/env bash
# devKomet.sh — Workspace-aware dev launcher for Komet Desktop
#
# Constructs the JPMS module path from:
#   - target/classes directories for workspace modules (incremental compilation)
#   - JARs from komet-desktop/target/jlink-module-path/ for external dependencies
#
# Usage:
#   bin/devKomet.sh              # Standard launch
#   bin/devKomet.sh --debug      # Launch with JDWP on port 5005
#   bin/devKomet.sh --profile    # Launch with JProfiler agent
#
# Prerequisites:
#   mvn compile -DskipTests -T4                    # compile workspace modules
#   mvn process-resources -pl komet-desktop -T4    # stage external dependency JARs
#
# Works with IntelliJ Shell Script run configurations.
# The "Build Project" before-launch action triggers IntelliJ's incremental
# compiler, whose output lands in target/classes — this script picks it up.

set -euo pipefail

# Resolve workspace root (parent of bin/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

JLINK_MODULE_PATH="$WORKSPACE_ROOT/komet-desktop/target/jlink-module-path"

# ── Verify jlink-module-path exists ──────────────────────────────────────────
if [ ! -d "$JLINK_MODULE_PATH" ]; then
  echo "ERROR: $JLINK_MODULE_PATH does not exist."
  echo "Run:   mvn verify -DskipTests -T4   (or at minimum: mvn process-resources -pl komet-desktop)"
  exit 1
fi

# ── Known workspace module mappings ─────────────────────────────────────────
# Maps Maven artifactId → relative path from workspace root.
# These are the modules whose JARs in jlink-module-path can be replaced
# with target/classes for incremental development.
declare -A WS_MODULE_DIRS=(
  [artifact]="komet/artifact"
  [builder]="komet/builder"
  [classification]="komet/classification"
  [details]="komet/details"
  [executor]="komet/executor"
  [framework]="komet/framework"
  [knowledge-layout-editor]="komet/knowledge-layout-editor"
  [knowledge-layout]="komet/knowledge-layout"
  [komet-terms]="komet/komet-terms"
  [kview]="komet/kview"
  [list]="komet/list"
  [navigator]="komet/navigator"
  [preferences]="komet/preferences"
  [progress]="komet/progress"
  [rules]="komet/rules"
  [search]="komet/search"
  [sync]="komet/sync"
  [rocks-kb-engine]="rocks-kb/rocks-kb-engine"
  [composer]="tinkar-composer"
  [collection]="tinkar-core/collection"
  [common]="tinkar-core/common"
  [component]="tinkar-core/component"
  [entity]="tinkar-core/entity"
  [events]="tinkar-core/events"
  [terms]="tinkar-core/terms"
  [changeset-writer-provider]="tinkar-core/provider/changeset-writer-provider"
  [data-ephemeral-provider]="tinkar-core/provider/data-ephemeral-provider"
  [data-mvstore-provider]="tinkar-core/provider/data-mvstore-provider"
  [data-spinedarray-provider]="tinkar-core/provider/data-spinedarray-provider"
  [entity-provider]="tinkar-core/provider/entity-provider"
  [search-provider]="tinkar-core/provider/search-provider"
  [owl-extension]="tinkar-core/language-extensions/owl-extension"
  [reasoner-elk-snomed]="tinkar-core/reasoner/reasoner-elk-snomed"
  [reasoner-hybrid]="tinkar-core/reasoner/reasoner-hybrid"
  [reasoner-service]="tinkar-core/reasoner/reasoner-service"
)

# ── Build module path ───────────────────────────────────────────────────────
# Strategy: iterate jlink-module-path JARs (the authoritative dependency set).
# For each JAR that matches a workspace module with compiled target/classes,
# substitute the target/classes directory. Otherwise use the JAR as-is.
MODULE_PATH=""
WS_COUNT=0
SUBSTITUTED=()
FELL_BACK=()

for jar in "$JLINK_MODULE_PATH"/*.jar; do
  jar_name="$(basename "$jar")"
  # Extract artifactId: strip version suffix (e.g., entity-1.127.2-SNAPSHOT.jar -> entity)
  aid="$(echo "$jar_name" | sed -E 's/-[0-9]+\..*$//')"

  if [ -v 'WS_MODULE_DIRS[$aid]' ]; then
    classes_dir="$WORKSPACE_ROOT/${WS_MODULE_DIRS[$aid]}/target/classes"
    if [ -f "$classes_dir/module-info.class" ]; then
      # Use compiled classes instead of JAR for incremental development
      MODULE_PATH="${MODULE_PATH:+$MODULE_PATH:}$classes_dir"
      WS_COUNT=$((WS_COUNT + 1))
      SUBSTITUTED+=("$aid")
      continue
    else
      FELL_BACK+=("${WS_MODULE_DIRS[$aid]}")
    fi
  fi

  # External dependency or uncompiled workspace module — use the JAR
  MODULE_PATH="${MODULE_PATH:+$MODULE_PATH:}$jar"
done

# Add the launch module (komet-desktop itself is not in jlink-module-path)
LAUNCH_CLASSES="$WORKSPACE_ROOT/komet-desktop/target/classes"
if [ -f "$LAUNCH_CLASSES/module-info.class" ]; then
  MODULE_PATH="${MODULE_PATH:+$MODULE_PATH:}$LAUNCH_CLASSES"
  WS_COUNT=$((WS_COUNT + 1))
else
  # Fall back to the packaged JAR
  LAUNCH_JAR="$(ls "$WORKSPACE_ROOT"/komet-desktop/target/komet-desktop-*.jar 2>/dev/null | grep -v javadoc | grep -v sources | head -1)"
  if [ -n "$LAUNCH_JAR" ]; then
    MODULE_PATH="${MODULE_PATH:+$MODULE_PATH:}$LAUNCH_JAR"
    FELL_BACK+=("komet-desktop")
  else
    echo "ERROR: komet-desktop not built. Run: mvn package -DskipTests -T4"
    exit 1
  fi
fi

# Report status
if [ ${#FELL_BACK[@]} -gt 0 ]; then
  echo "WARNING: ${#FELL_BACK[@]} workspace module(s) not compiled (using installed JARs):"
  printf '  %s\n' "${FELL_BACK[@]}"
  echo "Run:   mvn compile -DskipTests -T4"
  echo ""
fi

# ── JVM arguments ───────────────────────────────────────────────────────────
JAVA_OPTS=(
  --enable-preview
  -Xmx42g
  --add-opens javafx.graphics/javafx.scene=org.controlsfx.controls
  --add-exports javafx.controls/com.sun.javafx.scene.control.behavior=dev.ikm.komet.navigator
  --add-exports javafx.base/com.sun.javafx.event=one.jpro.platform.file
  -Djava.util.concurrent.ForkJoinPool.common.exceptionHandler=dev.ikm.tinkar.common.alert.UncaughtExceptionAlertStreamer
  --add-modules jdk.incubator.vector
  --enable-native-access=javafx.graphics,javafx.media,javafx.web,org.controlsfx.controls
)

# ── Variant handling ────────────────────────────────────────────────────────
case "${1:-}" in
  --debug)
    echo "Launching with JDWP debug agent on port 5005 (suspend=n)"
    JAVA_OPTS+=(-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005)
    shift
    ;;
  --debug-suspend)
    echo "Launching with JDWP debug agent on port 5005 (suspend=y — waiting for debugger)"
    JAVA_OPTS+=(-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005)
    shift
    ;;
  --profile)
    echo "Launching with JProfiler agent on port 8849"
    JAVA_OPTS+=(-agentpath:/Applications/JProfiler.app/Contents/Resources/app/bin/macos/libjprofilerti.jnilib=port=8849,nowait)
    shift
    ;;
esac

# ── Launch ──────────────────────────────────────────────────────────────────
echo "Workspace modules on module-path: $WS_COUNT (of ${#WS_MODULE_DIRS[@]} known)"
echo "Working directory: $WORKSPACE_ROOT/komet-desktop"

cd "$WORKSPACE_ROOT/komet-desktop"

exec java "${JAVA_OPTS[@]}" \
  -p "$MODULE_PATH" \
  -m dev.ikm.komet.desktop/dev.ikm.komet.desktop.App \
  "$@"
