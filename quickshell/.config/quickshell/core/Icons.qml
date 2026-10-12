pragma Singleton

import QtQuick
import Quickshell

/**
* Icons - Central registry of icon name to Nerd Font glyph mappings
*
* Usage:
*   Text { text: Core.Icons.get("bell") }
*
* Or with the Icon component:
*   Icon { icon: "bell" }
*/
Singleton {
  id: root

  // Font family for icons
  readonly property string fontFamily: "Symbols Nerd Font Mono"

  // === Icon Registry ===
  // Organized by category for easier maintenance

  readonly property var _icons: ({
      // === Navigation ===
      "chevron-left": "󰅁",
      "chevron-right": "󰅂",
      "arrow-up": "󰁝",
      "arrow-down": "󰁅",

      // === Actions ===
      "close": "󰅖",
      "check": "󰄬",
      "refresh": "󰑓",
      "edit": "󰏫",
      "copy": "󰆏",
      "trash": "󰆴",
      "external-link": "󰏌",

      // === System ===
      "settings": "󰒓",
      "power": "󰐥",
      "lock": "󰌾",
      "logout": "󰗼",
      "info": "󰋽",
      "warning": "󰀪",
      "error": "󰅚",

      // === Notifications ===
      "bell": "󰂚",
      "bell-off": "󰂛",

      // === Theme ===
      "moon": "󰖔",
      "sun": "󰖙",
      "cloud": "󰖐",
      "cloud-sun": "󰖕",
      "rain": "󰖗",
      "snow": "󰖘",
      "storm": "󰖓",
      "palette": "󰏘",

      // === Visibility ===
      "eye": "󰈈",
      "eye-off": "󰈉",

      // === Connectivity ===
      // WiFi signal strength icons
      "wifi": "󰤨",
      "wifi-strong": "󰤨",
      "wifi-medium": "󰤥",
      "wifi-weak": "󰤟",
      "wifi-off": "󰤭",

      // Bluetooth
      "bluetooth": "󰂯",
      "bluetooth-off": "󰂲",
      "bluetooth-connected": "󰂱",
      "bluetooth-searching": "󰂰",

      // === Input Devices ===
      "mouse": "󰍽",
      "keyboard": "󰌌",
      "gamepad": "󰊖",

      // Network
      "network": "󰛳",
      "network-off": "󰲛",
      "usb": "󰕓",

      // === Audio ===
      "volume": "󰕾",
      "volume-high": "󰕾",
      "volume-medium": "󰖀",
      "volume-low": "󰕿",
      "volume-mute": "󰖁",
      "volume-off": "󰝟",
      "microphone": "󰍬",
      "microphone-off": "󰍭",
      "headphones": "󰋋",
      "headphones-off": "󰟎",
      "speaker": "󰓃",

      // === Display ===
      "brightness-high": "󰃠",
      "brightness-medium": "󰃟",
      "brightness-low": "󰃞",
      "monitor": "󰍹",
      "laptop": "󰌢",

      // === Power/Battery ===
      "battery": "󰁹",
      "battery-full": "󰁹",
      "battery-high": "󰂁",
      "battery-medium": "󰁾",
      "battery-low": "󰁻",
      "battery-critical": "󰂃",
      "battery-charging": "󰂄",
      "battery-unknown": "󰂑",

      // === Media ===
      "play": "󰐊",
      "pause": "󰏤",
      "skip-next": "󰒭",
      "skip-previous": "󰒮",
      "shuffle": "󰒟",
      "repeat": "󰑖",
      "repeat-one": "󰑘",
      "playlist": "󰲸",
      "music": "󰝚",
      "video": "󰕧",
      "image": "󰋩",

      // === Social/Rating ===
      "heart": "󰋑",

      // === Apps/Launcher ===
      "apps": "󰀻",
      "grid": "󰕰",
      "browser": "󰖟",
      "calendar": "󰃭",
      "clock": "󰥔",
      "camera": "󰄀",
      "message": "󰍡",
      "phone": "󰏲",

      // === Workspace/Window ===
      "window": "󱂬",
      "layers": "󰌨",

      // === System Monitoring ===
      "cpu": "",
      "gpu": "󰢮",
      "memory": "",
      "ram": "󰘚",
      "disk": "󰋊",
      "thermometer": "󰔏",
      "thermometer-high": "󰔐",
      "chip": "󰍛",
      "dashboard": "󰕮",
      "gauge": "󰓅",
      "fire": "󰈸",

      // === Capture ===
      "crop": "󰆞",

      // === Misc ===
      "shield": "󰒃",
      "rocket": "󰑣",
      "chart": "󱕎"
    })

  /**
  * Get icon glyph by name
  * @param name - Icon name
  * @returns Nerd Font glyph, or "" when the name is unknown
  *
  * Unknown names return empty rather than "?" so a typo renders as nothing
  * instead of a literal question mark in the bar. Use has() to assert a name.
  */
  function get(name) {
    return name ? (_icons[name] ?? "") : "";
  }

  function has(name) {
    return root._icons[name] !== undefined;
  }
}
