pragma Singleton

import QtQuick
import Quickshell

import "../config" as Config
import "../core" as Core

/**
* Weather - the temperature now and five days of it, for one city
*
* From open-meteo.com through curl: no key and no account. The city's name goes
* out once, to find its coordinates; after that only the coordinates do. With no
* city set nothing is asked. `qs ipc call weather city <name>` sets it.
*/
Singleton {
  id: root

  readonly property string city: Config.Config.weatherCity
  readonly property bool located: Config.Config.weatherLatitude !== 0 || Config.Config.weatherLongitude !== 0

  // Whether there is an answer, and for this city.
  readonly property bool ready: _answer !== null && _kept.city === root.city
  readonly property real temperature: ready ? _answer.current.temperature_2m : 0
  // A WMO weather code; describe() puts it in words and icon() names a glyph.
  readonly property int code: ready ? _answer.current.weather_code : -1
  readonly property bool night: ready && _answer.current.is_day === 0
  // Today first: { date, code, min, max }.
  readonly property var days: !ready ? [] : _answer.daily.time.map((date, i) => ({
        date: date,
        code: _answer.daily.weather_code[i],
        min: _answer.daily.temperature_2m_min[i],
        max: _answer.daily.temperature_2m_max[i]
      }))
  readonly property real fetchedAt: _kept.fetchedAt
  // Why the last try failed, or "".
  property string problem: ""

  readonly property string statusText: {
    if (root.city === "")
      return "no city set";
    if (root.problem !== "")
      return root.problem;
    if (!root.ready)
      return `asking about ${root.city}`;
    return `${root.city}: ${Math.round(root.temperature)}°C, ${root.describe(root.code).toLowerCase()}; checked at ${Qt.formatTime(new Date(root.fetchedAt), "HH:mm")}`;
  }

  readonly property int refreshEveryMs: 30 * 60 * 1000

  function describe(code) {
    if (code === 0)
      return "Clear";
    if (code === 1)
      return "Mostly clear";
    if (code === 2)
      return "Partly cloudy";
    if (code === 3)
      return "Overcast";
    if (code <= 48)
      return "Fog";
    if (code <= 57)
      return "Drizzle";
    if (code <= 67)
      return "Rain";
    if (code <= 77)
      return "Snow";
    if (code <= 82)
      return "Showers";
    if (code <= 86)
      return "Snow showers";
    return "Thunderstorm";
  }

  function icon(code, night) {
    if (code <= 1)
      return night ? "moon" : "sun";
    if (code === 2)
      return "cloud-sun";
    if (code <= 48)
      return "cloud";
    if (code <= 67)
      return "rain";
    if (code <= 77)
      return "snow";
    if (code <= 82)
      return "rain";
    if (code <= 86)
      return "snow";
    return "storm";
  }

  function setCity(name) {
    _kept.unknown = "";
    Config.Config.setWeatherPlace(name.trim(), 0, 0);
    root.refresh();
  }

  property real _triedAt: 0

  function refresh() {
    if (root.city === "" || _find.running || _fetch.running)
      return;
    root._triedAt = Date.now();

    if (!root.located) {
      // A name nobody knew is not sent again.
      if (root.city === _kept.unknown)
        return;
      _find.command = ["curl", "-sf", "--max-time", "10", `https://geocoding-api.open-meteo.com/v1/search?count=1&language=en&format=json&name=${encodeURIComponent(root.city)}`];
      _find.running = true;
      return;
    }

    _fetch.command = ["curl", "-sf", "--max-time", "10", `https://api.open-meteo.com/v1/forecast?latitude=${Config.Config.weatherLatitude}&longitude=${Config.Config.weatherLongitude}&current=temperature_2m,weather_code,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=5`];
    _fetch.running = true;
  }

  readonly property var _answer: Core.Utils.parseJson(_kept.json, null)

  // The last answer survives a reload. A restart asks again.
  PersistentProperties {
    id: _kept

    reloadableId: "weather"

    property string json: ""
    property string city: ""
    property real fetchedAt: 0
    property string unknown: ""
  }

  Core.Command {
    id: _find

    onDone: (code, out) => {
      const place = (Core.Utils.parseJson(out, ({})).results ?? [])[0];
      if (!place) {
        root.problem = code === 0 ? `could not find ${root.city}` : "open-meteo did not answer";
        if (code === 0)
          _kept.unknown = root.city;
        return;
      }
      Config.Config.setWeatherPlace(place.name, place.latitude, place.longitude);
      root.refresh();
    }
  }

  Core.Command {
    id: _fetch

    onDone: (code, out) => {
      if (!Core.Utils.parseJson(out, ({})).current) {
        root.problem = "open-meteo did not answer";
        return;
      }
      root.problem = "";
      _kept.json = out;
      _kept.city = root.city;
      _kept.fetchedAt = Date.now();
    }
  }

  // Looks once a minute whether an answer is due, so the half hour counts from
  // the last answer and a reload does not push it back.
  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: {
      // After a failure, offline say, the next try waits five minutes, not one.
      if (root.problem !== "" && Date.now() - root._triedAt < 5 * 60000)
        return;
      if (_kept.city !== root.city || Date.now() - _kept.fetchedAt >= root.refreshEveryMs)
        root.refresh();
    }
  }
}
