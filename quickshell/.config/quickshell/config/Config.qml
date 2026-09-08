pragma Singleton

import QtQuick
import Quickshell

import "../core" as Core

/**
* Config - shell configuration
*
* Every value reads through Settings, with the default written inline. That
* means:
*
* - Defaults live here, in one readable place, and are never written to disk.
* - Anything can be changed at runtime and survives a restart.
* - Adding a key needs no migration; an older settings.json simply falls back.
*
* Use the setters below rather than assigning, so the change is persisted.
*/
Singleton {
  id: root

  // === Feature Toggles ===
  readonly property bool animationsEnabled: Settings.get("animationsEnabled", true)
  readonly property bool shadowsEnabled: Settings.get("shadowsEnabled", true)
  readonly property bool debugMode: Settings.get("debugMode", false)

  // === Bar Configuration ===
  readonly property string barPosition: Settings.get("barPosition", "top")
  readonly property bool barShowClock: Settings.get("barShowClock", true)
  readonly property bool barShowVolume: Settings.get("barShowVolume", true)
  readonly property bool barShowMicrophone: Settings.get("barShowMicrophone", true)
  readonly property bool barShowBrightness: Settings.get("barShowBrightness", true)
  readonly property bool barShowBattery: Settings.get("barShowBattery", true)
  readonly property bool barShowLauncher: Settings.get("barShowLauncher", true)
  readonly property bool barShowNotification: Settings.get("barShowNotification", true)
  readonly property bool barShowNetwork: Settings.get("barShowNetwork", true)
  readonly property bool barShowBluetooth: Settings.get("barShowBluetooth", true)
  readonly property bool barShowSystemStats: Settings.get("barShowSystemStats", true)
  readonly property bool barShowTray: Settings.get("barShowTray", true)
  readonly property bool barShowMedia: Settings.get("barShowMedia", true)
  readonly property bool barShowIdleInhibitor: Settings.get("barShowIdleInhibitor", true)
  readonly property bool barShowWindowTitle: Settings.get("barShowWindowTitle", true)
  readonly property bool barShowScreenshot: Settings.get("barShowScreenshot", true)
  readonly property bool barShowPower: Settings.get("barShowPower", true)

  // === Appearance ===
  readonly property string theme: Settings.get("theme", Themes.defaultName)
  readonly property real uiScale: Settings.get("uiScale", 1.0)

  readonly property string fontFamily: Settings.get("fontFamily", "Roboto")

  readonly property real surfaceOpacity: Settings.get("surfaceOpacity", 0.85)

  // === OSD Configuration ===
  readonly property string osdPosition: Settings.get("osdPosition", "top_right")
  readonly property int osdDuration: Settings.get("osdDuration", 2000)
  readonly property bool osdEnabled: Settings.get("osdEnabled", true)

  // === Notifications ===
  readonly property bool doNotDisturb: Settings.get("doNotDisturb", false)
  readonly property int notificationHistoryLimit: Settings.get("notificationHistoryLimit", 100)

  // === Tooltip Configuration ===
  readonly property int tooltipDelay: Settings.get("tooltipDelay", 500)
  readonly property int tooltipMaxWidth: Settings.get("tooltipMaxWidth", 320)

  // === Workspaces ===
  // By default the bar shows only the workspaces that exist on its monitor -
  // Hyprland keeps one alive while it has windows or focus. Turn this on to get
  // a fixed row of workspaceCount slots instead, which never reflows but is
  // permanently there.
  readonly property bool workspaceShowEmpty: Settings.get("workspaceShowEmpty", false)

  // Slot count for the fixed row above; ignored unless workspaceShowEmpty.
  readonly property int workspaceCount: Settings.get("workspaceCount", 5)

  // === Setters ===
  // Assigning to the readonly properties above is not possible by design -
  // route changes through here so they persist.

  function setTheme(name) {
    Settings.set("theme", name);
  }

  function setFontFamily(name) {
    Settings.set("fontFamily", name);
  }

  function setUiScale(scale) {
    Settings.set("uiScale", Core.Utils.clamp(scale, 0.5, 2.0));
  }

  function setDoNotDisturb(enabled) {
    Settings.set("doNotDisturb", enabled);
  }

  function toggleDoNotDisturb() {
    return Settings.toggle("doNotDisturb");
  }

  function setWidgetVisible(key, visible) {
    Settings.set(key, visible);
  }

  function toggleDebugMode() {
    return Settings.toggle("debugMode");
  }

  function toggleShadows() {
    return Settings.toggle("shadowsEnabled", true);
  }

  function setSurfaceOpacity(value) {
    Settings.set("surfaceOpacity", Core.Utils.clamp(value, 0.3, 1.0));
  }
}
