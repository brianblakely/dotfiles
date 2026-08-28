# Dotfiles

## First setup

1. Clone this repository to the required location:

   ```bash
   git clone git@github.com:brianblakely/dotfiles.git "$HOME/dotfiles"
   cd "$HOME/dotfiles"
   ```

2. If `nix` is unavailable, install it and open a new shell:

   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

3. Initialize as your regular user:

   ```bash
   "$HOME/dotfiles/init.sh"
   ```

4. Apply the system override:

   ```bash
   sudo install -D -m 0644 \
     "$HOME/dotfiles/etc/systemd/system/systemd-poweroff.service.d/override.conf" \
     /etc/systemd/system/systemd-poweroff.service.d/override.conf
   sudo systemctl daemon-reload
   ```

## Apply changes

After editing the repository, run:

```bash
"$HOME/dotfiles/scripts/home-manager-switch"
```

This reconciles the dotfiles and installs missing applications through
Omarchy.

## Check

```bash
tests/reconcile-config-imports.test.sh
nix --extra-experimental-features 'nix-command flakes' \
  flake check --impure "path:$PWD"
```
