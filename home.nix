{ lib, pkgs, homeDirectory, username, ... }:

let
  postUpdateHook = pkgs.writeTextFile {
    name = "dotfiles-omarchy-post-update-hook";
    executable = true;
    text = ''
      #!/usr/bin/env bash

      set -euo pipefail

      reconciler="$HOME/dotfiles/scripts/reconcile-config-imports"
      if [[ ! -x "$reconciler" ]]; then
        printf 'dotfiles post-update hook: executable not found: %s\n' "$reconciler" >&2
        exit 1
      fi

      exec "$reconciler"
    '';
  };
in {
  home = {
    inherit username homeDirectory;
    stateVersion = "26.05";
    extraActivationPath = [ pkgs.gawk ];
  };

  # Keep this configuration reconciliation-only. In particular, suppress
  # Home Manager's otherwise automatic systemd/XDG marker files so activation
  # does not introduce incidental configuration symlinks.
  systemd.user.enable = false;
  home.file."${homeDirectory}/.cache/.keep".enable = false;
  home.file."${homeDirectory}/.local/state/.keep".enable = false;

  programs.home-manager.enable = true;

  # Omarchy owns Hyprland and the desktop. Home Manager only reconciles the
  # final imports in Omarchy's mutable canonical customization files.
  home.activation.reconcileExternalDotfiles =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      reconciler="$HOME/dotfiles/scripts/reconcile-config-imports"
      if [[ ! -x "$reconciler" ]]; then
        printf 'Home Manager activation: executable not found: %s\n' "$reconciler" >&2
        exit 1
      fi

      run "$reconciler"

      hook_directory="$HOME/.config/omarchy/hooks/post-update.d"
      hook_path="$hook_directory/reconcile-dotfiles.hook"
      run ${pkgs.coreutils}/bin/install -d -m 0755 "$hook_directory"

      if [[ -v DRY_RUN ]]; then
        run ${pkgs.coreutils}/bin/install -m 0755 ${postUpdateHook} "$hook_path"
      else
        (
          hook_temporary=$(${pkgs.coreutils}/bin/mktemp \
            "$hook_directory/.reconcile-dotfiles.hook.XXXXXX")
          trap '${pkgs.coreutils}/bin/rm -f -- "$hook_temporary"' EXIT
          ${pkgs.coreutils}/bin/install -m 0755 ${postUpdateHook} "$hook_temporary"
          ${pkgs.coreutils}/bin/mv -fT -- "$hook_temporary" "$hook_path"
          trap - EXIT
        )
      fi
    '';
}
