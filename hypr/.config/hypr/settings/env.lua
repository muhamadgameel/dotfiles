-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                    ENVIRONMENT VARIABLES                          ║
-- ╚═══════════════════════════════════════════════════════════════════╝
-- This session runs under uwsm (DESKTOP_SESSION=hyprland-uwsm).
--
-- Variables set here only reach processes Hyprland spawns itself -- EXCEPT
-- the ones uwsm explicitly re-exports into the systemd/D-Bus activation
-- environment, listed in $UWSM_FINALIZE_VARNAMES:
--
--     HYPRLAND_INSTANCE_SIGNATURE HYPRLAND_CMD
--     HYPRCURSOR_THEME HYPRCURSOR_SIZE XCURSOR_SIZE XCURSOR_THEME
--
-- So cursor vars belong here. Everything else (Qt/GTK/SDL/Electron toolkit
-- hints) lives in ~/.config/uwsm/env, which uwsm sources before starting the
-- compositor -- otherwise portal- and D-Bus-activated apps never see them.
-- See the `uwsm` stow package in this repo.

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adwaita")
