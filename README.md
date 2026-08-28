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

3. Restore the private Syncthing settings outside Git:

   ```bash
   install -d -m 0700 "$HOME/.config/dotfiles"
   install -m 0600 /path/to/syncthing.json \
     "$HOME/.config/dotfiles/syncthing.json"
   ```

4. Initialize as your regular user:

   ```bash
   "$HOME/dotfiles/init.sh"
   ```

5. Apply the system override:

   ```bash
   sudo install -D -m 0644 \
     "$HOME/dotfiles/etc/systemd/system/systemd-poweroff.service.d/override.conf" \
     /etc/systemd/system/systemd-poweroff.service.d/override.conf
   sudo systemctl daemon-reload
   ```

## Syncthing settings

`~/.config/dotfiles/syncthing.json` contains remote peers and folders:

```json
{
  "devices": [
    {
      "deviceID": "<remote Syncthing device ID>",
      "name": "remote-device",
      "addresses": ["dynamic"],
      "compression": "metadata",
      "paused": false
    }
  ],
  "folders": [
    {
      "id": "folder-id",
      "label": "Folder label",
      "path": "~/path/to/folder",
      "type": "sendreceive",
      "devices": [
        { "deviceId": "<remote Syncthing device ID>" }
      ],
      "paused": false,
      "rescanIntervalS": 3600,
      "fsWatcherEnabled": true,
      "fsWatcherDelayS": 10
    }
  ],
  "options": {
    "urAccepted": -1
  }
}
```

Add one device entry per remote peer and reference its ID from each shared
folder. Do not add the local device; Home Manager inserts it automatically.
The `deviceID`/`deviceId` capitalization is intentional.

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
