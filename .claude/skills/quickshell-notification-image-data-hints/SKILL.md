---
name: quickshell-notification-image-data-hints
description: When notification has no path, load image-data as QImage.
category: quickshell-development
---

When a D-Bus notification carries no `app_icon` or `image-path` but includes raw RGBA bytes in the `image-data` hint struct, extract the dimensions and byte array, construct a QImage, and assign it as the icon source.

Desktop apps like Claude bundle their logo as binary data and send it through D-Bus notification hints instead of a file path. Identify the app via `desktop-entry` (e.g., `com.anthropic.Claude`) and route the image struct to your notification's icon display pipeline.