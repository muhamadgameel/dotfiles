import QtQuick
import Quickshell.Io

/**
* DeviceDetails - IPv4 address, gateway and DNS of one interface, from nmcli
*
* Call refresh() after setting `device`. An empty device clears the values.
*/
Process {
  id: root

  property string device: ""

  property string ip: ""
  property string gateway: ""
  property string dns: ""

  function refresh() {
    if (device === "") {
      ip = "";
      gateway = "";
      dns = "";
      return;
    }
    running = true;
  }

  // Undo nmcli's terse-mode escaping for a value from a KEY:VALUE line cut at
  // its first colon.
  function _unescape(value) {
    return value ? value.replace(/\\(.)/g, "$1") : "";
  }

  command: ["nmcli", "-t", "-e", "yes", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", device]

  stdout: StdioCollector {
    onStreamFinished: {
      let ip = "", gateway = "";
      const dnsServers = [];

      for (const line of text.split("\n")) {
        const idx = line.indexOf(":");
        if (idx <= 0)
          continue;

        const key = line.substring(0, idx);
        const value = root._unescape(line.substring(idx + 1));

        if (key.startsWith("IP4.ADDRESS") && !ip)
          ip = value;
        else if (key === "IP4.GATEWAY")
          gateway = value;
        else if (key.startsWith("IP4.DNS"))
          dnsServers.push(value);
      }

      root.ip = ip;
      root.gateway = gateway;
      root.dns = dnsServers.join(", ");
    }
  }
}
