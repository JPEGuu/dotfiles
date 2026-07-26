-- ~/.config/wezterm/wezterm.lua
-- WezTerm configuration matching the repo aesthetic (Kanagawa + Nerd Font).
-- This config uses WezTerm's OWN tabs and panes (no tmux in the GUI).
--
-- Modern Lua API: require 'wezterm' + wezterm.config_builder() + return config.
--   https://wezterm.org/config/lua/config/index.html
--
-- ============================ KEYBINDINGS CHEAT SHEET =========================
--  Leader is CTRL+a (tmux-like), 1s timeout.
--
--  PANES (ALT = no leader needed, fast):
--    ALT + h / j / k / l ............ move focus left/down/up/right (vim-style)
--    ALT + \  (or LEADER + |) ....... split RIGHT  (vertical divider)
--    ALT + -  (or LEADER + -) ....... split DOWN   (horizontal divider)
--    ALT + w  (or LEADER + x) ....... close current pane (asks to confirm)
--    ALT + z  (or LEADER + z) ....... toggle pane zoom (fullscreen the pane)
--
--  TABS (CTRL+SHIFT, the WezTerm default modifier for tabs):
--    CTRL+SHIFT + t ................. new tab
--    CTRL+SHIFT + w ................. close current tab (asks to confirm)
--    CTRL+SHIFT + [ / ] ............. previous / next tab
--    CTRL+SHIFT + 1..9 ............. jump to tab by index (1 = first)
--
--  Note on WezTerm split semantics:
--    SplitHorizontal -> new pane to the RIGHT (panes side by side).
--    SplitVertical   -> new pane BELOW (panes stacked).
--    We bind keys by the *visual* result (\ = side-by-side, - = stacked).
-- =============================================================================

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ------------------------------- Appearance ---------------------------------
-- Kanagawa to match the Neovim colorscheme.
-- IMPORTANT: 'Kanagawa (Gogh)' is a STABLE builtin scheme (Since 20230320).
--   https://wezterm.org/colorschemes/k/index.html
-- NOTE: 'Kanagawa Dragon (Gogh)' exists ONLY in WezTerm *nightly builds*
--   ("Since: Version nightly builds only" per the docs) and will NOT resolve
--   on a stable release. Only swap to it if you run a nightly build.
config.color_scheme = 'Kanagawa (Gogh)'
-- config.color_scheme = 'Kanagawa Dragon (Gogh)' -- nightly-only; do not use on stable

-- JetBrainsMono Nerd Font (matches starship's Nerd Font symbols) with a CJK
-- fallback so Japanese renders without tofu. Fallback list is tried in order.
config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'JetBrains Mono', -- fallback if the Nerd Font patched build is missing
  'Noto Sans CJK JP',
  'Noto Color Emoji',
}
config.font_size = 12.0

-- Subtle transparency. Keep it gentle so text stays readable.
config.window_background_opacity = 0.95

config.window_padding = {
  left = 8,
  right = 8,
  top = 6,
  bottom = 6,
}

-- ------------------------------- Tab bar ------------------------------------
config.enable_tab_bar = true
config.use_fancy_tab_bar = true            -- GUI-styled tab bar (not the retro one)
config.hide_tab_bar_if_only_one_tab = true -- clean look with a single tab
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = true

-- ------------------------------- Behavior -----------------------------------
config.audible_bell = 'Disabled' -- no beep
config.scrollback_lines = 10000
config.window_close_confirmation = 'NeverPrompt'
-- default_prog left unset: WezTerm launches your login shell (zsh) by default.

-- ------------------------------- Keys ---------------------------------------
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  -- ---- Panes: navigation (ALT + hjkl) ----
  { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

  -- ---- Panes: split ----
  -- '\' => side-by-side (new pane on the right)
  { key = '\\', mods = 'ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  -- '-' => stacked (new pane below)
  { key = '-', mods = 'ALT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- ---- Panes: close / zoom ----
  { key = 'w', mods = 'ALT', action = act.CloseCurrentPane { confirm = true } },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },

  -- ---- Tabs (CTRL+SHIFT) ----
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = true } },
  { key = '[', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },
}

-- Tab by index: CTRL+SHIFT+1..9 -> tabs 0..8 (1 = first tab).
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CTRL|SHIFT',
    action = act.ActivateTab(i - 1),
  })
end

return config
