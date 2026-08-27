# Dotfiles on Omarchy

This repository uses standalone Home Manager as a user-environment and
reconciliation layer on top of Omarchy. Omarchy still owns Hyprland and the
desktop packages; this flake does not enable or install a Nix-managed
Hyprland.

## Fresh-machine setup

1. Clone this repository to exactly `$HOME/dotfiles`.
2. If Nix is missing, use the official multi-user installer:

   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

   Start a new shell after it finishes. Do not run the remaining setup as
   root.

   If the Arch `nix` package is already installed but its store is not yet
   available, initialize the packaged multi-user daemon instead:

   ```bash
   sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/nix-daemon.conf
   sudo systemctl enable --now nix-daemon.service
   nix --extra-experimental-features 'nix-command flakes' store info
   ```
3. Run the non-root setup:

   ```bash
   "$HOME/dotfiles/firstrun/index.sh"
   ```

   This bootstraps standalone Home Manager when needed, switches to the
   repository's pinned configuration, then runs the Omarchy application
   installers. The installers skip applications that are already present.
4. Review and apply the root-owned system configuration separately:

   ```bash
   sudo install -D -m 0644 \
     "$HOME/dotfiles/etc/systemd/system/systemd-poweroff.service.d/override.conf" \
     /etc/systemd/system/systemd-poweroff.service.d/override.conf
   sudo systemctl daemon-reload
   ```

For later switches, run:

```bash
"$HOME/dotfiles/scripts/home-manager-switch"
```

The flake derives the user and home directory from the invoking environment so
it does not hardcode a username. That makes evaluation intentionally impure;
the wrapper supplies `--impure` and enables `nix-command` and `flakes` for Nix
installations that do not enable them globally. The equivalent direct command
on this machine is:

```bash
NIX_CONFIG='extra-experimental-features = nix-command flakes' \
  home-manager switch --impure --flake "path:$HOME/dotfiles#default"
```

## External configuration reconciliation

Home Manager does not take ownership of Omarchy's canonical files. Activation
runs `scripts/reconcile-config-imports` after `writeBoundary`; the script
preserves unrelated content and atomically moves one marked import block to the
end of each ordinary canonical file:

| Canonical file | Repository source |
| --- | --- |
| `~/.config/hypr/hyprland.lua` | `~/dotfiles/.config/hypr/hyprland.lua` |
| `~/.config/hypr/hyprsunset.conf` | `~/dotfiles/.config/hypr/hyprsunset.conf` |
| `~/.inputrc` | `~/dotfiles/.inputrc` |
| `~/.bashrc` | `~/dotfiles/.bashrc` |

Activation also installs a regular executable at
`~/.config/omarchy/hooks/post-update.d/reconcile-dotfiles.hook`. Omarchy runs
that hook after updates, so a replaced or migrated canonical file gets only
the final managed import restored; the rest of Omarchy's new file remains
untouched.

The repository's `.codex/config.toml` is intentionally not copied over
`~/.codex/config.toml`. Codex supports user, project, profile, command-line,
and system configuration layers, but no general TOML include/import. In a
trusted checkout, this repository file acts as project-scoped configuration;
the mutable user configuration remains authoritative for user state. See the
[Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).

## Validation

```bash
tests/reconcile-config-imports.test.sh
nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure "path:$PWD"
nix --extra-experimental-features 'nix-command flakes' \
  build --impure --no-link \
  "path:$PWD#homeConfigurations.default.activationPackage"
```
