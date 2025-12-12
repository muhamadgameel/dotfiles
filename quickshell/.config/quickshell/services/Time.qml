pragma Singleton

import QtQuick
import Quickshell

/*
* Time - Time updates and formatting
*/
Singleton {
  id: root

  // Formatted time strings (reactive)
  readonly property string timeShort: Qt.formatTime(clock.date, "hh:mm")
  readonly property string timeLong: Qt.formatTime(clock.date, "hh:mm:ss AP")
  readonly property string dateShort: Qt.formatDate(clock.date, "ddd, MMM d")
  readonly property string dateLong: Qt.formatDate(clock.date, "dddd, MMMM d, yyyy")

  SystemClock {
    id: clock

    precision: SystemClock.Seconds
  }

  // Format a relative time string (e.g., "2 minutes ago", "Yesterday")
  function formatRelativeTime(date) {
    if (!date)
      return "";

    var now = clock.date;
    var then = date instanceof Date ? date : new Date(date);
    var diffMs = now.getTime() - then.getTime();
    var diffSec = Math.floor(diffMs / 1000);
    var diffMin = Math.floor(diffSec / 60);
    var diffHour = Math.floor(diffMin / 60);
    var diffDay = Math.floor(diffHour / 24);

    if (diffSec < 60)
      return "Just now";
    if (diffMin < 60)
      return diffMin + (diffMin === 1 ? " minute ago" : " minutes ago");
    if (diffHour < 24)
      return diffHour + (diffHour === 1 ? " hour ago" : " hours ago");
    if (diffDay === 1)
      return "Yesterday";
    if (diffDay < 7)
      return diffDay + " days ago";

    // For older dates, show the actual date
    return Qt.formatDate(then, "MMM d");
  }
}
