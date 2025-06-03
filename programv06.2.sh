#!/bin/bash
set -e  # stop on first error but keep window open afterwards
###############################################################################
# DevKitPro + Community SDK Megapack                                             
# Adds Atari 2600/7800/Jaguar and PlayStation 1‒4 toolchains, plus PS5 stub.     
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
sudo apt-get update && sudo apt-get install -y devkitpro-keyring pacman

# ---------- PATHs ----------
echo 'export DEVKITPRO=/opt/devkitpro' >> ~/.bashrc
echo 'export PATH=$DEVKITPRO/devkitARM/bin:$DEVKITPRO/devkitPPC/bin:$DEVKITPRO/devkitA64/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# ---------- Nintendo toolchains ----------
sudo pacman -S --noconfirm devkitARM devkitPPC devkitA64 libgba libnds libctru libnx

# =============================================================================
# Atari family
# =============================================================================
echo -e "${CYAN}Installing Atari 8-bit / 2600 / 7800 (cc65 + dasm)…${NC}"
sudo apt-get install -y cc65        # 6502 cross-compiler (2600, 8-bit) 
wget https://github.com/dasm-assembler/dasm/releases/latest/download/dasm-2.20.14-linux.tar.gz -O /tmp/dasm.tar.gz
sudo tar -xzf /tmp/dasm.tar.gz -C /usr/local/bin --strip-components=1

echo -e "${CYAN}Installing Atari Jaguar SDK…${NC}"
mkdir -p "$HOME/sdk" && cd "$HOME/sdk"
git clone https://github.com/cubanismo/jaguar-sdk.git
cd jaguar-sdk && ./build.sh            # builds GCC cross-compiler, rmac/rln
echo 'export JAGSDK=$HOME/sdk/jaguar-sdk' >> ~/.bashrc
echo 'export PATH=$JAGSDK/bin:$PATH'    >> ~/.bashrc
source ~/.bashrc
cd ..

# =============================================================================
# PlayStation family
# =============================================================================

echo -e "${CYAN}Installing PSXSDK (PS1)…${NC}"
git clone https://github.com/psxdev/psxsdk.git
cd psxsdk && ./toolchain/build-toolchain.sh && make && sudo make install
echo 'export PSXSDK=$HOME/sdk/psxsdk' >> ~/.bashrc ; source ~/.bashrc
cd ..

echo -e "${CYAN}Installing PS2SDK…${NC}"
git clone https://github.com/ps2dev/ps2toolchain.git
cd ps2toolchain && ./install.sh && cd ..
git clone https://github.com/ps2dev/ps2sdk.git && cd ps2sdk && ./install.sh
echo 'export PS2DEV=$HOME/ps2dev' >> ~/.bashrc ; source ~/.bashrc
cd ..

echo -e "${CYAN}Installing PSL1GHT (PS3)…${NC}"
git clone https://github.com/ps3dev/PSL1GHT.git
cd PSL1GHT && make toolchain && make && sudo make install
echo 'export PSL1GHT=$HOME/PSL1GHT' >> ~/.bashrc ; source ~/.bashrc
cd ..

echo -e "${CYAN}Installing OpenOrbis toolchain (PS4)…${NC}"
git clone https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain.git
cd OpenOrbis-PS4-Toolchain && ./toolchain.sh
echo 'export PS4SDK=$HOME/OpenOrbis-PS4-Toolchain' >> ~/.bashrc ; source ~/.bashrc
cd ..

# =============================================================================
# PlayStation 5 stub
# =============================================================================
echo -e "${CYAN}PS5 SDK is proprietary; no automatic installer available.${NC}"
echo -e "${CYAN}See https://www.playstation.com/oss/ps5 for open-source components.${NC}"

# ---------- Verification ----------
echo -e "${CYAN}Verifying key compilers…${NC}"
arm-none-eabi-gcc --version    || echo -e "${RED}devkitARM missing!${NC}"
m68k-unknown-elf-gcc --version || echo -e "${RED}Jaguar GCC missing!${NC}"
psx-gcc --version              || echo -e "${RED}PSXSDK compiler missing!${NC}"
ee-gcc --version               || echo -e "${RED}PS2 EE compiler missing!${NC}"
ppu-lv2-gcc --version          || echo -e "${RED}PS3 PSL1GHT compiler missing!${NC}"
orbis-clang --version          || echo -e "${RED}PS4 OpenOrbis compiler missing!${NC}"

echo -e "${GREEN}All requested SDKs processed!${NC}"
