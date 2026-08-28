{ lib, pkgs, homeDirectory, username, ... }:

let
  omarchyApplications = [
    {
      package = "yazi";
      command = [ "pkg" "add" "yazi" ];
    }
    {
      package = "resvg";
      command = [ "pkg" "add" "resvg" ];
    }
    {
      package = "syncthing";
      command = [ "pkg" "add" "syncthing" ];
    }
    {
      package = "brave-bin";
      command = [ "install" "browser" "brave" ];
    }
    {
      package = "steam";
      command = [ "install" "gaming" "steam" ];
    }
  ];

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

  # Suppress Home Manager's otherwise automatic systemd/XDG marker files so
  # activation does not introduce incidental configuration symlinks.
  systemd.user.enable = false;
  home.file."${homeDirectory}/.cache/.keep".enable = false;
  home.file."${homeDirectory}/.local/state/.keep".enable = false;

  programs.home-manager.enable = true;

  # Omarchy owns Hyprland and the desktop. Home Manager reconciles the final
  # imports in Omarchy's mutable canonical customization files.
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

  # Keep applications in Omarchy's native package managers and let Omarchy
  # perform any app-specific setup. Checking first also avoids repeat installer
  # side effects, such as launching Steam after installation.
  home.activation.installOmarchyApplications =
    lib.hm.dag.entryAfter [ "reconcileExternalDotfiles" ] ''
      omarchy_path="/usr/share/omarchy/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:$PATH"
      omarchy_command=$(PATH="$omarchy_path" command -v omarchy || true)
      if [[ -z "$omarchy_command" ]]; then
        printf 'Home Manager activation: omarchy command not found\n' >&2
        exit 1
      fi

      install_omarchy_application() {
        local package="$1"
        shift

        if ${pkgs.coreutils}/bin/env PATH="$omarchy_path" \
          "$omarchy_command" pkg present "$package"; then
          echo "$package is already installed, skipping..."
        else
          run ${pkgs.coreutils}/bin/env PATH="$omarchy_path" \
            "$omarchy_command" "$@"
        fi
      }

      install_omarchy_flatpak_application() {
        local flatpak_id="$1"
        shift

        if ${pkgs.coreutils}/bin/env PATH="$omarchy_path" \
          flatpak info --user "$flatpak_id" >/dev/null 2>&1 ||
          ${pkgs.coreutils}/bin/env PATH="$omarchy_path" \
            flatpak info --system "$flatpak_id" >/dev/null 2>&1; then
          echo "$flatpak_id is already installed, skipping..."
        else
          run ${pkgs.coreutils}/bin/env PATH="$omarchy_path" \
            "$omarchy_command" "$@"
        fi
      }

      ${lib.concatMapStringsSep "\n" (application:
        "install_omarchy_application "
        + lib.escapeShellArgs ([ application.package ] ++ application.command)
      ) omarchyApplications}

      install_omarchy_flatpak_application com.nvidia.geforcenow \
        install gaming geforce-now

      # This helper is internally idempotent and only adds missing flags.
      run ${pkgs.coreutils}/bin/env PATH="$omarchy_path" \
        "$omarchy_command" install chromium google account
    '';
}
