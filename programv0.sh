#!/bin/bash

# =============================================================================
#  INSTALL ALL DEVKITPRO TOOLCHAINS
#  (devkitARM, devkitPPC, devkitA64 + libraries)
# =============================================================================
# Run this on a Debian/Ubuntu system. Must have sudo access.
# =============================================================================

# Define colors
CYAN="\033[1;36m"
GREEN="\033[1;32m"
RED="\033[1;31m"
NC="\033[0m"  # No Color

echo -e "${CYAN}Installing devkitPro pacman first...${NC}"

# Install devkitPro pacman (the package manager for all toolchains)
sudo apt-get update
sudo apt-get install -y wget gnupg

# Add devkitPro repository
sudo tee /etc/apt/sources.list.d/devkitpro.list > /dev/null <<EOF
deb https://apt.devkitpro.org/ stable main
EOF

wget https://apt.devkitpro.org/devkitpro-keyring.gpg -O- | sudo gpg --dearmor -o /usr/share/keyrings/devkitpro.gpg

# Update and install devkitPro keyring
sudo apt-get update
sudo apt-get install -y devkitpro-keyring

# Install pacman (if not installed)
sudo apt-get install -y pacman

# Set up devkitPro environment variables
echo "export DEVKITPRO=/opt/devkitpro" >> ~/.bashrc
echo "export PATH=\$DEVKITPRO/devkitARM/bin:\$DEVKITPRO/devkitPPC/bin:\$DEVKITPRO/devkitA64/bin:\$PATH" >> ~/.bashrc

# It’s best practice to tell the user to source or re-open the terminal.
# But if you want to source it immediately in the same session, do so:
source ~/.bashrc

echo -e "${GREEN}devkitPro pacman ready!${NC}"

# Install all toolchains now
echo -e "${CYAN}Installing devkitARM (GBA/DS/3DS)...${NC}"
sudo pacman -S --noconfirm devkitARM

echo -e "${CYAN}Installing devkitPPC (GameCube/Wii)...${NC}"
sudo pacman -S --noconfirm devkitPPC

echo -e "${CYAN}Installing devkitA64 (Nintendo Switch)...${NC}"
sudo pacman -S --noconfirm devkitA64

# Install basic libraries
echo -e "${CYAN}Installing libraries: libgba, libnds, libctru, libnx...${NC}"
sudo pacman -S --noconfirm libgba libnds libctru libnx

echo -e "${GREEN}ALL DEVKITPRO TOOLCHAINS INSTALLED SUCCESSFULLY!${NC}"

# Test output
echo -e "${CYAN}Verifying installations...${NC}"
arm-none-eabi-gcc --version || echo -e "${RED}devkitARM missing!${NC}"
powerpc-eabi-gcc --version || echo -e "${RED}devkitPPC missing!${NC}"
aarch64-none-elf-gcc --version || echo -e "${RED}devkitA64 missing!${NC}"

echo -e "${GREEN}Setup complete! Time to build games across GBA, DS, 3DS, Wii, GameCube, and Switch!${NC}"

# Keep the window open by waiting for user input.
echo -e "${CYAN}Press [ENTER] to close this window...${NC}"
read -r
