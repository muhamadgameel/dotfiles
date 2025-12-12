pragma Singleton

import QtQuick
import Quickshell

/**
* Utils - Generic utility functions for the shell
*/
Singleton {
  id: root

  // === ID Generation ===
  property int _idCounter: 0

  function generateId(prefix) {
    _idCounter++;
    return (prefix || "id") + "_" + Date.now() + "_" + _idCounter;
  }

  // === String Utilities ===

  function stripTags(text) {
    if (!text)
      return "";
    return text.replace(/<[^>]*>?/gm, '');
  }

  function truncate(text, maxLength) {
    if (!text || text.length <= maxLength)
      return text || "";
    return text.substring(0, maxLength - 1) + "…";
  }

  function capitalize(text) {
    if (!text)
      return "";
    return text.charAt(0).toUpperCase() + text.slice(1);
  }

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

  function updateModelItem(model, property, value, updates) {
    const index = findInModel(model, property, value);
    if (index < 0)
      return false;
    for (const key in updates) {
      model.setProperty(index, key, updates[key]);
    }
    return true;
  }

  // === JSON Utilities ===

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
}
