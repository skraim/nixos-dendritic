pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string cacheDir: {
        const xdg = Quickshell.env("XDG_CACHE_HOME");
        return (xdg ? xdg : Quickshell.env("HOME") + "/.cache") + "/quickshell";
    }
    readonly property string cachePath: cacheDir + "/weather.json"

    // ── Public properties ──────────────────────────────────────────────
    property bool hasData: false
    property bool loading: false
    property string cityName: ""

    property real currentTemp: 0
    property real currentFeelsLike: 0
    property int currentCode: 0
    property real currentHumidity: 0
    property real currentWindSpeed: 0
    property int currentWindDir: 0
    property real todayMax: 0
    property real todayMin: 0

    property var hourlySlots: []   // [{time, code, temp, precip}] – 12 at 2h step
    property var dailySlots: []   // [{date, code, max, min}]     – 6 days

    property string lastFetch: ""

    // ── Ensure cache dir exists on startup ─────────────────────────────
    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.cacheDir]
        running: false
    }

    // ── Cache via FileView + JsonAdapter ───────────────────────────────
    FileView {
        id: cacheFile
        path: root.cachePath
        printErrors: false
        onLoaded: {
            if (cacheData.fetchedAt > 0 && cacheData.response !== null)
                root._applyResponse(cacheData.response, cacheData.lat, cacheData.lon, cacheData.city);
            root._maybeFetch();
        }
        onLoadFailed: root._doFetch()

        JsonAdapter {
            id: cacheData
            property real lat: 0
            property real lon: 0
            property string city: ""
            property int fetchedAt: 0
            property var response: null   // raw open-meteo response
        }
    }

    Component.onCompleted: {
        mkdirProc.running = true;
        cacheFile.reload();
    }

    Timer {
        interval: 3 * 60 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root._maybeFetch()
    }

    // ── Fetch logic ────────────────────────────────────────────────────
    function _maybeFetch() {
        const age = Math.floor(Date.now() / 1000) - cacheData.fetchedAt;
        if (cacheData.fetchedAt === 0 || age >= 3 * 60 * 60)
            _doFetch();
    }

    function _doFetch() {
        if (loading)
            return;
        loading = true;
        _geolocate();
    }

    function refreshHourlySlots() {
        if (cacheData.response !== null)
            _refreshHourlySlots(cacheData.response);
    }

    function _geolocate() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    var geo = JSON.parse(xhr.responseText);
                    if (geo.status === "success")
                        _fetchWeather(geo.lat, geo.lon, geo.city + ", " + geo.countryCode);
                    else {
                        loading = false;
                        console.log("WeatherService: geo failed:", geo.message);
                    }
                } catch (e) {
                    loading = false;
                    console.log("WeatherService: geo parse error", e);
                }
            } else {
                loading = false;
                console.log("WeatherService: geo http error", xhr.status);
            }
        };
        xhr.open("GET", "http://ip-api.com/json/");
        xhr.send();
    }

    function _fetchWeather(lat, lon, city) {
        const url = "https://api.open-meteo.com/v1/forecast" + "?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,relative_humidity_2m,apparent_temperature" + ",weather_code,wind_speed_10m,wind_direction_10m" + "&hourly=temperature_2m,weather_code,precipitation_probability" + "&daily=temperature_2m_max,temperature_2m_min,weather_code" + "&timezone=auto&forecast_days=8";

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            loading = false;
            if (xhr.status === 200) {
                try {
                    var d = JSON.parse(xhr.responseText);
                    _applyResponse(d, lat, lon, city);
                    cacheData.lat = lat;
                    cacheData.lon = lon;
                    cacheData.city = city;
                    cacheData.fetchedAt = Math.floor(Date.now() / 1000);
                    cacheData.response = d;
                    cacheFile.writeAdapter();
                } catch (e) {
                    console.log("WeatherService: weather parse error", e);
                }
            } else {
                console.log("WeatherService: weather http error", xhr.status);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function _applyResponse(d, lat, lon, city) {
        const c = d.current;
        root.currentTemp = Math.round(c.temperature_2m);
        root.currentFeelsLike = Math.round(c.apparent_temperature);
        root.currentCode = c.weather_code;
        root.currentHumidity = Math.round(c.relative_humidity_2m);
        root.currentWindSpeed = Math.round(c.wind_speed_10m);
        root.currentWindDir = Math.round(c.wind_direction_10m);
        root.todayMax = Math.round(d.daily.temperature_2m_max[0]);
        root.todayMin = Math.round(d.daily.temperature_2m_min[0]);
        root.cityName = city;

        root._refreshHourlySlots(d);

        // Daily: 6 days starting tomorrow (index 1)
        const daily = [];
        for (let i = 1; i <= 6 && i < d.daily.time.length; i++) {
            daily.push({
                date: d.daily.time[i],
                code: d.daily.weather_code[i],
                max: Math.round(d.daily.temperature_2m_max[i]),
                min: Math.round(d.daily.temperature_2m_min[i])
            });
        }
        root.dailySlots = daily;
        root.lastFetch = Qt.formatDateTime(new Date(), "HH:mm");
        root.hasData = true;
    }

    function _refreshHourlySlots(d) {
        const nowIso = _apiLocalTimestamp(d);
        const times = d.hourly.time;
        let start = times.length;
        for (let i = 0; i < times.length; i++) {
            if (times[i] > nowIso) {
                start = i;
                break;
            }
        }
        // Align to next even-hour boundary
        if (start < times.length)
            start += parseInt(times[start].slice(11, 13)) % 2;
        const hourly = [];
        for (let i = start; i < times.length && hourly.length < 12; i += 2) {
            hourly.push({
                time: times[i].slice(11, 16)   // "HH:MM"
                ,
                temp: Math.round(d.hourly.temperature_2m[i]),
                code: d.hourly.weather_code[i],
                precip: d.hourly.precipitation_probability[i] || 0
            });
        }
        root.hourlySlots = hourly;
    }

    // ── Helpers ────────────────────────────────────────────────────────
    function iconFromCode(code) {
        if (code === 0)
            return "clear_day";
        if (code <= 2)
            return "partly_cloudy_day";
        if (code === 3)
            return "cloud";
        if (code >= 45 && code <= 48)
            return "foggy";
        if (code >= 51 && code <= 57)
            return "rainy_light";
        if (code >= 61 && code <= 67)
            return "rainy";
        if (code >= 71 && code <= 77)
            return "weather_snowy";
        if (code >= 80 && code <= 82)
            return "rainy";
        if (code >= 85 && code <= 86)
            return "weather_snowy";
        if (code >= 95)
            return "thunderstorm";
        return "cloud";
    }

    function descFromCode(code) {
        if (code === 0)
            return "Clear sky";
        if (code === 1)
            return "Mainly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Overcast";
        if (code >= 45 && code <= 48)
            return "Fog";
        if (code >= 51 && code <= 57)
            return "Drizzle";
        if (code >= 61 && code <= 67)
            return "Rain";
        if (code >= 71 && code <= 77)
            return "Snow";
        if (code >= 80 && code <= 82)
            return "Rain showers";
        if (code >= 85 && code <= 86)
            return "Snow showers";
        if (code >= 95)
            return "Thunderstorm";
        return "Cloudy";
    }

    function _apiLocalTimestamp(d) {
        const offsetSeconds = Number(d.utc_offset_seconds) || 0;
        const shifted = new Date(Date.now() + offsetSeconds * 1000);

        function pad2(value) {
            return value < 10 ? "0" + value : "" + value;
        }

        return shifted.getUTCFullYear() + "-" + pad2(shifted.getUTCMonth() + 1) + "-" + pad2(shifted.getUTCDate()) + "T" + pad2(shifted.getUTCHours()) + ":" + pad2(shifted.getUTCMinutes());
    }

    function windDirIcon(deg) {
        const icons = ["\ue353" // weather-direction_up
            , "\ue352" // weather-direction_up_right
            , "x_circle" // official Material Symbols name for e349
            , "\ue380" // weather-direction_down_right
            , "\ue340" // weather-direction_down
            , "\ue33f" // weather-direction_down_left
            , "\ue344" // weather-direction_left
            , "\ue37f"  // weather-direction_up_left
        ];
        return icons[Math.round(deg / 45) % 8];
    }
}
