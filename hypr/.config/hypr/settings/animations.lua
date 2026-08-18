-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║                          ANIMATIONS                               ║
-- ╚═══════════════════════════════════════════════════════════════════╝

hl.config({
	animations = {
		enabled = true,
		workspace_wraparound = false,
	},
})

-- ── Curves ───────────────────────────────────────────────────────────
-- Bezier: points are the two control points, {x1,y1} and {x2,y2}.
-- Visualize at https://cubic-bezier.com
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.30, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("smooth", { type = "bezier", points = { { 0.05, 0.9 }, { 0.10, 1.05 } } })
hl.curve("snappy", { type = "bezier", points = { { 0.40, 0 }, { 0.20, 1 } } })

-- Spring: physical model, no fixed duration. Feels better than a bezier for
-- things that get interrupted mid-flight (opening/moving windows).
hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

-- ── Animation leaves ─────────────────────────────────────────────────
-- speed is in 100ms units; lower = faster.

hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "smooth" })

-- Windows
hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "easy", style = "popin 80%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "easy", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, spring = "easy" })

-- Fades
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "linear" })

-- Borders
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "easeOutQuint" })
-- `borderangle` only does anything for *gradient* borders, and with `loop` it
-- redraws forever. Borders here are solid colors, so it is pure battery cost.
hl.animation({ leaf = "borderangle", enabled = false })

-- Workspaces
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutExpo", style = "slidevert" })

-- Layers (bar, launcher, notifications)
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "easeOutExpo", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "linear", style = "fade" })
