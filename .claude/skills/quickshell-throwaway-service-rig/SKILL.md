---
name: quickshell-throwaway-service-rig
description: When testing a Quickshell service: warm via IPC before use.
category: testing
---

Probe one service on a scratch Quickshell config, substituting side effects and stub stand-ins for others. A service accessed through `property var name: Services.ServiceName` does not start until first use—even the property declaration alone will not initialize it. Call an IPC method or read a property through IPC before the first synchronous read, so the service is warm when the test runs.

## Setup

Use an offscreen `QT_QPA_PLATFORM=offscreen` environment, a probe directory as `XDG_CONFIG_HOME`, and IPC calls to query state and drive the test. Stub each service that the real one depends on (use a `Component { onCompleted: { // mock data } }` near the root), and record state through IPC handlers in the probe's `ShellRoot`.

## Example

Testing a notification service: load the real service, stub the D-Bus backend (mock incoming notifications via an IPC call), and read back what was stored via another IPC call. The stubs prevent side effects; the real code runs.

Related: [[quickshell-hot-reload-pitfalls]], [[quickshell-multi-file-live-writes]], [[quickshell-testing-comprehensive]]