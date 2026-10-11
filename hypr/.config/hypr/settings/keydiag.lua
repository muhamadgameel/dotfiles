-- Temporary: logs key timings, never which key, to find the cause of the repeat bursts.
-- Delete with its require in hyprland.lua.
local LOG = os.getenv("HOME") .. "/.cache/hypr-keydiag.log"

-- Held on purpose: BackSpace Tab Return Ctrl Shift Alt Space Caps arrows Delete Super.
local HELD_OK = {}
for _, code in ipairs({ 22, 23, 36, 37, 50, 62, 64, 65, 66, 105, 108, 111, 113, 114, 116, 119, 133, 134 }) do
	HELD_OK[code] = true
end

local down, idle_before = {}, {}
local offset, first_event, last_event, last_press, last_release, last_tick

-- ponytail: /proc/uptime is 10 ms coarse, and the event time wraps after 49 days of uptime
local function now_ms()
	local f = io.open("/proc/uptime")
	if not f then
		return 0
	end
	local seconds = f:read("n")
	f:close()
	return math.floor(seconds * 1000)
end

local function log(fmt, ...)
	local f = io.open(LOG, "a")
	if not f then
		return
	end
	f:write(os.date("%F %T "), fmt:format(...), "\n")
	f:close()
end

hl.on("input.keyboard.key", function(code, time, state)
	local lag = now_ms() - time
	-- The two clocks differ by a constant; the smallest difference seen is that constant.
	if not offset or lag < offset or lag - offset > 60000 then
		offset = lag
	end
	lag = lag - offset
	if lag >= 50 then
		log("LAG %d ms: the compositor read a key event late", lag)
	end
	first_event = first_event or time

	if state == 1 then
		if last_release and time - last_release <= 2 then
			log("  ^ LOST-RELEASE: the next press came %d ms after that release, in the same report", time - last_release)
		end
		last_release = nil
		if down[code] then
			log("DOUBLE-PRESS: key already down for %d ms (a second device, or a lost release)", time - down[code])
		end
		for other, pressed in pairs(down) do
			if other ~= code and not HELD_OK[other] and time - pressed > 10000 then
				log("STALE: a key has been down %d s with no release", (time - pressed) // 1000)
				down[other] = nil
			end
		end
		down[code], idle_before[code], last_press = time, last_event and (time - last_event) or -1, time
	else
		local pressed = down[code]
		down[code] = nil
		if not pressed then
			-- A key held across a config reload releases without a press.
			if time - first_event > 2000 then
				log("RELEASE-WITHOUT-PRESS")
			end
		elseif time - pressed >= 250 and not HELD_OK[code] then
			log("LONG-HOLD %d ms (idle before the press %d ms, lag %d ms)", time - pressed, idle_before[code], lag)
			if last_press ~= pressed and time - last_press <= 2 then
				log("  ^ LOST-RELEASE: released in the same report as the next press")
			else
				last_release = time
			end
		end
	end
	last_event = time
end)

hl.timer(function()
	local now = now_ms()
	if last_tick and now - last_tick >= 250 then
		log("LOOP-GAP %d ms: the main loop stalled", now - last_tick)
	end
	last_tick = now
end, { timeout = 100, type = "repeat" })

hl.bind("SUPER + F2", function()
	log("MARK: a burst just happened")
end, { description = "Mark a keyboard burst in the diagnostic log" })

log("START")
