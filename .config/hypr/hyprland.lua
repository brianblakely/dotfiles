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
    kb_options = "compose:menu",
  }
})

-- Window rules.
o.window("steam", { tile = true })

-- System.
hl.unbind("SUPER + CTRL + A")
o.bind("SUPER + CTRL + A", "AI usage", "omarchy-shell omarchy.agents toggle")

-- Plugins.
o.bind("SUPER + B", "Blink", "omarchy-shell b.blink blink")
o.bind("SUPER + GRAVE", "Peek behind floating windows", "omarchy-shell b.peek toggle")
o.bind("SUPER + H", "OmaHUD", "omarchy-shell shell summon b.omahud")
hl.unbind("PRINT")
o.bind("PRINT", "Omashot", "omarchy-shell b.omashot show")
hl.unbind("SUPER + SLASH")
o.bind("SUPER + SLASH", "Everything", "omarchy-shell shell toggle b.everything")

-- Applications.
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "Files", { tui = "yazi" })
o.bind("SUPER + SHIFT + ALT + F", "File manager", { omarchy = "nautilus" })
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music", { webapp = "https://music.amazon.com/", focus = true })
hl.unbind("SUPER + SHIFT + Y")
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/", focus = true })
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
hl.unbind("SUPER + SHIFT + X")
o.bind("SUPER + SHIFT + X", "Feedly", { webapp = "https://feedly.com/i", focus = true })

-- Extra mouse buttons.
o.bind("mouse:277", "Show OmaHUD", "omarchy-shell shell summon b.omahud")
hl.bind(
  "mouse:278",
  hl.dsp.send_shortcut({
    mods = "CTRL",
    key = "W",
    window = "activewindow",
  }),
  { description = "Ctrl+W" }
)
hl.bind(
  "mouse:279",
  hl.dsp.send_shortcut({
    mods = "",
    key = "Home",
    window = "activewindow",
  }),
  { description = "Home" }
)
