#!/usr/bin/env bash

# Most of the script is based on https://github.com/jrtashjian/homelab-ansible/blob/master/init.sh

set -o errexit
set -o nounset

# Check if the script is running with sudo privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script requires superuser privileges. Please run it with sudo."
  exit 1
fi

os=$(uname -s)

bootstrap_macos() {
  # Check if 'brew' is already installed
  if ! command -v brew &>/dev/null; then
    echo "You need to have Homebrew installed on your system."
    exit 1
  fi

  # Check if 'ansible' is already installed
  if ! command -v ansible &>/dev/null; then
    echo "Installing Ansible..."
    brew install ansible
  fi

  if ! command -v op &>/dev/null; then
    echo "Installing 1Password CLI..."
    brew install 1password-cli
  fi

}

bootstrap_linux() {
  # Check if 'ansible' is already installed
  if ! command -v ansible &>/dev/null; then
    if command -v apt &>/dev/null; then
      install_ubuntu
    elif command -v pacman &>/dev/null; then
      install_arch
    elif command -v dnf &>/dev/null; then
      install_fedora
    else
      echo "Unsupported package manager"
      exit 1
    fi
  fi
}

install_ubuntu() {
  apt update
  apt install -y ansible

  # Check if 'op' command is already installed
  if ! command -v op &>/dev/null; then
    # Add the key for the 1Password apt repository
    curl -sS https://downloads.1password.com/linux/keys/1password.asc -o /tmp/1password.asc
    gpg --dearmor --yes --output /usr/share/keyrings/1password-archive-keyring.gpg /tmp/1password.asc

    # Add the 1Password apt repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | tee /etc/apt/sources.list.d/1password.list

    # Add the debsig-verify policy
    mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol -o /etc/debsig/policies/AC2D62742012EA22/1password.pol

    # Import debsig keyring GPG key
    mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    gpg --dearmor --yes --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg /tmp/1password.asc

    # Install 1Password CLI
    apt install -y 1password-cli
  fi
}

install_arch() {
  pacman -Syu ansible

  # Check if 'op' command is already installed
  if ! command -v op &>/dev/null; then
    paru -S 1password-cli
  fi
}

install_fedora() {
  dnf install -y ansible

  # Check if 'op' command is already installed
  if ! command -v op &>/dev/null; then
    # Import the public key
    rpm --import https://downloads.1password.com/linux/keys/1password.asc

    # Configure the repository information
    sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

    # Install 1Password CLI
    dnf check-update -y 1password-cli
    dnf install 1password-cli
  fi
}

case "$os" in
Darwin)
  bootstrap_macos
  ;;
Linux)
  bootstrap_linux
  ;;
*)
  echo "Unsupported OS: $os"
  exit 1
  ;;
esac

# Retrieve ansible-vault password from 1Password
if [ ! -f ".ansible-vault-password" ]; then
  sudo -u $SUDO_USER op read "op://Personal/Ansible/password" -o .ansible-vault-password --force
fi

# Install ansible and ansible-galaxy requirements
sudo -u $SUDO_USER ansible-galaxy install -r requirements.yml
