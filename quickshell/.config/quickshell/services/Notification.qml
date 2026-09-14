pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import "../config" as Config
import "../core" as Core
import "../services" as Services

/**
* Notification Service
* Manages notification server, active popups, and history.
*/
Singleton {
  id: root

  // === Configuration ===
  // How many popups are on screen at once.
  property int maxVisible: 5

  property int maxActive: 20

  readonly property int maxHistory: Config.Config.notificationHistoryLimit

  // Duration per urgency level: [low, normal, critical]
  property var urgencyDurations: [3000, 5000, 10000]

  // === State ===
  // The saved setting, or game mode holding popups back. Game mode never writes
  // the setting, so turning it off leaves your own choice exactly as it was.
  readonly property bool doNotDisturb: Config.Config.doNotDisturb || Services.GameMode.active
  property int unreadCount: 0

  // Active notifications with no room on screen. Derived, so the popup stack's
  // counter can never drift out of step with what is actually queued.
  readonly property int hiddenCount: Math.max(0, activeList.count - maxVisible)

  // === Models ===
  property ListModel activeList: ListModel {}
  property ListModel historyList: ListModel {}

  // === Internal ===
  property var _active: ({})  // id -> {notification, watcher, meta}

  // === Notification Server ===
  NotificationServer {
    id: server
    keepOnReload: false
    imageSupported: true
    actionsSupported: true
    onNotification: n => root._handleNotification(n)
  }

  // === Watcher Component ===
  Component {
    id: watcherComponent

    QtObject {
      id: watcher
      required property var notification
      required property string dataId
      required property var service

      property Connections _conn: Connections {
        target: watcher.notification
        function onSummaryChanged() {
          watcher.service._updateFromSource(watcher.dataId);
        }
        function onBodyChanged() {
          watcher.service._updateFromSource(watcher.dataId);
        }
        function onAppNameChanged() {
          watcher.service._updateFromSource(watcher.dataId);
        }
        function onUrgencyChanged() {
          watcher.service._updateFromSource(watcher.dataId);
        }
        function onAppIconChanged() {
          watcher.service._updateFromSource(watcher.dataId);
        }
        function onImageChanged() {
          watcher.service._updateFromSource(watcher.dataId);
        }
        function onActionsChanged() {
          watcher.service._updateFromSource(watcher.dataId);
        }
      }
    }
  }

  // === Progress Timer ===
  Timer {
    interval: 100
    repeat: true
    running: root.activeList.count > 0
    onTriggered: root._updateProgress()
    // A fresh start, so the first tick does not count the time spent idle.
    onRunningChanged: root._lastTick = Date.now()
  }

  property real _lastTick: 0

  // === Signals ===
  signal animateAndRemove(string notificationId)

  // === Public API ===

  function dismiss(id) {
    const entry = _active[id];
    if (!entry)
      return;

    // If notification exists, dismiss it - the closed signal will call _remove()
    // Otherwise, clean up directly (notification may have been closed externally)
    if (entry.notification) {
      entry.notification.dismiss();
    } else {
      _remove(id);
    }
  }

  function invokeAction(id, actionId) {
    const entry = _active[id];
    if (!entry?.notification?.actions)
      return false;

    for (const action of entry.notification.actions) {
      if (action.identifier === actionId) {
        action.invoke();
        return true;
      }
    }
    return false;
  }

  function pauseTimeout(id) {
    const entry = _active[id];
    if (entry && !entry.meta.paused) {
      entry.meta.paused = true;
      entry.meta.pausedAt = Date.now();
    }
  }

  function resumeTimeout(id) {
    const entry = _active[id];
    if (entry && entry.meta.paused) {
      entry.meta.startTime += Date.now() - entry.meta.pausedAt;
      entry.meta.paused = false;
    }
  }

  function removeFromHistory(id) {
    if (Core.Utils.removeFromModel(historyList, "id", id)) {
      unreadCount = Math.max(0, unreadCount - 1);
    }
  }

  function clearHistory() {
    historyList.clear();
    unreadCount = 0;
  }

  function markAllRead() {
    unreadCount = 0;
  }

  // === Internal Handlers ===

  function _handleNotification(n) {
    const data = _createData(n);
    _addToHistory(data);

    if (!doNotDisturb) {
      _addActive(n, data);
    }
  }

  function _createData(n) {
    return Object.assign({
      id: Core.Utils.generateId("notif"),
      expireTimeout: n.expireTimeout,
      timestamp: new Date(),
      progress: 1.0
    }, _content(n));
  }

  // The fields an app can change by updating a notification in place.
  function _content(n) {
    const actions = (n.actions || []).map(a => ({
          text: a.text || "Action",
          identifier: a.identifier || ""
        }));

    return {
      summary: n.summary || "",
      body: Core.Utils.stripTags(n.body || ""),
      appName: Core.Utils.formatAppName(n.appName || n.desktopEntry || ""),
      urgency: (n.urgency >= 0 && n.urgency <= 2) ? n.urgency : 1,
      image: _resolveImage(n),
      actionsJson: JSON.stringify(actions)
    };
  }

  function _resolveImage(n) {
    if (n.image && n.image !== "")
      return n.image;

    // Try to resolve icon from various sources
    const iconSources = [n.appIcon, n.desktopEntry].filter(s => s && s !== "");

    for (const iconName of iconSources) {
      // Try direct icon theme lookup
      let resolved = Quickshell.iconPath(iconName, true);
      if (resolved && resolved !== "") {
        return resolved;
      }
    }

    // Fallback: look up desktop entry by app name to get the correct icon
    const lookupNames = [n.desktopEntry, n.appName, n.appIcon].filter(s => s && s !== "");
    for (const name of lookupNames) {
      const entry = DesktopEntries.heuristicLookup(name);
      if (entry && entry.icon) {
        const resolved = Quickshell.iconPath(entry.icon, true);
        if (resolved && resolved !== "")
          return resolved;
        // No icon on disk for this entry: keep going. An unconditional return
        // here meant only the first candidate name was ever tried.
      }
    }

    return "";
  }

  function _addActive(notification, data) {
    const watcher = watcherComponent.createObject(root, {
      notification: notification,
      dataId: data.id,
      service: root
    });

    const duration = _calculateDuration(data);

    _active[data.id] = {
      notification: notification,
      watcher: watcher,
      meta: {
        startTime: Date.now(),
        duration: duration,
        paused: false,
        pausedAt: 0
      }
    };

    notification.tracked = true;

    // Kept on the entry so _cleanup can disconnect it. An anonymous closure
    // stayed attached to the notification for its entire lifetime.
    const onClosed = () => root._remove(data.id);
    _active[data.id].onClosed = onClosed;
    notification.closed.connect(onClosed);

    activeList.insert(0, data);

    // Only the backstop is enforced here. Everything between maxVisible and
    // maxActive stays in the model and is counted by hiddenCount.
    //
    // The ids are collected first. This used to be `while (count > maxActive)
    // dismiss(last)`, which only terminates because dismiss() shrinks the model
    // synchronously through the closed signal - true today, but the loop would
    // spin forever the day that signal is queued instead.
    const overflow = [];
    for (let i = maxActive; i < activeList.count; i++)
      overflow.push(activeList.get(i).id);
    for (const id of overflow)
      dismiss(id);
  }

  function _calculateDuration(data) {
    if (data.expireTimeout === 0)
      return -1;  // Never expires
    if (data.expireTimeout > 0)
      return data.expireTimeout;
    return urgencyDurations[data.urgency];
  }

  function _updateFromSource(id) {
    const entry = _active[id];
    if (!entry)
      return;

    const n = entry.notification;
    const content = _content(n);

    // The history row is a separate copy of the same data. Updating only the
    // popup left the notification center showing the first version.
    Core.Utils.updateModelItem(activeList, "id", id, content);
    Core.Utils.updateModelItem(historyList, "id", id, content);

    // Update duration if urgency changed
    entry.meta.duration = _calculateDuration({
      urgency: content.urgency,
      expireTimeout: n.expireTimeout
    });
  }

  function _remove(id) {
    if (!_active[id])
      return;
    Core.Utils.removeFromModel(activeList, "id", id);
    _cleanup(id);
  }

  function _cleanup(id) {
    const entry = _active[id];
    if (!entry)
      return;

    if (entry.onClosed && entry.notification) {
      try {
        entry.notification.closed.disconnect(entry.onClosed);
      } catch (e) {
        // Notification already gone - nothing left to disconnect from.
      }
    }

    entry.watcher?.destroy();
    delete _active[id];
  }

  // === Progress ===

  function _updateProgress() {
    const now = Date.now();
    const tick = now - root._lastTick;
    root._lastTick = now;
    const expired = [];

    for (var i = 0; i < activeList.count; i++) {
      const item = activeList.get(i);
      const entry = _active[item.id];
      if (!entry)
        continue;

      const meta = entry.meta;

      // Queued below the visible stack: the clock stands still until the card
      // has a slot, by pushing its start forward by this tick. Without this a
      // burst of eight low-urgency notifications all expired together at 3 s,
      // and the three that were queued only flashed on screen as they went.
      // One pushed down mid-countdown keeps the time it had left.
      if (i >= maxVisible) {
        meta.startTime += tick;
        continue;
      }

      if (meta.duration < 0 || meta.paused || meta.expired)
        continue;

      const elapsed = now - meta.startTime;
      const progress = Math.max(1.0 - elapsed / meta.duration, 0);

      if (progress <= 0) {
        // Collected rather than dispatched here: emitting mutates activeList
        // underneath this loop. Marked so the next ticks, which run while the
        // card animates out, do not send it again.
        meta.expired = true;
        expired.push(item.id);
        continue;
      }

      if (Math.abs(item.progress - progress) > 0.01) {
        activeList.setProperty(i, "progress", progress);
      }
    }

    // Everything that expired this tick goes at once. Dispatching one per tick
    // capped removals at 10/s, so a burst visibly trickled away.
    for (const id of expired) {
      animateAndRemove(id);
    }
  }

  // === History ===

  function _addToHistory(data) {
    historyList.insert(0, data);
    unreadCount++;

    while (historyList.count > maxHistory) {
      historyList.remove(historyList.count - 1);
    }
  }
}
