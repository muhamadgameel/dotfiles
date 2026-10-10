  WheelHandler {
    // Qt's Wayland platform reports every wheel event as a touchpad's.
    acceptedDevices: PointerDevice.AllDevices
    onWheel: event => {