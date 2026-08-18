-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                            MONITORS                               ║
-- ╚═══════════════════════════════════════════════════════════════════╝
-- Use `hyprctl monitors all` to list available outputs and modes.

-- Fallback for any monitor not matched below.
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

-- Laptop panel: BOE 0x0B8B, 2560x1600 @ 240Hz.
hl.monitor({
	output = "eDP-1",
	mode = "2560x1600@240",
	position = "0x0",
	scale = 1.333333,
})
