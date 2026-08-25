<!--
SPDX-FileCopyrightText: 2023 Nikita Chernyi
SPDX-FileCopyrightText: 2026 Slavi Pantaleev
SPDX-FileCopyrightText: 2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Soft Serve Ansible role

This is an [Ansible](https://www.ansible.com/) role which installs [Soft Serve](https://github.com/charmbracelet/soft-serve) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

This role *implicitly* depends on:

- [`com.devture.ansible.role.playbook_help`](https://github.com/devture/com.devture.ansible.role.playbook_help)
- [`com.devture.ansible.role.systemd_docker_base`](https://github.com/devture/com.devture.ansible.role.systemd_docker_base)
- (optional) [`com.devture.ansible.role.playbook_runtime_messages`](https://github.com/devture/com.devture.ansible.role.playbook_runtime_messages)

Check [`defaults/main.yml`](defaults/main.yml) for the full list of supported options.

💡 For an Ansible playbook which integrates this role and makes it easier to use, see the [Mother-of-All-Self-Hosting Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

## Clone URLs

Soft Serve advertises a single clone URL to its users: it prints it when a repository is created (`ssh -p … <hostname> repo create …`) and builds the clone command shown in its SSH interface out of it. That URL is `soft_serve_ssh_public_url`, which this role derives from `soft_serve_hostname` and `soft_serve_container_bind_port`.

Override it when the SSH port is reached at some other address than the one the container publishes — through a load balancer or a port forwarding, say. Getting it wrong breaks nothing: cloning from the real address keeps working. It only means the URL Soft Serve shows people is not one they can use.

## Development

### pre-commit

You can optionally install a Git pre-commit hook (via [mise](https://mise.jdx.dev/) + [prek](https://prek.j178.dev/)) that runs formatting and linting checks before each commit. See [`.pre-commit-config.yaml`](./.pre-commit-config.yaml) for which hooks are to be executed.

To install the hook, run the [`just`](https://github.com/casey/just) command below:

```sh
just prek-install-git-pre-commit-hook
```

### Molecule

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

Refer to [this page](./molecule/README.md) for details about how to utilize it.
