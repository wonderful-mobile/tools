#!/bin/bash

#set -e

#
# Copyright (C) 2025 blueskychan-dev
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

if [ ! -f "Makefile" ]; then
    echo "Makefile not found, please run this script in kernel source directory"
    exit 1
fi

KERNEL_VERSION=$(make kernelversion | grep -v "Entering\|Leaving")
KERNEL_MAJOR=$(echo $KERNEL_VERSION | cut -d'.' -f1)
KERNEL_MINOR=$(echo $KERNEL_VERSION | cut -d'.' -f2)

install_kernel_su_next() {
    if [ -d "KernelSU-Next" ]; then
        rm -rf KernelSU-Next
    fi
    local version_flag=$1
    curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash $version_flag
}

patch_susfs_old() {
    echo "Entering KernelSU-Next directory..."
    cd KernelSU-Next || exit 1
    echo "Applying SUSFS patch for KernelSU-Next..."
    local patch_url="https://raw.githubusercontent.com/galaxybuild-project/tools/refs/heads/main/Patches/0001_susfs_157_for_ksunext.patch"
    curl -LSs "$patch_url" > susfs.patch
    patch -p1 < susfs.patch
    rm -f susfs.patch
    cd ..
}

patch_susfs_gki() {
    echo "Applying SuSFS patch v1.5.9 for kernel >= 5.10..."
    local patch_url="https://raw.githubusercontent.com/galaxybuild-project/tools/refs/heads/main/Patches/0001_susfs_157_for_ksunext.patch"
    curl -LSs "$patch_url" > susfs-gki.patch
    patch -p1 < susfs-gki.patch
    rm -f susfs-gki.patch
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  help                Show this help message and exit"
    echo "  <commit-or-tag>:    Sets up or updates the KernelSU-Next to specified tag or commit."
}

# Parse command-line arguments
KERNELSU_VERSION=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        help)
            show_help
            exit 0
            ;;
        *)
            KERNELSU_VERSION="$1"
            shift
            ;;
    esac
done

VERSION_FLAG=""
if [ -n "$KERNELSU_VERSION" ]; then
    VERSION_FLAG="-s $KERNELSU_VERSION"
fi

echo "############################################"
echo "KernelSU Next with SuSFS Patches"
echo "Made by @blueskychan-dev, @sidex15, @rifsxd"
echo "Last updated: 31 Dec 2025"
echo "############################################"
echo ""
echo "⚠️ This script will be **DEPRECATED** soon!"
echo "Please check the official SuSFS branch:"
echo "➡️ https://rifsxd.github.io/KernelSU-Next/pages/installation.html"
echo ""
echo "For more info, visit:"
echo "➡️ https://t.me/galaxybuild_project/268"
echo ""

# Check if kernel is supported
if [ "$KERNEL_MAJOR" -lt 4 ] || ([ "$KERNEL_MAJOR" -eq 4 ] && [ "$KERNEL_MINOR" -lt 9 ]); then
    echo "Kernel version is too old. SUSFS requires kernel version >= 4.9. Aborting."
    exit 1
fi

# Decide patch method
if [ "$KERNEL_MAJOR" -gt 5 ] || ([ "$KERNEL_MAJOR" -eq 5 ] && [ "$KERNEL_MINOR" -ge 10 ]); then
    echo "Kernel version $KERNEL_VERSION detected: applying GKI SuSFS patch (for 5.10+ kernels)"
    patch_susfs_gki
else
    echo "Kernel version $KERNEL_VERSION detected: applying old SuSFS patch (for KernelSU-Next)"
    echo "Checking if KernelSU-Next is installed..."
    if [ -d "KernelSU-Next" ]; then
        echo "KernelSU-Next is installed, uninstalling..."
        rm -rf KernelSU-Next
    else
        echo "KernelSU-Next is not installed"
    fi
    echo "Installing KernelSU-Next..."
    install_kernel_su_next "$VERSION_FLAG"
    patch_susfs_old
fi

echo ""
echo "✅ Done! Thanks for using my script :3"
