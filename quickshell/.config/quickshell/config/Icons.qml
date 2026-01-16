pragma Singleton

import QtQuick
import Quickshell

/**
* Icons - Central registry of icon name to Nerd Font glyph mappings
*
* Usage:
*   import "../config" as Config
*   Text { text: Config.Icons.get("bell") }
*
* Or with the Icon component:
*   Icon { name: "bell" }
*/
Singleton {
  id: root

  // Font family for icons
  readonly property string fontFamily: "Symbols Nerd Font Mono"

  // === Icon Registry ===
  // Organized by category for easier maintenance

  readonly property var _icons: ({
      // === Navigation ===
      "chevron-down": "󰅀",
      "chevron-up": "󰅃",
      "chevron-left": "󰅁",
      "chevron-right": "󰅂",
      "arrow-left": "󰁍",
      "arrow-right": "󰁔",
      "arrow-up": "󰁝",
      "arrow-down": "󰁅",
      "menu": "󰍜",
      "more": "󰇙",

      // === Actions ===
      "close": "󰅖",
      "check": "󰄬",
      "plus": "󰐕",
      "minus": "󰍴",
      "search": "󰍉",
      "refresh": "󰑓",
      "edit": "󰏫",
      "save": "󰆓",
      "copy": "󰆏",
      "paste": "󰆒",
      "trash": "󰆴",
      "download": "󰇚",
      "upload": "󰕒",
      "external-link": "󰏌",

      // === System ===
      "settings": "󰒓",
      "power": "󰐥",
      "lock": "󰌾",
      "logout": "󰗼",
      "user": "󰀄",
      "info": "󰋽",
      "warning": "󰀪",
      "error": "󰅚",
      "question": "󰋖",

      // === Notifications ===
      "bell": "󰂚",
      "bell-off": "󰂛",
      "bell-ring": "󰂞",

      // === Theme ===
      "moon": "󰖔",
      "sun": "󰖙",
      "palette": "󰏘",

      // === Visibility ===
      "eye": "󰈈",
      "eye-off": "󰈉",

      // === Files ===
      "folder": "󰉋",
      "folder-open": "󰉖",
      "file": "󰈔",
      "file-text": "󰈙",

      // === Connectivity ===
      // WiFi signal strength icons
      "wifi": "󰤨",
      "wifi-strong": "󰤨",
      "wifi-medium": "󰤥",
      "wifi-weak": "󰤟",
      "wifi-off": "󰤭",
      "wifi-lock": "󰤪",
      "wifi-alert": "󰤬",
      "wifi-outline": "󰤯",

      // Bluetooth
      "bluetooth": "󰂯",
      "bluetooth-off": "󰂲",
      "bluetooth-connected": "󰂱",
      "bluetooth-searching": "󰂰",
      "bluetooth-audio": "󰂰",

      // === Input Devices ===
      "mouse": "󰍽",
      "keyboard": "󰌌",
      "gamepad": "󰊖",

      // Network
      "network": "󰛳",
      "network-off": "󰲛",
      "ethernet": "󰈀",
      "ethernet-off": "󰈂",
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
      "brightness": "󰃟",
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
      "stop": "󰓛",
      "skip-next": "󰒭",
      "skip-previous": "󰒮",
      "fast-forward": "󰒐",
      "rewind": "󰒓",
      "shuffle": "󰒟",
      "repeat": "󰑖",
      "repeat-one": "󰑘",
      "playlist": "󰲸",
      "music": "󰝚",
      "video": "󰕧",
      "image": "󰋩",

      // === Social/Rating ===
      "star": "󰓎",
      "star-off": "󰓏",
      "star-half": "󰓐",
      "heart": "󰋑",
      "heart-off": "󰋕",
      "thumbs-up": "󰍵",
      "thumbs-down": "󰍶",

      // === Apps/Launcher ===
      "apps": "󰀻",
      "grid": "󰕰",
      "terminal": "󰆍",
      "code": "󰗀",
      "browser": "󰖟",
      "calculator": "󰃬",
      "calendar": "󰃭",
      "clock": "󰥔",
      "camera": "󰄀",
      "mail": "󰇮",
      "message": "󰍡",
      "phone": "󰏲",

      // === Workspace/Window ===
      "window": "󱂬",
      "window-maximize": "󰁌",
      "window-minimize": "󰖰",
      "window-restore": "󰁐",
      "layers": "󰌨",
      "split": "󰕮",

      // === System Monitoring ===
      "cpu": "",
      "cpu-temp": "󱃃",
      "gpu": "󰢮",
      "gpu-temp": "󰢮",
      "memory": "",
      "ram": "󰘚",
      "disk": "󰋊",
      "thermometer": "󰔏",
      "thermometer-high": "󰔐",
      "thermometer-low": "󱃃",
      "chip": "󰍛",
      "dashboard": "󰕮",
      "gauge": "󰓅",
      "fire": "󰈸",

      // === Misc ===
      "loading": "󰑓",
      "spinner": "󰑓",
      "dot": "󰧞",
      "circle": "󰝥",
      "square": "󰝤",
      "pin": "󰐃",
      "pin-off": "󰐄",
      "link": "󰌷",
      "unlink": "󰌸",
      "key": "󰌋",
      "shield": "󰒃",
      "bug": "󰃤",
      "rocket": "󰑣",
      "flag": "󰈿",
      "bookmark": "󰃀",
      "tag": "󰓹",
      "filter": "󰈶",
      "sort": "󰒺",
      "chart": "󱕎"
    })

  /**
  * Get icon glyph by name
  * @param name - Icon name
  * @returns Nerd Font glyph or "?" if not found
  */
  function get(name) {
    return _icons[name] || "?";
  }

  function has(name) {
    return root._icons[name] !== undefined;
  }
}
