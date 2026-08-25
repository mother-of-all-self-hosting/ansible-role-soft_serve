#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Exercises bin/compute-next-tag.sh against throwaway git repositories.
#
# Usage: bin/test-compute-next-tag.sh
#
# Every scenario creates a repository in a temporary directory, gives it role
# files and a release history, and then replays a series of merges through the real
# script, tagging as it goes just like the autotag workflow does. This repository is
# never touched and no network access is needed.

set -euo pipefail

script_under_test="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/compute-next-tag.sh"

failures=0
workdir=''

cleanup() {
	cd /
	if [ -n "$workdir" ]; then
		rm -rf "$workdir"
		workdir=''
	fi
}

trap cleanup EXIT

# Starts a scenario with a repository at Soft Serve v0.12.2 which has already seen
# two releases of it (v0.12.2-0 and v0.12.2-1), plus `v0-0`, `v0.12-0` and
# `v0.12.2-amd64-0`. Docker Hub publishes floating `v0.12` tags and per-architecture
# `v0.12.2-amd64` ones alongside the real releases, and the commit-message era read
# the version straight out of Renovate's subject line, so tags shaped like that are
# exactly what a regression would produce. None of them may be counted as releases.
#
# The defaults file carries the traps this role's real one has: a commented-out
# example of the version variable, the Renovate annotation that has to keep
# pointing at the leaf literal, and an image tag derived from it whose name ends in
# `_tag` - which the shared Renovate manager's own pattern accepts just as readily
# as `_version`. Neither may be picked up as the version.
scenario() {
	echo "$1"

	cleanup
	workdir="$(mktemp -d)"

	mkdir -p "$workdir/bin" "$workdir/defaults" "$workdir/meta" "$workdir/tasks" "$workdir/templates"
	cp "$script_under_test" "$workdir/bin/"
	cd "$workdir"

	git init -q -b main .
	git config user.email 'test@example.com'
	git config user.name 'Test'
	git config commit.gpgsign false

	cat > defaults/main.yml <<-'YAML'
		# soft_serve_version: v9.9.9
		# renovate: datasource=docker depName=charmcli/soft-serve versioning=semver
		soft_serve_version: v0.12.2
		soft_serve_container_image: "{{ soft_serve_container_image_registry_prefix }}charmcli/soft-serve:{{ soft_serve_container_image_tag }}"
		soft_serve_container_image_tag: "{{ soft_serve_version }}"
	YAML
	printf 'placeholder\n' > meta/main.yml
	printf 'placeholder\n' > tasks/main.yml
	printf 'placeholder\n' > templates/env.j2
	printf 'placeholder\n' > README.md

	git add -A
	git commit -qm 'Initial commit'

	local tag
	for tag in v0-0 v0.12-0 v0.12.2-amd64-0 v0.12.2-0 v0.12.2-1; do
		git tag "$tag"
	done
}

# Applies a change, commits it, and tags whatever the script says it should be.
# Prints the tag, or nothing when the script decided against a release.
merge() {
	local change="$1" tag

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	tag="$(bin/compute-next-tag.sh 2>/dev/null)"

	if [ -n "$tag" ]; then
		git tag "$tag"
	fi

	printf '%s' "$tag"
}

expect() {
	local description="$1" expected="$2" actual="$3"

	if [ "$actual" = "$expected" ]; then
		printf '  ok   | %s -> %s\n' "$description" "${actual:-no release}"
	else
		printf '  FAIL | %s -> expected %s, got %s\n' "$description" "${expected:-no release}" "${actual:-no release}"
		failures=$((failures + 1))
	fi
}

bump_version="sed -i 's|^soft_serve_version: v0.12.2|soft_serve_version: v0.12.3|' defaults/main.yml"
revert_version="sed -i 's|^soft_serve_version: v0.12.3|soft_serve_version: v0.12.2|' defaults/main.yml"
bump_minor="sed -i 's|^soft_serve_version: v0.12.2|soft_serve_version: v0.13.0|' defaults/main.yml"
edit_task="printf 'a task\n' >> tasks/main.yml"
edit_template="printf 'a line\n' >> templates/env.j2"
edit_meta="printf 'a field\n' >> meta/main.yml"
edit_readme="printf 'documentation\n' >> README.md"
edit_script="printf '# a comment\n' >> bin/compute-next-tag.sh"

# The two merge orders below apply the same updates and must each end up with every
# update released exactly once, whichever order they arrive in.

scenario 'A version bump merged before other role changes'
expect 'version bump' v0.12.3-0 "$(merge "$bump_version")"
expect 'task edit'    v0.12.3-1 "$(merge "$edit_task")"
expect 'template'     v0.12.3-2 "$(merge "$edit_template")"

scenario 'A version bump merged after other role changes'
expect 'task edit'    v0.12.2-2 "$(merge "$edit_task")"
expect 'version bump' v0.12.3-0 "$(merge "$bump_version")"

scenario 'A minor bump'
expect 'minor bump' v0.13.0-0 "$(merge "$bump_minor")"

# `v0-0`, `v0.12-0` and `v0.12.2-amd64-0` exist in every scenario. If the version
# were ever read as a bare major, as `major.minor`, or with one of Docker Hub's
# architecture suffixes attached - all of which the registry publishes - the
# counter would continue from those instead of starting afresh.
scenario 'The floating and per-architecture tags that a version misread would land on'
expect 'a task' v0.12.2-2 "$(merge "$edit_task")"

scenario 'Commits that do not affect the role'
expect 'README'   ''          "$(merge "$edit_readme")"
expect 'a script' ''          "$(merge "$edit_script")"
expect 'meta'     v0.12.2-2   "$(merge "$edit_meta")"

scenario 'Release numbers past 9'
for release_number in 2 3 4 5 6 7 8 9 10; do
	git tag "v0.12.2-$release_number"
done
expect 'a task' v0.12.2-11 "$(merge "$edit_task")"

scenario 'Reverting to an already released version'
merge "$bump_version" > /dev/null
# The role is now identical to what v0.12.2-1 already published, so there is
# nothing new to release.
expect 'a revert' '' "$(merge "$revert_version")"

scenario 'Reverting to an already released version, with a change'
merge "$bump_version" > /dev/null
expect 'a revert' v0.12.2-2 "$(merge "$revert_version && $edit_task")"

if [ "$failures" -gt 0 ]; then
	echo >&2 "$failures scenario(s) behaved unexpectedly"
	exit 1
fi

echo 'All scenarios behaved as expected'
