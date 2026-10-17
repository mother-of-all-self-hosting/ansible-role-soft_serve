<!--
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2020-2024 MDAD project contributors
SPDX-FileCopyrightText: 2020-2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Nikita Chernyi
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up Soft Serve

This is an [Ansible](https://www.ansible.com/) role which installs [Soft Serve](https://github.com/charmbracelet/soft-serve) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Soft Serve is a self-hostable [Git](https://git-scm.com/) server for the command line.

See the project's [documentation](https://github.com/charmbracelet/soft-serve/blob/main/README.md) to learn what Soft Serve does and why it might be useful to you.

## Adjusting the playbook configuration

To enable Soft Serve with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# soft_serve                                                           #
#                                                                      #
########################################################################

soft_serve_enabled: true

########################################################################
#                                                                      #
# /soft_serve                                                          #
#                                                                      #
########################################################################
```

### Set the hostname

To enable Soft Serve you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
soft_serve_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

**Note**: hosting Soft Serve under a subpath (by configuring the `soft_serve_path_prefix` variable) does not seem to be possible due to Soft Serve's technical limitations.

### Configure SSH port

It is also necessary to specify SSH port by adding the following configuration to your `vars.yml` file:

```yaml
soft_serve_container_bind_port: 2222
```

>[!NOTE]
> For Git servers the usual Git-over-SSH port is 22.

### Set initial administrator's key

You also need to set an initial administrator's key by adding the following configuration to your `vars.yml` file:

```yaml
soft_serve_environment_variables_soft_serve_initial_admin_keys: YOUR_PUBLIC_SSH_KEY_HERE
```

Replace `YOUR_PUBLIC_SSH_KEY_HERE` with your own value.

>[!WARNING]
> This key will be able to authenticate with ANY user until Soft Serve is configured.

### Adjusting clone URLs (optional)

Soft Serve advertises a single clone URL to its users: it prints it when a repository is created (`ssh -p … <hostname> repo create …`) and builds the clone command shown in its SSH interface out of it. That URL is `soft_serve_environment_variables_soft_serve_ssh_public_url`, and you need to override it when the SSH port is reached at some other address than the one the container publishes.

### Disabling anonymous access for a private Git server (optional)

Soft Serve ships with anonymous access set to `read-only` and with keyless connections allowed, and it stores both in its own database rather than in configuration. This role leaves those stored values alone by default, which means that **anyone who can reach the SSH port can list and clone every repository that has not been made private**.

To avoid it for a private Git server, add the following configuration to your `vars.yml` file:

```yaml
soft_serve_environment_variables_soft_serve_anon_access: no-access
soft_serve_environment_variables_soft_serve_allow_keyless: false
```

Note that neither affects your own access: the key in `soft_serve_environment_variables_soft_serve_initial_admin_keys` is an administrator regardless.

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `soft_serve_environment_variables_additional_variables` variable

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, Soft Serve becomes available at the specified hostname.

You can run a command `ssh example@example.com -p 2222` with the SSH key defined in `soft_serve_environment_variables_soft_serve_initial_admin_keys` to see its [TUI](https://en.wikipedia.org/wiki/Text-based_user_interface) and follow the instructions to configure Soft Serve further.

Note that you have to [finish the configuration yourself](https://github.com/charmbracelet/soft-serve#configuration). **Otherwise any user with the SSK key specified with `soft_serve_environment_variables_soft_serve_initial_admin_keys` will be able to log in as an administrator.**

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu soft-serve` (or how you/your playbook named the service, e.g. `mash-soft-serve`).
