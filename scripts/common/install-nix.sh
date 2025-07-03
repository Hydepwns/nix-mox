#!/bin/sh

# This script installs the Nix package manager on your system by
# downloading a binary distribution and running its installer script
# (which in turn creates and populates /nix).

oops() {
  echo "$0:" "$@" >&2
  exit 1
}

umask 0022

tmpDir="$(mktemp -d -t nix-binary-tarball-unpack.XXXXXXXXXX ||
  oops "Can't create temporary directory for downloading the Nix binary tarball")"
cleanup() {
  rm -rf "$tmpDir"
}
trap cleanup EXIT INT QUIT TERM

require_util() {
  command -v "$1" >/dev/null 2>&1 ||
    oops "you do not have '$1' installed, which I need to $2"
}

case "$(uname -s).$(uname -m)" in
Linux.x86_64)
  hash=17ed09eaf0ff02ae33f97590cbd2fc2c60567e217267cdc04fe0bc300111370d
  path=hdzchq9q8b20srq1qll02qfkzxqs267f/nix-2.29.0-x86_64-linux.tar.xz
  system=x86_64-linux
  ;;
Linux.i?86)
  hash=38b713063b6b122bd2dd023e873d56636020523ab5f575fc325463ef81f204b3
  path=kq8v28xn0akhk7w224s9jrw71789krcm/nix-2.29.0-i686-linux.tar.xz
  system=i686-linux
  ;;
Linux.aarch64)
  hash=8bbf6573f557a6180cc23f78795741a15074926d415f43b77b8c677a697acf70
  path=cw31ak22bijbg1aikdq21m1y1p162bvh/nix-2.29.0-aarch64-linux.tar.xz
  system=aarch64-linux
  ;;
Linux.armv6l)
  hash=8983d0fae1c4cc79378200554ff315ae3c71af5e21bcd664f85c716fb763ea02
  path=j938isd6kczy5ywayynfy89d7cvrjwgb/nix-2.29.0-armv6l-linux.tar.xz
  system=armv6l-linux
  ;;
Linux.armv7l)
  hash=f7674fd07fa3f37eba8d9d99c6195bae6ac02858abea50d5c29374d1a17ddf7b
  path=cqn2w0f5wfvkmi97lij5wq27nmx5zlkb/nix-2.29.0-armv7l-linux.tar.xz
  system=armv7l-linux
  ;;
Linux.riscv64)
  hash=0fcd1adde6106dcce1edeb7e6e456c3c428a1fa703c207132fdd28dd8e6ad798
  path=2azkdbq1rdry8s0wwq59lv745kqlbn9x/nix-2.29.0-riscv64-linux.tar.xz
  system=riscv64-linux
  ;;
Darwin.x86_64)
  hash=d0fd64615d1120cff7968edc1dfec9500d73650e7eb29aaca05e7a548d6bea8f
  path=m9fh7zl5q4dg6j1a9bvs2xlynqvk0b17/nix-2.29.0-x86_64-darwin.tar.xz
  system=x86_64-darwin
  ;;
Darwin.arm64 | Darwin.aarch64)
  hash=f7428a9490f7a1973b0378253e933cb87ee728183f45006bb9afd9258d3d7cd5
  path=9x4gp8lh9ijmnmg6zgdkjy135hky4g81/nix-2.29.0-aarch64-darwin.tar.xz
  system=aarch64-darwin
  ;;
*) oops "sorry, there is no binary distribution of Nix for your platform" ;;
esac

# Use this command-line option to fetch the tarballs using nar-serve or Cachix
if [ "${1:-}" = "--tarball-url-prefix" ]; then
  if [ -z "${2:-}" ]; then
    oops "missing argument for --tarball-url-prefix"
  fi
  url=${2}/${path}
  shift 2
else
  url=https://releases.nixos.org/nix/nix-2.29.0/nix-2.29.0-$system.tar.xz
fi

tarball=$tmpDir/nix-2.29.0-$system.tar.xz

require_util tar "unpack the binary tarball"
if [ "$(uname -s)" != "Darwin" ]; then
  require_util xz "unpack the binary tarball"
fi

if command -v curl >/dev/null 2>&1; then
  fetch() { curl --fail -L "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget "$1" -O "$2"; }
else
  oops "you don't have wget or curl installed, which I need to download the binary tarball"
fi

echo "downloading Nix 2.29.0 binary tarball for $system from '$url' to '$tmpDir'..."
fetch "$url" "$tarball" || oops "failed to download '$url'"

if command -v sha256sum >/dev/null 2>&1; then
  hash2="$(sha256sum -b "$tarball" | cut -c1-64)"
elif command -v shasum >/dev/null 2>&1; then
  hash2="$(shasum -a 256 -b "$tarball" | cut -c1-64)"
elif command -v openssl >/dev/null 2>&1; then
  hash2="$(openssl dgst -r -sha256 "$tarball" | cut -c1-64)"
else
  oops "cannot verify the SHA-256 hash of '$url'; you need one of 'shasum', 'sha256sum', or 'openssl'"
fi

if [ "$hash" != "$hash2" ]; then
  oops "SHA-256 hash mismatch in '$url'; expected $hash, got $hash2"
fi

unpack=$tmpDir/unpack
mkdir -p "$unpack"
tar -xJf "$tarball" -C "$unpack" || oops "failed to unpack '$url'"

script=$(echo "$unpack"/*/install)

[ -e "$script" ] || oops "installation script is missing from the binary tarball!"
export INVOKED_FROM_INSTALL_IN=1
"$script" "$@"
