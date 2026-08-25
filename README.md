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

## Who can read your repositories

Soft Serve ships with anonymous access set to `read-only` and with keyless connections allowed, and it stores both in its own database rather than in configuration. This role leaves those stored values alone by default, which means that out of the box **anyone who can reach the SSH port can list and clone every repository that has not been made private** — including with `ssh` presenting no key at all. Repositories are not private unless someone makes them so.

That is Soft Serve's own default and it is the right one for a server whose repositories are meant to be public. It is the wrong one for a private git server reachable from the internet, so this role lets you close it:

```yaml
soft_serve_anon_access: no-access
soft_serve_allow_keyless: false
```

Both settings are overrides rather than seeds: while they are set, Soft Serve consults them on every access check and the corresponding `settings anon-access` / `settings allow-keyless` commands stop having any effect. Leave them empty to manage access over SSH instead.

Note that neither affects your own access: the key in `soft_serve_initial_admin_key` is an administrator regardless.

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
