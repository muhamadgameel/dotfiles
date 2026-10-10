# Testing notification popup changes

## The constraint

`NotificationPopups.qml` is embedded in the quickshell config and renders on a panel window. An offscreen test cannot:
1. Load the module without panel context
2. Use the real notification service (it claims the session's dbus server)

## Solution: extract the delegate

Lift the popup's delegate (`Item { ... }` inside the `Repeater`) into a standalone QML file that mocks all external dependencies.

### Standalone file structure

```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../components" as Components
import "../../core" as Core
import "../../services" as Services

Item {
  id: wrapper
  property alias model: repeater.model

  function cardAt(index) {
    return repeater.itemAt(index);
  }

  // Mock the window object the delegate references
  Item {
    id: notifWindow
    readonly property int shadowRoom: Math.max(Core.Style.spaceXS, Core.Style.elevationRoom(2))
  }

  // Mock the stack the delegate renders into
  Components.AnimatedColumn {
    id: notificationStack
    fadeIn: false
    spacing: Core.Style.spaceS
    width: Math.round(400 * Core.Style.uiScale) + (notifWindow.shadowRoom - Core.Style.spaceXS) * 2

    Repeater {
      id: repeater
      // Paste the delegate's content here (re-indent if needed; behavior is unchanged)
    }
  }
}
```

### Stub notification service

```qml
pragma Singleton

import QtQuick

Singleton {
  readonly property bool isStub: true
  property var callLog: []

  function invokeAction(id, actionId) {
    callLog.push({ action: 'invokeAction', id, actionId })
    return actionId === "default"
  }
  // ... other methods ...
}
```

## Testing workflow

1. Extract delegate into standalone file with the structure above
2. Create stub service in the same folder  
3. Build a test config that imports the live shell's quickshell config but substitutes the stub service
4. Render offscreen: `QT_QPA_PLATFORM=offscreen qs -p <test-cfg>`
5. Use IPC to click test cards and inspect the call log
6. Create a before/after comparison table of behavior
7. Deploy to live shell and confirm clean reload

## Example: before/after comparison

| Click | Before | After |
|-------|--------|-------|
| Left on body | nothing | run action 'default' |
| Right on body | dismiss | dismiss |
| Action button | run action | run action |
