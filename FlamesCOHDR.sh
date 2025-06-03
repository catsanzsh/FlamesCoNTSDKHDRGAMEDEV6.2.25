#!/bin/bash
set -e  # stop on first error but keep window open afterwards
###############################################################################
# DevKitPro + Retro‑to‑Modern SDK Megapack                                     
# Installs Nintendo (GBA→Switch), *all the classic Ataris* (8‑bit/2600/5200/7800/
# Lynx/Jaguar/ST), and PlayStation (PSX→PS4) toolchains, plus a PS5 placeholder.
###############################################################################

# ---------- Styling ----------
CYAN="\033[1;36m"; GREEN="\033[1;32m"; RED="\033[1;31m"; NC="\033[0m"

# Pause the window even on crash ------------------------------------------------
pause() { echo -e "${CYAN}Press [ENTER] to close this window…${NC}"; read -r; }
trap pause EXIT INT TERM ERR

###############################################################################
# 1) devkitPro – Nintendo World ------------------------------------------------
###############################################################################

echo -e "${CYAN}Installing devkitPro pacman…${NC}"
sudo apt-get update
sudo apt-get install -y wget gnupg git build-essential pkg-config cmake curl unzip

# Add devkitPro repo & key
if ! grep -q "apt.devkitpro.org" /etc/apt/sources.list.d/devkitpro.list 2>/dev/null; then
  echo "deb https://apt.devkitpro.org/ stable main" | sudo tee /etc/apt/sources.list.d/devkitpro.list
  wget -qO- https://apt.devkitpro.org/devkitpro-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/devkitpro.gpg
fi
sudo apt-get update && sudo apt-get install -y devkitpro-keyring pacman

# Paths
if ! grep -q DEVKITPRO ~/.bashrc; then
  echo 'export DEVKITPRO=/opt/devkitpro' >> ~/.bashrc
  echo 'export PATH=$DEVKITPRO/devkitARM/bin:$DEVKITPRO/devkitPPC/bin:$DEVKITPRO/devkitA64/bin:$PATH' >> ~/.bashrc
fi
source ~/.bashrc

sudo pacman -S --noconfirm devkitARM devkitPPC devkitA64 libgba libnds libctru libnx

###############################################################################
# 2) Atari Family – from 1977 to 1996 -----------------------------------------
###############################################################################

echo -e "${CYAN}Installing cc65 for 8‑bit / 2600 / 5200 / Lynx targets…${NC}"
sudo apt-get install -y cc65  # includes cl65, ca65, etc.
# Ensure cc65 targets are in PATH
if ! grep -q CC65_HOME ~/.bashrc; then echo 'export CC65_HOME=/usr/share/cc65' >> ~/.bashrc; fi

# DASM (2600/7800 assembler)
echo -e "${CYAN}Installing DASM assembler…${NC}"
DASM_REL=https://github.com/dasm-assembler/dasm/releases/latest/download/dasm-2.20.14-linux.tar.gz
sudo wget -qO /tmp/dasm.tar.gz "$DASM_REL"
sudo tar -xzf /tmp/dasm.tar.gz -C /usr/local/bin --strip-components=1

# Atari Jaguar SDK
echo -e "${CYAN}Building Atari Jaguar GCC toolchain…${NC}"
mkdir -p "$HOME/sdk" && cd "$HOME/sdk"
if [ ! -d jaguar-sdk ]; then git clone --depth 1 https://github.com/cubanismo/jaguar-sdk.git; fi
cd jaguar-sdk && ./build.sh && cd ..
if ! grep -q JAGSDK ~/.bashrc; then
  echo 'export JAGSDK=$HOME/sdk/jaguar-sdk' >> ~/.bashrc
  echo 'export PATH=$JAGSDK/bin:$PATH' >> ~/.bashrc
fi
source ~/.bashrc

# Atari ST (68k) – use cross‑m68k‑elf GCC
echo -e "${CYAN}Installing m68k‑elf GCC for Atari ST dev…${NC}"
sudo apt-get install -y gcc-m68k-linux-gnu

###############################################################################
# 3) PlayStation Family – PSX → PS4 -------------------------------------------
###############################################################################

# PSXSDK (PS1)
echo -e "${CYAN}Installing PSXSDK…${NC}"
cd "$HOME/sdk" && [ ! -d psxsdk ] && git clone https://github.com/psxdev/psxsdk.git
cd psxsdk && ./toolchain/build-toolchain.sh && make && sudo make install && cd ..
if ! grep -q PSXSDK ~/.bashrc; then echo 'export PSXSDK=$HOME/sdk/psxsdk' >> ~/.bashrc; fi

# PS2SDK
echo -e "${CYAN}Installing PS2SDK…${NC}"
[ ! -d ps2dev ] && git clone https://github.com/ps2dev/ps2toolchain.git
cd ps2toolchain && ./install.sh && cd ..
[ ! -d ps2sdk ] && git clone https://github.com/ps2dev/ps2sdk.git
cd ps2sdk && ./install.sh && cd ..
if ! grep -q PS2DEV ~/.bashrc; then echo 'export PS2DEV=$HOME/ps2dev' >> ~/.bashrc; fi

# PSL1GHT (PS3)
echo -e "${CYAN}Installing PSL1GHT…${NC}"
[ ! -d PSL1GHT ] && git clone https://github.com/ps3dev/PSL1GHT.git
cd PSL1GHT && make toolchain && make && sudo make install && cd ..
if ! grep -q PSL1GHT ~/.bashrc; then echo 'export PSL1GHT=$HOME/PSL1GHT' >> ~/.bashrc; fi

# OpenOrbis (PS4)
echo -e "${CYAN}Installing OpenOrbis toolchain…${NC}"
[ ! -d OpenOrbis-PS4-Toolchain ] && git clone https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain.git
cd OpenOrbis-PS4-Toolchain && ./toolchain.sh && cd ..
if ! grep -q PS4SDK ~/.bashrc; then echo 'export PS4SDK=$HOME/OpenOrbis-PS4-Toolchain' >> ~/.bashrc; fi

###############################################################################
# 4) PlayStation 5 stub --------------------------------------------------------
###############################################################################

echo -e "${CYAN}PS5 SDK is proprietary; community toolchains not yet available.${NC}"
echo -e "${CYAN}Visit https://www.playstation.com/oss/ps5 for open‑source components.${NC}"

###############################################################################
# 5) Verification -------------------------------------------------------------
###############################################################################

echo -e "${CYAN}Verifying compilers…${NC}"
arm-none-eabi-gcc --version       || echo -e "${RED}devkitARM missing!${NC}"
cl65 -V                           || echo -e "${RED}cc65 missing!${NC}"
dasm -v | head -n1                || echo -e "${RED}DASM missing!${NC}"
m68k-linux-gnu-gcc -v             || echo -e "${RED}m68k‑elf GCC missing!${NC}"
m68k-unknown-elf-gcc --version    || echo -e "${RED}Jaguar GCC missing!${NC}"
psx-gcc --version                 || echo -e "${RED}PSXSDK compiler missing!${NC}"
ee-gcc --version                  || echo -e "${RED}PS2 EE compiler missing!${NC}"
ppu-lv2-gcc --version             || echo -e "${RED}PS3 PSL1GHT compiler missing!${NC}"
orbis-clang --version             || echo -e "${RED}PS4 OpenOrbis compiler missing!${NC}"

echo -e "${GREEN}All requested SDKs processed!${NC}"
