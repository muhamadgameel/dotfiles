pragma Singleton

import QtQuick
import Quickshell

/**
* Utils - helpers that are not tied to any one service
*
* The rule for what belongs here: it takes plain values in and returns plain
* values out, and at least two unrelated places want it.
*/
Singleton {
  id: root

  // === ID Generation ===
  property int _idCounter: 0

  /**
  * A process-unique id, e.g. "notif_1716500000000_7".
  */
  function generateId(prefix) {
    root._idCounter++;
    return (prefix || "id") + "_" + Date.now() + "_" + root._idCounter;
  }

  // === String Utilities ===

  /**
  * Drop HTML-ish markup. Notification bodies arrive with it and Text would
  * otherwise render the tags literally when richText is off.
  */
  function stripTags(text) {
    if (!text)
      return "";
    return text.replace(/<[^>]*>?/gm, '');
  }

  function capitalize(text) {
    if (!text)
      return "";
    return text.charAt(0).toUpperCase() + text.slice(1);
  }

  /**
  * Turn a desktop-entry or bus name into something worth showing a person:
  * "org.mozilla.firefox" becomes "Firefox".
  */
  function formatAppName(name) {
    if (!name || name.trim() === "")
      return "Unknown";
    name = name.trim();

    // Handle flatpak/desktop entry style names (com.foo.Bar, org.app.Name)
    if (name.includes(".") && (name.startsWith("com.") || name.startsWith("org.") || name.startsWith("io."))) {
      const parts = name.split(".");
      let appPart = parts[parts.length - 1];

      // Skip generic endings
      if (!appPart || appPart === "app" || appPart === "desktop") {
        appPart = parts[parts.length - 2] || parts[0];
      }
      if (appPart)
        name = appPart;
    }

    return capitalize(name);
  }

  // === ListModel Utilities ===

  /**
  * Index of the first row whose `property` equals `value`, or -1.
  */
  function findInModel(model, property, value) {
    for (var i = 0; i < model.count; i++) {
      if (model.get(i)[property] === value)
        return i;
    }
    return -1;
  }

  function removeFromModel(model, property, value) {
    const index = findInModel(model, property, value);
    if (index >= 0) {
      model.remove(index);
      return true;
    }
    return false;
  }

  /**
  * @param updates - object of field: value to apply to the matched row.
  */
  function updateModelItem(model, property, value, updates) {
    const index = findInModel(model, property, value);
    if (index < 0)
      return false;
    for (const key in updates) {
      model.setProperty(index, key, updates[key]);
    }
    return true;
  }

  /**
  * Bring a ListModel into step with a list of stable keys, in place.
  *
  * A Repeater given a plain JS array has no identity to diff against, so any
  * change to the array's contents tears down and rebuilds every delegate. For a
  * list a service rebuilds on each poll that means the whole view is destroyed
  * and recreated several times a second - measured at ~32 rebuilds/second in the
  * Bluetooth panel while merely scanning. It shows as flicker, and in a
  * content-sized panel the window resizes with every rebuild.
  *
  * Keyed instead, a delegate is only created or destroyed when the thing it
  * stands for actually arrives or goes. Reorders are done with move() rather than
  * remove+insert, so a list that re-sorts (Wi-Fi networks by signal) keeps its
  * delegates too.
  *
  * @param model - ListModel to update
  * @param keys - keys that should be present, in the order they should appear
  * @param role - role name the key lives under
  */
  function syncKeyedModel(model, keys, role) {
    for (let i = model.count - 1; i >= 0; i--) {
      if (keys.indexOf(model.get(i)[role]) === -1)
        model.remove(i);
    }

    for (let k = 0; k < keys.length; k++) {
      if (k < model.count && model.get(k)[role] === keys[k])
        continue;

      let at = -1;
      for (let i = k; i < model.count; i++) {
        if (model.get(i)[role] === keys[k]) {
          at = i;
          break;
        }
      }

      if (at === -1) {
        const row = {};
        row[role] = keys[k];
        model.insert(Math.min(k, model.count), row);
      } else if (at !== k) {
        model.move(at, k, 1);
      }
    }
  }

  // === JSON Utilities ===

  /**
  * Parse, or return the fallback. Command output is the usual caller, and a
  * process that failed hands back an empty string or a diagnostic.
  */
  function parseJson(jsonString, fallback) {
    try {
      return jsonString ? JSON.parse(jsonString) : (fallback !== undefined ? fallback : []);
    } catch (e) {
      return fallback !== undefined ? fallback : [];
    }
  }

  // === Value Utilities ===

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  // === Size Formatting ===

  /**
  * Human-readable byte count, binary units. formatBytes(1536) is "1.5 KB".
  */
  function formatBytes(bytes, decimals) {
    if (!bytes || bytes < 1)
      return "0 B";
    const k = 1024;
    const dm = decimals !== undefined ? decimals : 1;
    const sizes = ["B", "KB", "MB", "GB", "TB", "PB"];
    const i = Math.min(sizes.length - 1, Math.floor(Math.log(bytes) / Math.log(k)));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
  }

  /**
  * As formatBytes, per second.
  */
  function formatSpeed(bytesPerSecond, decimals) {
    return formatBytes(bytesPerSecond, decimals) + "/s";
  }

  function formatTemp(celsius) {
    return Math.round(celsius) + "°C";
  }

  // === Time Formatting ===

  /**
  * Rough remaining/elapsed time: "2h 15m", or "15 min" spelled out.
  */
  function formatDuration(seconds, shortAnnotation) {
    if (seconds <= 0)
      return "";
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (shortAnnotation) {
      return hours > 0 ? hours + "h " + minutes + "m" : minutes + "m";
    }
    return hours > 0 ? hours + "h " + minutes + "m" : minutes + " min";
  }

  /**
  * Playback-style timestamp: m:ss, or h:mm:ss past an hour.
  */
  function formatClock(seconds) {
    if (!seconds || seconds < 0 || !isFinite(seconds))
      return "0:00";

    const total = Math.floor(seconds);
    const s = total % 60;
    const m = Math.floor(total / 60) % 60;
    const h = Math.floor(total / 3600);

    const ss = s < 10 ? `0${s}` : `${s}`;
    if (h > 0)
      return `${h}:${m < 10 ? "0" + m : m}:${ss}`;
    return `${m}:${ss}`;
  }
}
