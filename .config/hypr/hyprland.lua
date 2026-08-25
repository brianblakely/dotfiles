-- Personal Hyprland overrides.
-- Loaded after Omarchy's defaults by ~/.config/hypr/hyprland.lua.

-- Display.
hl.env("GDK_SCALE", "2")
hl.monitor({
  output = "DP-3",
  mode = "3840x2160@119.91",
  position = "0x0",
  scale = 2,
})

-- Input, appearance, and XWayland.
hl.config({
  input = {
    kb_options = "caps:escape,compose:menu",
  },

  general = {
    gaps_in = 0,
    gaps_out = 0,
    border_size = 0,
  },

  xwayland = {
    force_zero_scaling = true,
  },
})

-- Startup applications.
o.launch_on_start("hyprsunset")
o.exec_on_start("omarchy-toggle-idle stay-awake")

-- Hypridle is no longer part of Omarchy, but keep the custom display-off
-- listener working on machines where it is installed separately.
if o.cmd_present("hypridle") then
  o.launch_on_start([[hypridle -c "$HOME/dotfiles/.config/hypr/hypridle.conf"]])
end

-- Window rules.
o.window("^(steam|steam.*)$", { tile = true })

o.window("^(UnrealEditor)$", {
  no_initial_focus = true,
  no_anim = true,
  suppress_event = "activate",
  tile = true,
})

-- Screenshots.
o.bind("SHIFT + PRINT", "Screenshot to clipboard", [[grim -g "$(slurp)" - | wl-copy]])

-- Plugins.
hl.unbind("SUPER + CTRL + A")
o.bind("SUPER + CTRL + A", "AI usage", "omarchy-shell omarchy.agents toggle")

hl.unbind("SUPER + B")
o.bind("SUPER + B", "Blink", "omarchy-shell b.blink blink")

hl.unbind("SUPER + GRAVE")
o.bind("SUPER + GRAVE", "Peek behind floating windows", "omarchy-shell b.peek toggle")

hl.unbind("SUPER + H")
o.bind("SUPER + H", "OmaHUD", "omarchy-shell shell summon b.omahud")

hl.unbind("PRINT")
o.bind("PRINT", "Omashot", "omarchy-shell b.omashot show")

hl.unbind("SUPER + SLASH")
o.bind("SUPER + SLASH", "Everything", "omarchy-shell shell toggle b.everything")

-- Applications.
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "Files", { tui = "yazi" })

hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music", { webapp = "https://music.amazon.com/", focus = true })

hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Discord", { webapp = "https://discord.com/app", focus = true })

hl.unbind("SUPER + SHIFT + O")
o.bind("SUPER + SHIFT + O", "Notion", { webapp = "https://app.notion.com" })

hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", { webapp = "https://lastpass.com/vault", focus = true })

hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://calendar.google.com/" })

hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://mail.google.com/" })

hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + ALT + E", "Email (Work)", { webapp = "https://mail.google.com/mail/u/1" })

hl.unbind("SUPER + SHIFT + Y")
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/", focus = true })

hl.unbind("SUPER + SHIFT + X")
o.bind("SUPER + SHIFT + X", "Feedly", { webapp = "https://feedly.com/i", focus = true })

hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Omawrite", { launch = "omawrite" })

hl.unbind("XF86Calculator")
o.bind("XF86Calculator", "Omacalc", { launch = "omacalc" })

-- `ln -sfnT "$HOME/Projects/my-current-project" "$HOME/Projects/main"`
hl.unbind("SUPER + code:61")
o.bind("SUPER + code:61", "Main project", { launch = [[xdg-terminal-exec --dir="$HOME/Projects/main"]] })

-- Extra mouse buttons.
hl.unbind("mouse:277")
o.bind("mouse:277", "Show OmaHUD", "omarchy-shell shell summon b.omahud")

hl.unbind("mouse:278")
hl.bind(
  "mouse:278",
  hl.dsp.send_shortcut({
    mods = "CTRL",
    key = "W",
    window = "activewindow",
  }),
  { description = "Fn2: Ctrl+W" }
)

hl.unbind("mouse:279")
hl.bind(
  "mouse:279",
  hl.dsp.send_shortcut({
    mods = "",
    key = "Home",
    window = "activewindow",
  }),
  { description = "Fn3: Home" }
)
