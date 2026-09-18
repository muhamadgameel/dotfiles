pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config
import "../services" as Services

/**
* Time - the clock, and formatting that depends on it
*
* Two SystemClocks, split by how often what they drive actually changes:
*
* - `minuteClock` drives everything shown to the minute: the bar clock by
*   default, both dates, and relative notification timestamps. One wakeup a
*   minute.
* - `secondClock` drives `timeLong` alone, and only runs while something is
*   showing seconds - the bar with barClockShowSeconds on, or the calendar.
*
* A single seconds-precision clock used to drive all of it. The bar redrew and
* committed a frame 86,400 times a day to show a minute that changes 1,440
* times, and both date strings were rebuilt every second along with it.
*
* Every widget binds these strings rather than running a timer of its own, so
* there is one wakeup per precision no matter how many clocks are on screen.
*
* Usage:
*   Services.Time.timeShort              // "06:05 PM"
*   Services.Time.formatRelativeTime(d)  // "2 minutes ago"
*/
Singleton {
  id: root

  // === Formatted Strings (reactive) ===
  // timeShort is 12-hour to match timeLong. It used to be 24-hour, so the
  // calendar showed "18:05" in its header over "06:05:12 PM" in its body.
  readonly property string timeShort: Qt.formatTime(minuteClock.date, "hh:mm AP")
  readonly property string dateShort: Qt.formatDate(minuteClock.date, "ddd, MMM d")
  readonly property string dateLong: Qt.formatDate(minuteClock.date, "dddd, MMMM d, yyyy")

  // Current only while secondsWanted. Read it only from something that is
  // itself counted in secondsWanted, or it shows a frozen time.
  readonly property string timeLong: Qt.formatTime(secondClock.date, "hh:mm:ss AP")

  // Minutes since midnight, for anything that acts at a time of day rather
  // than displaying one.
  readonly property int minuteOfDay: minuteClock.date.getHours() * 60 + minuteClock.date.getMinutes()

  // Whether anything on screen shows seconds right now.
  readonly property bool secondsWanted: Config.Config.barClockShowSeconds || Services.Panels.openPanel === "calendar"

  SystemClock {
    id: minuteClock

    precision: SystemClock.Minutes
  }

  SystemClock {
    id: secondClock

    precision: SystemClock.Seconds
    enabled: root.secondsWanted
  }

  // Format a relative time string (e.g., "2 minutes ago", "Yesterday").
  //
  // Driven by the minute clock, so it re-evaluates once a minute - the finest
  // step any of these strings can show. A timestamp newer than the last tick
  // gives a negative difference, which correctly reads "Just now".
  function formatRelativeTime(date) {
    if (!date)
      return "";

    var now = minuteClock.date;
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
