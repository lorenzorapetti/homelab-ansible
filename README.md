# Homelab Ansible

This repository contains the Ansible playbooks and roles I use to manage my homelab. It's still very much a work in progress because I'm still learning, and oftentimes i don't know what i'm doing.

## Setup

You will need to have the following tools installed on the control machine:

- Ansible
- 1Password CLI

1Password CLI is used to retrieve the Ansible Vault Password and save it to a file called `.ansible-vault-password`.

The script `init.sh` automates the setup process. It will:

- Install Ansible and 1Password CLI based on the OS (the supported OSes are MacOS, Ubuntu, Arch and Fedora)
- Retrieve the Ansible Vault Password from 1Password and save it to a file called `.ansible-vault-password`
- Install the Ansible Galaxy requirements

To run the script, execute the following command:

```bash
./init.sh
```
