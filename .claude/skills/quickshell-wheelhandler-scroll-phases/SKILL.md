---
name: quickshell-wheelhandler-scroll-phases
category: testing
description: When testing WheelHandler: reset on ScrollEnd, not Begin.
---

When a WheelHandler accumulates state across swipe events (travel, steps, direction), reset that state on `Qt.ScrollEnd`, not on `ScrollBegin`.

A WheelHandler that is not yet active rejects any event with no delta in its orientation (zero delta on the vertical axis for a vertical handler), so it never sees the ScrollBegin event. Once active, it receives all update events up to and including the single ScrollEnd event. A MouseArea, by contrast, receives all events: two Begins, the updates, and two Ends.

Resetting on Begin (common in MouseArea patterns) will carry one swipe's leftover state into the next swipe if the handler was not active at Begin, resulting in a partial step at the wrong swipe boundary.

A vertical wheel handler does not see sideways-only swipes (no vertical delta means rejected if not active). One step per notch is phase 0 (one event); swipe travel is phases 2–3 (updates) then phase 4 (ScrollEnd). The `angleDelta.y` is negative for natural scrolling (fingers towards top = down = volume decrease in today's direction).

See [[quickshell-throwaway-service-rig]] for measuring phases in the rig; probe scripts in the 2026-10-10 episode's scratchpad have full reproduction with early-exit on pointer-left.
