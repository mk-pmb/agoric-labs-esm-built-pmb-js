#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function rebuild () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local REPOPATH="$(readlink -m -- "$BASH_SOURCE"/../..)"
  cd -- "$REPOPATH" || return $?

  local NME='node_modules/esm'
  git status --porcelain -- package.json | grep . && return 4$(
    echo "E: Better commit these files, because npm might clobber them." >&2)
  [ ! -d "$NME" ] || rm --recursive -- "$NME" || return $?
  local INST=( npm install 'agoric-labs/esm#Agoric-built' )
  echo "D: ${INST[*]}"
  "${INST[@]}" || return $?
  git checkout -- package.json

  local ESM_VER='require("./node_modules/esm/package.json").version'
  ESM_VER="$(node -p "$ESM_VER")"
  [ -n "$ESM_VER" ] || return 4$(echo "E: Failed to detect esm version" >&2)
  sed -re 's!^( *"version": ")[^"]*!\1'"$ESM_VER!" -i package.json || return $?

  move_files_from "$NME" || return $?

  rm -- "$NME"/package.json || return $?
  mv --no-target-directory -- "$NME"/LICENSE LICENSE.txt || return $?
  cp --no-target-directory -- build/README.top.md README.md || return $?
  cat -- "$NME"/README.md >>README.md || return $?
  rm -- "$NME"/README.md || return $?

  rmdir -- "$NME"{/esm,} || return $?

  echo '+OK rebuilt. git status:'
  git status --short
}


function move_files_from () {
  local FROM="$1"
  local FILES=()
  readarray -t FILES < <(node -p '
    require("./node_modules/esm/package.json").files.join("\n")')
  local ITEM=
  local SUBDIR=
  for ITEM in "${FILES[@]}"; do
    SUBDIR="$(dirname -- "$ITEM")"
    mkdir --parents -- "$SUBDIR"
    mv --target-directory="$SUBDIR" -- "$FROM/$ITEM" || return $?
  done
}


rebuild "$@"; exit $?
