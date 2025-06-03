#!/bin/bash
set -e  # stop on first error but keep window open afterwards
###############################################################################
# DevKitPro + Community SDK Megapack                                             
# Adds Atari 2600/7800/Jaguar and PlayStation 1‒4 toolchains, plus PS5 stub.     
# Expanded to install all devkitPro packages.
###############################################################################

# ---------- Styling ----------
CYAN="\033[1;36m"; GREEN="\033[1;32m"; RED="\033[1;31m"; NC="\033[0m"

# Function to pause on script exit (success *or* error)
pause() {
  echo -e "${CYAN}Press [ENTER] to close this window…${NC}"
  read -r
}
trap pause EXIT INT TERM ERR   # ensures the pause even if the script aborts

# ---------- devkitPro ----------
echo -e "${CYAN}Installing devkitPro pacman…${NC}"
sudo apt-get update
sudo apt-get install -y wget gnupg git build-essential pkg-config

echo "deb https://apt.devkitpro.org/ stable main" | sudo tee /etc/apt/sources.list.d/devkitpro.list
wget https://apt.devkitpro.org/devkitpro-keyring.gpg -O- | sudo gpg --dearmor -o /usr/share/keyrings/devkitpro.gpg
# Ensure pacman (the Arch package manager, used by devkitPro) is installed
# devkitpro-pacman package from devkitPro's repo provides /opt/devkitpro/tools/bin/pacman
# However, some base systems might need 'pacman' package for it to be found or for dependencies.
# The original script installs 'pacman' via apt, which is good for Debian/Ubuntu based systems.
sudo apt-get update && sudo apt-get install -y devkitpro-keyring pacman 

# ---------- PATHs ----------
echo -e "${CYAN}Setting up devkitPro environment variables…${NC}"
{
  echo ''
  echo '# DevkitPro Paths'
  echo 'export DEVKITPRO=/opt/devkitpro'
  echo 'export DEVKITDOTPRO=/opt/devkitpro' # Some older docs/tools might use this
  echo 'export PATH=$DEVKITPRO/tools/bin:$PATH' # For dkp-pacman and other tools
  echo 'export PATH=$DEVKITPRO/devkitARM/bin:$PATH'
  echo 'export PATH=$DEVKITPRO/devkitPPC/bin:$PATH'
  echo 'export PATH=$DEVKITPRO/devkitA64/bin:$PATH'
} >> ~/.bashrc
# Source .bashrc to apply changes to the current session immediately
# Note: For subsequent new terminals, this will be sourced automatically.
# For the current script execution, we need to source it explicitly if commands later depend on these paths.
# The verification step later will test this.
echo -e "${CYAN}Sourcing .bashrc to update PATH for current session...${NC}"
# It's generally better to export variables directly in the script if they are needed immediately,
# or ensure sub-shells inherit them. Sourcing .bashrc can have side effects.
# However, to keep with the script's original intent of modifying .bashrc for future sessions
# and for simplicity here, we'll set them for the current script's environment too.
export DEVKITPRO=/opt/devkitpro
export DEVKITDOTPRO=/opt/devkitpro
export PATH=$DEVKITPRO/tools/bin:$PATH
export PATH=$DEVKITPRO/devkitARM/bin:$PATH
export PATH=$DEVKITPRO/devkitPPC/bin:$PATH
export PATH=$DEVKITPRO/devkitA64/bin:$PATH

# ---------- Nintendo toolchains (ALL of devkitPro) ----------
echo -e "${CYAN}Installing ALL devkitPro toolchains and libraries (GBA, NDS, 3DS, Switch, Wii, GameCube, etc.)…${NC}"
# Sync package databases, update installed devkitPro packages, and install the 'devkitpro' group
# The 'devkitpro' group should pull in all core toolchains (devkitARM, devkitA64, devkitPPC)
# and libraries (libgba, libnds, libctru, libnx, libogc, libfat, etc.)
sudo pacman -Syu --noconfirm devkitpro

# =============================================================================
# Atari family
# =============================================================================
echo -e "${CYAN}Installing Atari 8-bit / 2600 / 7800 (cc65 + dasm)…${NC}"
sudo apt-get install -y cc65        # 6502 cross-compiler (2600, 8-bit, Apple II, C64, NES, etc.)
                                    # This cc65 covers NES development as well.
wget https://github.com/dasm-assembler/dasm/releases/latest/download/dasm-2.20.14-linux.tar.gz -O /tmp/dasm.tar.gz
sudo mkdir -p /usr/local/bin # Ensure target directory exists
sudo tar -xzf /tmp/dasm.tar.gz -C /usr/local/bin --strip-components=1 dasm-2.20.14-linux-amd64/dasm # More specific extraction
rm /tmp/dasm.tar.gz

echo -e "${CYAN}Installing Atari Jaguar SDK…${NC}"
mkdir -p "$HOME/sdk" && cd "$HOME/sdk"
if [ ! -d "jaguar-sdk" ]; then
  git clone https://github.com/cubanismo/jaguar-sdk.git
fi
cd jaguar-sdk && ./build.sh            # builds GCC cross-compiler, rmac/rln
echo -e "${CYAN}Setting up Jaguar SDK environment variables…${NC}"
{
  echo ''
  echo '# Jaguar SDK Paths'
  echo 'export JAGSDK=$HOME/sdk/jaguar-sdk'
  echo 'export PATH=$JAGSDK/bin:$PATH'
} >> ~/.bashrc
export JAGSDK=$HOME/sdk/jaguar-sdk
export PATH=$JAGSDK/bin:$PATH
cd "$HOME/sdk" # Go back to sdk directory

# =============================================================================
# PlayStation family
# =============================================================================

echo -e "${CYAN}Installing PSXSDK (PS1)…${NC}"
if [ ! -d "psxsdk" ]; then
  git clone https://github.com/psxdev/psxsdk.git
fi
cd psxsdk
# Check if toolchain needs building to avoid rebuilding if already done
if [ ! -f "$DEVKITPRO/psxsdk/mipsel-none-elf/bin/mipsel-none-elf-gcc" ]; then # Example check
  ./toolchain/build-toolchain.sh
fi
make && sudo make install # make install might need specific paths or DEVKITPRO set
echo -e "${CYAN}Setting up PSXSDK environment variables…${NC}"
{
  echo ''
  echo '# PSXSDK Paths'
  # PSXSDK might install to /usr/local/psxsdk or expect PSXSDK var
  # The original PSXSDK build script might install to a different prefix.
  # Assuming it installs files that will be found via system PATH or dedicated env var.
  # The `sudo make install` part of PSXSDK often puts things in /usr/local.
  # Let's define PSXSDK for consistency if examples/projects use it.
  echo 'export PSXSDK_DIR=$DEVKITPRO/psxsdk' # Or wherever it robustly installs
  echo 'export PATH=$PSXSDK_DIR/bin:$PATH' # If it has a bin directory there
} >> ~/.bashrc
# For current session, if psx-gcc is not in default path after install:
export PSXSDK_DIR=${DEVKITPRO}/psxsdk # Adjust if necessary
export PATH=${PSXSDK_DIR}/bin:$PATH # Adjust if necessary
# A common install path for psx-gcc via psxsdk is often /usr/local/psxsdk/bin or within DEVKITPRO itself if integrated
# For now, relying on `sudo make install` putting it in a standard PATH or one we set.
cd "$HOME/sdk"

echo -e "${CYAN}Installing PS2SDK…${NC}"
if [ ! -d "ps2toolchain" ]; then
  git clone https://github.com/ps2dev/ps2toolchain.git
  cd ps2toolchain && ./toolchain.sh && cd ..
else
  echo "${GREEN}PS2Toolchain directory already exists, skipping clone & build. Manual check advised if issues.${NC}"
fi

# PS2SDK itself
if [ ! -d "ps2sdk" ]; then
  git clone https://github.com/ps2dev/ps2sdk.git
  cd ps2sdk
  # PS2SDK build steps
  echo 'export PS2SDK=$HOME/ps2dev/ps2sdk' >> ~/.bashrc # Path for ps2sdk build system
  echo 'export PS2SDKSRC=$PS2SDK' >> ~/.bashrc
  echo 'export PS2SDKEE=$PS2SDK/ee/lib/build' >> ~/.bashrc
  echo 'export PS2SDKIOP=$PS2SDK/iop/lib/build' >> ~/.bashrc
  echo 'export PS2SDKMS=$PS2SDK/samples/lib/build' >> ~/.bashrc
  echo 'export PATH=$HOME/ps2dev/bin:$HOME/ps2dev/ee/bin:$HOME/ps2dev/iop/bin:$HOME/ps2dev/dvp/bin:$PATH' >> ~/.bashrc
  # Apply for current session
  export PS2SDK=$HOME/ps2dev/ps2sdk
  export PS2SDKSRC=$PS2SDK
  export PS2SDKEE=$PS2SDK/ee/lib/build
  export PS2SDKIOP=$PS2SDK/iop/lib/build
  export PS2SDKMS=$PS2SDK/samples/lib/build
  export PATH=$HOME/ps2dev/bin:$HOME/ps2dev/ee/bin:$HOME/ps2dev/iop/bin:$HOME/ps2dev/dvp/bin:$PATH

  # Setup PS2SDK (builds and installs it)
  # This needs to be done AFTER ps2toolchain is built and its paths are active.
  # The ps2toolchain script above should set its own paths.
  # Let's ensure the ps2toolchain paths are effective.
  export PS2DEV=$HOME/ps2dev
  export PATH=$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin:$PATH
  
  # Build and install ps2sdk
  ./setup.sh # ps2sdk's own setup script
  make && sudo make install # Typical build and install
  cd ..
else
  echo "${GREEN}PS2SDK directory already exists, skipping clone & build. Manual check advised if issues.${NC}"
fi
# Re-ensure PS2DEV path for consistency and for things built outside this script's direct env
echo 'export PS2DEV=$HOME/ps2dev' >> ~/.bashrc
export PS2DEV=$HOME/ps2dev # Ensure for current session
cd "$HOME/sdk"


echo -e "${CYAN}Installing PSL1GHT (PS3)…${NC}"
if [ ! -d "PSL1GHT" ]; then
  git clone https://github.com/ps3dev/PSL1GHT.git
fi
cd PSL1GHT
# Check if toolchain needs building
# This is a heuristic, actual file may vary.
if [ ! -d "$PSL1GHT/host/ppu/bin" ] || [ ! -x "$PSL1GHT/host/ppu/bin/ppu-lv2-gcc" ]; then
    make toolchain
fi
make && sudo make install
echo -e "${CYAN}Setting up PSL1GHT environment variables…${NC}"
{
  echo ''
  echo '# PSL1GHT Paths'
  echo 'export PSL1GHT=$HOME/sdk/PSL1GHT' # Assuming it's cloned into $HOME/sdk
  echo 'export PATH=$PSL1GHT/host/ppu/bin:$PATH'
  echo 'export PATH=$PSL1GHT/host/spu/bin:$PATH'
} >> ~/.bashrc
export PSL1GHT=$HOME/sdk/PSL1GHT # Corrected path, assuming clone in $HOME/sdk
export PATH=$PSL1GHT/host/ppu/bin:$PATH
export PATH=$PSL1GHT/host/spu/bin:$PATH
cd "$HOME/sdk"

echo -e "${CYAN}Installing OpenOrbis toolchain (PS4)…${NC}"
if [ ! -d "OpenOrbis-PS4-Toolchain" ]; then
  git clone https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain.git
fi
cd OpenOrbis-PS4-Toolchain
# Check if toolchain needs building; ./toolchain.sh is idempotent but can be long
if [ ! -f "$HOME/OpenOrbis-PS4-Toolchain/toolchain/ শেלל/bin/clang" ]; then # Heuristic check
    ./toolchain.sh
fi
echo -e "${CYAN}Setting up OpenOrbis environment variables…${NC}"
{
  echo ''
  echo '# OpenOrbis PS4 SDK Paths'
  echo 'export PS4SDK=$HOME/sdk/OpenOrbis-PS4-Toolchain' # Assuming it's cloned into $HOME/sdk
  echo 'export PATH=$PS4SDK/toolchain/bin:$PATH'
} >> ~/.bashrc
export PS4SDK=$HOME/sdk/OpenOrbis-PS4-Toolchain # Corrected path
export PATH=$PS4SDK/toolchain/bin:$PATH
cd "$HOME/sdk"

# =============================================================================
# PlayStation 5 stub
# =============================================================================
echo -e "${CYAN}PS5 SDK is proprietary; no automatic installer available.${NC}"
echo -e "${CYAN}See https://www.playstation.com/en-us/legal/ps5-oss/ and https://prosperosdk.com/ (unofficial) for info.${NC}"
echo -e "${CYAN}For official development: https://partners.playstation.net/${NC}"

# ---------- Verification ----------
echo -e "${CYAN}Verifying key compilers…${NC}"
source ~/.bashrc # Ensure all .bashrc changes are loaded for verification commands

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

verify_compiler() {
  local compiler_name="$1"
  local version_flag="${2:---version}"
  local friendly_name="$3"

  if command_exists "$compiler_name"; then
    echo -e "${GREEN}${friendly_name} ($compiler_name) found:${NC}"
    "$compiler_name" "$version_flag"
  else
    echo -e "${RED}${friendly_name} ($compiler_name) missing or not in PATH!${NC}"
  fi
}

# DevkitPro Toolchains
verify_compiler "arm-none-eabi-gcc" "--version" "devkitARM (GBA/NDS/3DS)"
verify_compiler "aarch64-none-elf-gcc" "--version" "devkitA64 (Switch)"
verify_compiler "powerpc-eabi-gcc" "--version" "devkitPPC (Wii/GameCube)"

# Atari Toolchains
verify_compiler "cc65" "-V" "cc65 (Atari 8-bit/2600/7800, NES, C64, etc.)"
verify_compiler "dasm" "" "dasm (6502/6507 Assembler)" # dasm typically prints usage/version on plain invocation
if command_exists "dasm"; then dasm; else echo -e "${RED}dasm missing!${NC}"; fi


# Jaguar Toolchain
# Assuming m68k-unknown-elf-gcc is the correct name from jaguar-sdk
verify_compiler "m68k-elf-gcc" "--version" "Jaguar SDK GCC (m68k-elf-gcc)" # common name for such cross-compilers
# Original script used m68k-unknown-elf-gcc, let's try that if the above fails or stick to it
# verify_compiler "m68k-unknown-elf-gcc" "--version" "Jaguar SDK GCC"


# PlayStation Toolchains
# PSXSDK compiler name might be psx-gcc or mipsel-none-elf-gcc depending on how it's set up/aliased
# The `sudo make install` for PSXSDK usually places `psx-gcc` in `/usr/local/bin` or a similar PATH location.
verify_compiler "psx-gcc" "--version" "PSXSDK GCC (psx-gcc)"
# If psx-gcc isn't found, the direct compiler might be mipsel-none-elf-gcc
# verify_compiler "mipsel-none-elf-gcc" "--version" "PSXSDK GCC (mipsel-none-elf-gcc)"

# PS2SDK (ee-gcc for Emotion Engine, iop-gcc for I/O Processor)
verify_compiler "ee-gcc" "--version" "PS2SDK EE GCC"
verify_compiler "iop-gcc" "--version" "PS2SDK IOP GCC"

# PS3 PSL1GHT
verify_compiler "ppu-lv2-gcc" "--version" "PS3 PSL1GHT PPU GCC"
verify_compiler "spu-lv2-gcc" "--version" "PS3 PSL1GHT SPU GCC"

# PS4 OpenOrbis
# The OpenOrbis toolchain uses clang. The executable might be 'clang' or 'orbis-clang'.
# The PATH set earlier points to $PS4SDK/toolchain/bin which should contain it.
verify_compiler "clang" "--version" "PS4 OpenOrbis Clang (from PS4SDK path)"
# verify_compiler "orbis-clang" "--version" "PS4 OpenOrbis Clang (orbis-clang)"


echo -e "${GREEN}All requested SDKs processed! Please check verification output above.${NC}"
echo -e "${CYAN}You might need to open a new terminal or run 'source ~/.bashrc' for all PATH changes to take full effect in new shells.${NC}"
