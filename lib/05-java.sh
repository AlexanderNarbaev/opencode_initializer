#!/usr/bin/env bash
# lib/05-java.sh — Java 25 via Adoptium + Gradle + Maven + jbang + Zig (STEP 4)
set -euo pipefail

if ([ "$MODE" = "full" ] || [ "$MODE" = "reinit" ] || [ "$MODE" = "update" ]) && _gate "INTERACTIVE_DO_JAVA"; then
  section "Java 25 + Gradle + Maven + jbang"

  if ! command -v java &>/dev/null; then
    JAVA_MAJOR=25
    ADOPTIUM_URL="${JAVA_MIRROR}/v3/binary/latest/${JAVA_MAJOR}/ga/linux/${ARCH_TYPE:-x64}/jdk/hotspot/normal/eclipse"
    JAVA_TAR="/tmp/jdk${JAVA_MAJOR}.tar.gz"
    info "Downloading Java ${JAVA_MAJOR} from Adoptium..."
    if _curl "$ADOPTIUM_URL" "$JAVA_TAR" 2>/dev/null; then
      sudo mkdir -p /usr/lib/jvm
      sudo tar -xzf "$JAVA_TAR" -C /usr/lib/jvm 2>/dev/null && \
        sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-${JAVA_MAJOR}*/bin/java 1 2>/dev/null && \
        sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-${JAVA_MAJOR}*/bin/javac 1 2>/dev/null && \
        log "Java ${JAVA_MAJOR} (Adoptium)" || warn "Java Adoptium setup failed"
      rm -f "$JAVA_TAR"
    else
      warn "Adoptium download failed — trying apt fallback"
    fi
  else
    log "Java $(java -version 2>&1 | head -1) already installed"
  fi

  if [ ! -d "$HOME/.sdkman" ]; then
    command -v zip &>/dev/null || sudo apt-get install -y zip 2>/dev/null || true
    command -v unzip &>/dev/null || sudo apt-get install -y unzip 2>/dev/null || true
    _curl "https://get.sdkman.io" /tmp/sdkman-install.sh 2>/dev/null && \
      bash /tmp/sdkman-install.sh 2>/dev/null; rm -f /tmp/sdkman-install.sh || \
      warn "SDKMAN install failed — using apt fallback for build tools"
  fi
  set +u; source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true; set -u
  _sdk() {
    local pkg="$1" ver="${2:-}"; set +u
    if command -v "${pkg%% *}" &>/dev/null; then log "$pkg already installed"; set -u; return 0; fi
    if [ -n "$ver" ]; then
      sdk install "$pkg" "$ver" 2>/dev/null || { warn "sdk install $pkg $ver failed, trying latest"; sdk install "$pkg" 2>/dev/null || warn "sdk install $pkg failed entirely"; }
    else
      sdk install "$pkg" 2>/dev/null || warn "sdk install $pkg failed"
    fi
    set -u
  }
  _sdk gradle
  _sdk maven
  _sdk jbang
  _sdk kotlin

  if ! command -v zig &>/dev/null; then
    if command -v snap &>/dev/null; then
      sudo snap install zig --classic 2>/dev/null && log "Zig from snap"
    fi
    if ! command -v zig &>/dev/null; then
      ZIG_VER="0.16.0"; ZIG_TARGET=""
      [ "$ARCH" = "aarch64" ] && ZIG_TARGET="aarch64" || ZIG_TARGET="x86_64"
      ZIG_URL="$ZIG_MIRROR/$ZIG_VER/zig-linux-${ZIG_TARGET}-$ZIG_VER.tar.xz"
      ZIG_DIR="/usr/local/lib/zig-$ZIG_VER"
      if [ ! -d "$ZIG_DIR" ]; then
        if _curl "$ZIG_URL" /tmp/zig.tar.xz 2>/dev/null; then
          sudo mkdir -p "$ZIG_DIR" && \
          sudo tar -xJf /tmp/zig.tar.xz -C "$ZIG_DIR" --strip-components=1 2>/dev/null && \
          sudo ln -sf "$ZIG_DIR/zig" /usr/local/bin/zig && \
          log "Zig $ZIG_VER installed (direct)" || warn "Zig not available"
        else
          warn "Zig download failed"
        fi
        rm -f /tmp/zig.tar.xz
      else
        log "Zig $ZIG_VER already installed"
      fi
    fi
  fi

  if ! command -v java &>/dev/null; then
    sudo apt-get install -y -qq openjdk-25-jdk gradle maven 2>/dev/null && log "Java/Gradle/Maven from apt" || warn "Java unavailable"
  fi
  _step_done step_java
fi
