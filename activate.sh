#!/bin/bash

set -euo pipefail

dotfiles_dir=$(cd "$(dirname "$0")"; pwd)

if ! vim --version | grep -q '2nd user vimrc file'; then
  for name in vim vimrc vimrc.bundles; do
    rm -rf "${HOME}/.${name}"
    ln -s "${dotfiles_dir}/${name}" "${HOME}/.${name}"
  done
fi

if command -v nvim >/dev/null 2>&1; then
  mkdir -p "${HOME}/.config"
  rm -rf "${HOME}/.config/nvim"
  ln -s "${dotfiles_dir}/config/nvim" "${HOME}/.config/nvim"
fi

vim +PlugInstall +PlugClean! +qall

if command -v nvim >/dev/null 2>&1; then
  nvim +PlugInstall +PlugClean! +qall
fi
