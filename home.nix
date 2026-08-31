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
      package = "keyd";
      command = [ "pkg" "add" "keyd" ];
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

  reconcileSyncthing = pkgs.writeShellApplication {
    name = "reconcile-syncthing";
    runtimeInputs = with pkgs; [ coreutils curl jq libxml2 xmlstarlet ];
    text = ''
      set -euo pipefail
      umask 0077

      syncthing_command="''${DOTFILES_SYNCTHING_COMMAND:-/usr/bin/syncthing}"
      syncthing_home="''${DOTFILES_SYNCTHING_HOME:-''${XDG_STATE_HOME:-$HOME/.local/state}/syncthing}"
      settings_file="''${DOTFILES_SYNCTHING_SETTINGS:-$HOME/.config/dotfiles/syncthing.json}"

      if [[ ! -x "$syncthing_command" ]]; then
        printf 'Syncthing reconciler: executable not found: %s\n' \
          "$syncthing_command" >&2
        exit 1
      fi
      if [[ ! -r "$settings_file" ]]; then
        printf 'Syncthing reconciler: settings not readable: %s\n' \
          "$settings_file" >&2
        exit 1
      fi

      install -d -m 0700 "$syncthing_home"
      config_path="$syncthing_home/config.xml"
      if [[ ! -f "$config_path" ]]; then
        "$syncthing_command" -H "$syncthing_home" generate \
          --no-port-probing >/dev/null
      fi

      api_key=$(xmllint --xpath 'string(/configuration/gui/apikey)' \
        "$config_path")
      if [[ -z "$api_key" ]]; then
        printf 'Syncthing reconciler: API key missing from %s\n' \
          "$config_path" >&2
        exit 1
      fi

      runtime_parent="''${XDG_RUNTIME_DIR:-/tmp}"
      runtime_directory=$(mktemp -d \
        "$runtime_parent/home-manager-syncthing.XXXXXX")
      headers_file="$runtime_directory/headers"
      socket_path="$runtime_directory/api.sock"
      log_file="$runtime_directory/syncthing.log"
      temporary_pid=""
      temporary_config_directory=""
      config_replacement=""

      cleanup() {
        if [[ -n "$temporary_pid" ]] && kill -0 "$temporary_pid" 2>/dev/null; then
          kill "$temporary_pid" 2>/dev/null || true
          wait "$temporary_pid" 2>/dev/null || true
        fi
        if [[ -n "$config_replacement" ]]; then
          rm -f -- "$config_replacement"
        fi
        rm -rf -- "$runtime_directory"
      }
      trap cleanup EXIT

      printf 'X-API-Key: %s\n' "$api_key" >"$headers_file"

      declare -a api_address_args=()
      api_base=""
      api_curl() {
        curl --silent --show-error --fail-with-body \
          --header "@$headers_file" "''${api_address_args[@]}" "$@"
      }

      gui_address=$(xmllint --xpath 'string(/configuration/gui/address)' \
        "$config_path")
      gui_tls=$(xmllint --xpath 'string(/configuration/gui/@tls)' \
        "$config_path")
      gui_scheme=http
      if [[ "$gui_tls" == true ]]; then
        gui_scheme=https
        api_address_args+=(--insecure)
      fi
      api_base="$gui_scheme://$gui_address"

      temporary_started=false
      declare -a original_listen_addresses=()
      original_global_announce_enabled=""
      original_local_announce_enabled=""
      original_relays_enabled=""
      original_nat_enabled=""
      if ! api_curl "$api_base/rest/system/status" >/dev/null 2>&1; then
        temporary_started=true
        api_address_args=(--unix-socket "$socket_path")
        api_base=http://localhost

        temporary_config_directory="$runtime_directory/config"
        install -d -m 0700 "$temporary_config_directory"
        install -m 0600 "$config_path" \
          "$temporary_config_directory/config.xml"
        install -m 0600 "$syncthing_home/cert.pem" \
          "$temporary_config_directory/cert.pem"
        install -m 0600 "$syncthing_home/key.pem" \
          "$temporary_config_directory/key.pem"

        mapfile -t original_listen_addresses < <(
          xmlstarlet sel -t -m '/configuration/options/listenAddress' \
            -v . -n "$config_path"
        )
        original_global_announce_enabled=$(xmlstarlet sel -t \
          -v 'string(/configuration/options/globalAnnounceEnabled)' \
          "$config_path")
        original_local_announce_enabled=$(xmlstarlet sel -t \
          -v 'string(/configuration/options/localAnnounceEnabled)' \
          "$config_path")
        original_relays_enabled=$(xmlstarlet sel -t \
          -v 'string(/configuration/options/relaysEnabled)' \
          "$config_path")
        original_nat_enabled=$(xmlstarlet sel -t \
          -v 'string(/configuration/options/natEnabled)' \
          "$config_path")

        xmlstarlet ed --inplace \
          -d '/configuration/options/listenAddress' \
          -s '/configuration/options' -t elem -n listenAddress \
            -v 'tcp://127.0.0.1:0' \
          -u '/configuration/options/globalAnnounceEnabled' -v false \
          -u '/configuration/options/localAnnounceEnabled' -v false \
          -u '/configuration/options/relaysEnabled' -v false \
          -u '/configuration/options/natEnabled' -v false \
          -u '/configuration/options/urAccepted' -v -1 \
          -u '/configuration/gui/@tls' -v false \
          "$temporary_config_directory/config.xml"

        "$syncthing_command" -C "$temporary_config_directory" \
          -D "$syncthing_home" serve \
          --paused --no-browser --no-restart --no-upgrade \
          --gui-address="unix://$socket_path" >"$log_file" 2>&1 &
        temporary_pid=$!

        ready=false
        for ((attempt = 0; attempt < 100; attempt++)); do
          if api_curl "$api_base/rest/system/status" >/dev/null 2>&1; then
            ready=true
            break
          fi
          if ! kill -0 "$temporary_pid" 2>/dev/null; then
            break
          fi
          sleep 0.1
        done

        if [[ "$ready" != true ]]; then
          printf 'Syncthing reconciler: temporary instance failed to start\n' >&2
          sed -n '1,120p' "$log_file" >&2
          exit 1
        fi
      fi

      local_device_id=$("$syncthing_command" -H "$syncthing_home" device-id)
      current_config=$(api_curl "$api_base/rest/config")
      printf '%s\n' "$current_config" |
        jq --arg local_device_id "$local_device_id" \
          --slurpfile desired "$settings_file" '
            ($desired[0]) as $wanted
            | .devices = (
                [.devices[] | select(.deviceID == $local_device_id)]
                + $wanted.devices
              )
            | .folders = (
                $wanted.folders
                | map(
                    .devices = (
                      [{ deviceId: $local_device_id }] + .devices
                    )
                  )
              )
            | .options.urAccepted = $wanted.options.urAccepted
          ' |
        api_curl -X PUT --json @- "$api_base/rest/config" >/dev/null

      restart_required=$(api_curl \
        "$api_base/rest/config/restart-required" | jq -r '.requiresRestart')
      if [[ "$temporary_started" == false && "$restart_required" == true ]]; then
        api_curl -X POST "$api_base/rest/system/restart" >/dev/null
      fi

      if [[ "$temporary_started" == true ]]; then
        api_curl -X POST "$api_base/rest/system/shutdown" >/dev/null || true
        wait "$temporary_pid" 2>/dev/null || true
        temporary_pid=""

        xmlstarlet ed --inplace \
          -d '/configuration/options/listenAddress' \
          -u '/configuration/options/globalAnnounceEnabled' \
            -v "$original_global_announce_enabled" \
          -u '/configuration/options/localAnnounceEnabled' \
            -v "$original_local_announce_enabled" \
          -u '/configuration/options/relaysEnabled' \
            -v "$original_relays_enabled" \
          -u '/configuration/options/natEnabled' \
            -v "$original_nat_enabled" \
          -u '/configuration/gui/@tls' -v "$gui_tls" \
          "$temporary_config_directory/config.xml"
        for listen_address in "''${original_listen_addresses[@]}"; do
          xmlstarlet ed --inplace \
            -s '/configuration/options' -t elem -n listenAddress \
              -v "$listen_address" \
            "$temporary_config_directory/config.xml"
        done

        config_replacement=$(mktemp \
          "$syncthing_home/.config.xml.home-manager.XXXXXX")
        install -m 0600 "$temporary_config_directory/config.xml" \
          "$config_replacement"
        mv -fT -- "$config_replacement" "$config_path"
        config_replacement=""
      fi

      echo 'Syncthing configuration reconciled.'
    '';
  };

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

  # Install applications through Omarchy's native package managers and let it
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

  # Reconcile Syncthing through its REST API while retaining the Arch package,
  # local device keys, and current systemd enablement state.
  home.activation.configureSyncthing =
    lib.hm.dag.entryAfter [ "installOmarchyApplications" ] ''
      run ${reconcileSyncthing}/bin/reconcile-syncthing
    '';
}
