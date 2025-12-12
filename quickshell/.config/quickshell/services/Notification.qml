pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import "../core" as Core

/**
* Notification Service
* Manages notification server, active popups, and history.
*/
Singleton {
  id: root

  // === Configuration ===
  property int maxVisible: 5
  property int maxHistory: 100

  // Duration per urgency level: [low, normal, critical]
  property var urgencyDurations: [3000, 5000, 10000]

  // === State ===
  property bool doNotDisturb: false
  property int unreadCount: 0

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
  }

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

  // === Internal Handlers ===

  function _handleNotification(n) {
    const data = _createData(n);
    _addToHistory(data);

    if (!doNotDisturb) {
      _addActive(n, data);
    }
  }

  function _createData(n) {
    const urgency = (n.urgency >= 0 && n.urgency <= 2) ? n.urgency : 1;
    const actions = (n.actions || []).map(a => ({
          text: a.text || "Action",
          identifier: a.identifier || ""
        }));

    return {
      id: Core.Utils.generateId("notif"),
      summary: n.summary || "",
      body: Core.Utils.stripTags(n.body || ""),
      appName: Core.Utils.formatAppName(n.appName || n.desktopEntry || ""),
      urgency: urgency,
      expireTimeout: n.expireTimeout,
      timestamp: new Date(),
      progress: 1.0,
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
        let resolved = Quickshell.iconPath(entry.icon, true);
        if (resolved && resolved !== "") {
          return resolved;
        }
        return resolved;
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
    notification.closed.connect(() => _remove(data.id));

    activeList.insert(0, data);

    // Enforce max visible - dismiss oldest notifications
    while (activeList.count > maxVisible) {
      const last = activeList.get(activeList.count - 1);
      dismiss(last.id);  // closed signal handles _remove() and cleanup
    }
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
    const urgency = (n.urgency >= 0 && n.urgency <= 2) ? n.urgency : 1;
    const actions = (n.actions || []).map(a => ({
          text: a.text || "Action",
          identifier: a.identifier || ""
        }));

    Core.Utils.updateModelItem(activeList, "id", id, {
      summary: n.summary || "",
      body: Core.Utils.stripTags(n.body || ""),
      appName: Core.Utils.formatAppName(n.appName || n.desktopEntry || ""),
      urgency: urgency,
      image: _resolveImage(n),
      actionsJson: JSON.stringify(actions)
    });

    // Update duration if urgency changed
    entry.meta.duration = _calculateDuration({
      urgency: urgency,
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
    if (entry) {
      entry.watcher?.destroy();
      delete _active[id];
    }
  }

  // === Progress ===

  function _updateProgress() {
    const now = Date.now();

    for (var i = 0; i < activeList.count; i++) {
      const item = activeList.get(i);
      const entry = _active[item.id];
      if (!entry)
        continue;

      const meta = entry.meta;
      if (meta.duration < 0 || meta.paused)
        continue;

      const elapsed = now - meta.startTime;
      const progress = Math.max(1.0 - elapsed / meta.duration, 0);

      if (progress <= 0) {
        animateAndRemove(item.id);
        return;  // Process one removal per tick
      }

      if (Math.abs(item.progress - progress) > 0.01) {
        activeList.setProperty(i, "progress", progress);
      }
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
