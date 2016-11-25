#!/bin/sh

set -eu

_main() {
  local tmpdir
  tmpdir="$(mktemp -d git_lfs_install.XXXXXX)"

  cd "$tmpdir"
  curl -Lo fly https://github.com/concourse/concourse/releases/download/v2.5.0/fly_linux_amd64
  mv fly /usr/bin
  chmod 755 /usr/bin/fly
  cd ..
  rm -rf "$tmpdir"
}

_main "$@"
