#!/usr/bin/env bash
set -eu

if command -v curl >/dev/null; then
	echo "You must have curl installed."
	exit 1
fi

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"

# Install brew on macOS
if [[ "$(uname)" == "Darwin" ]]; then
	if ! command -v brew >/dev/null; then
		echo "Installing brew" >&2
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	fi

	# Install essentials for further installation
	brew update
	brew upgrade
	brew install cmake coreutils git
fi

if ! chezmoi="$(command -v chezmoi)"; then
	bin_dir="${HOME}/.local/bin"
	chezmoi="${bin_dir}/chezmoi"
	echo "Installing chezmoi to '${chezmoi}'" >&2
	chezmoi_install_script="$(curl -fsSL https://chezmoi.io/get)"
	sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
	unset chezmoi_install_script bin_dir
fi

echo "Running chezmoi" >&2
${chezmoi} init --apply --source="${script_dir}"

# Install rtx
if [[ "$(uname)" == "Darwin" ]]; then
	brew install rtx
elif [[ "$CODESPACE" == "true" ]]; then
	sh -c "$(curl -fsSL curl https://rtx.pub/install.sh)"
else
	sudo install -dm 755 /etc/apt/keyrings
	wget -qO - https://rtx.pub/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/rtx-archive-keyring.gpg 1>/dev/null
	echo "deb [signed-by=/etc/apt/keyrings/rtx-archive-keyring.gpg arch=amd64] https://rtx.pub/deb stable main" | sudo tee /etc/apt/sources.list.d/rtx.list
	sudo apt update
	sudo apt install -y rtx
fi
rtx trust ~/.config/rtx/config.toml
