import QtQuick

import "../../../services" as Services

/**
* Updates - how many packages wait, when any do
*
* - Left click:  upgrade, in a terminal
* - Right click: check now
*/
BarButton {
  id: root

  // How many packages the tooltip names.
  readonly property int listed: 8

  icon: "refresh"
  iconSpinning: Services.Updates.checking
  text: Services.Updates.count

  tooltipText: {
    const packages = Services.Updates.packages;
    const lines = [`${packages.length} update${packages.length === 1 ? "" : "s"}`, ""].concat(packages.slice(0, root.listed));
    if (packages.length > root.listed)
      lines.push(`and ${packages.length - root.listed} more`);
    lines.push("");
    lines.push("Left click: Upgrade in a terminal");
    lines.push("Right click: Check now");
    return lines.join("\n");
  }

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  onClicked: button => {
    if (button === Qt.RightButton)
      Services.Updates.check();
    else
      Services.Updates.upgrade();
  }
}
