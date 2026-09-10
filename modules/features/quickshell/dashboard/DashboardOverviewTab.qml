import QtQuick
import QtQuick.Layouts
import qs.services
import qs.utils

Item {
    id: root
    required property var win

    property alias contentImplicitHeight: tab2Col.implicitHeight
    property alias hourlyFlickable: _hourlyFlickable
    property alias calendarWidget: _calendarWidget

    function resetState() {
        root.win.weatherHourlyOpen = false;
        root.win.weatherDailyOpen = false;
        _hourlyFlickable.resetScroll();
        _calendarWidget.monthOffset = 0;
    }

    function weatherDescription(code) {
        const key = WeatherService.descFromCode(code).toLowerCase().split(" ").join("_")
        return Localization.t("dashboard.overview.weather.conditions." + key, WeatherService.descFromCode(code))
    }

    // ── Sub-components ────────────────────────────────────────────────────────

    component SectionDivider: Rectangle {
        Layout.fillWidth: true
        height: 1
        color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.92)
        Layout.topMargin: 7
        Layout.bottomMargin: 7
    }

    // ── Tab content ───────────────────────────────────────────────────────────

    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        contentHeight: tab2Col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: tab2Col
            width: parent.width
            spacing: 0

            DashboardSection {
                win: root.win
                icon: "wb_sunny"
                label: Localization.t("dashboard.overview.sections.today", "Today")
                z: root.win.weatherHourlyOpen ? 100 : 0

                Item {
                    id: todaySectionContent
                    Layout.fillWidth: true
                    implicitHeight: todayRow.implicitHeight + 20
                    property date clockDate: new Date()

                    Timer {
                        id: clockTimer
                        interval: 1000
                        repeat: true
                        running: root.win.currentTab === 2
                        triggeredOnStart: true
                        onTriggered: {
                            todaySectionContent.clockDate = new Date();
                            clockFace.requestPaint();
                        }
                    }

                    RowLayout {
                        id: todayRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: 10
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 8

                        Item {
                            id: fancyClock
                            Layout.preferredWidth: 196
                            Layout.preferredHeight: 188
                            Layout.alignment: Qt.AlignVCenter

                            readonly property int hours: todaySectionContent.clockDate.getHours()
                            readonly property int minutes: todaySectionContent.clockDate.getMinutes()
                            readonly property int seconds: todaySectionContent.clockDate.getSeconds()
                            readonly property real hourAngle: ((hours % 12) + minutes / 60) * 30
                            readonly property real minuteAngle: (minutes + seconds / 60) * 6
                            readonly property real secondAngle: seconds * 6

                            Canvas {
                                id: clockFace
                                anchors.centerIn: parent
                                width: 176
                                height: 176
                                renderStrategy: Canvas.Cooperative
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();

                                    const primary = MatugenColors.md3.primary;
                                    const onPrimary = MatugenColors.md3.on_primary;
                                    const cx = width / 2;
                                    const cy = height / 2;
                                    const base = Math.min(width, height) / 2 - 10;

                                    for (let i = 0; i < 60; i++) {
                                        const a = (i / 60) * Math.PI * 2 - Math.PI / 2;
                                        const isHour = i % 5 === 0;
                                        const isCardinal = i % 15 === 0;
                                        if (isCardinal)
                                            continue;
                                        const outer = isCardinal ? base - 2 : base - 7;
                                        const inner = outer - (isCardinal ? 26 : isHour ? 10 : 5);
                                        ctx.lineWidth = isCardinal ? 5.0 : isHour ? 2.3 : 1.3;
                                        ctx.lineCap = "round";
                                        ctx.strokeStyle = Qt.rgba(onPrimary.r, onPrimary.g, onPrimary.b, isCardinal ? 0.78 : isHour ? 0.28 : 0.24);
                                        ctx.beginPath();
                                        ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner);
                                        ctx.lineTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer);
                                        ctx.stroke();
                                    }
                                }
                            }

                            Canvas {
                                anchors.centerIn: clockFace
                                width: 136
                                height: 136
                                renderStrategy: Canvas.Cooperative
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    const cx = width / 2;
                                    const cy = height / 2;
                                    const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, width / 2);
                                    g.addColorStop(0.00, Qt.rgba(1, 1, 1, 0.16));
                                    g.addColorStop(0.42, Qt.rgba(1, 1, 1, 0.08));
                                    g.addColorStop(1.00, Qt.rgba(1, 1, 1, 0.00));
                                    ctx.fillStyle = g;
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, width / 2, 0, Math.PI * 2);
                                    ctx.fill();
                                }
                            }

                            Repeater {
                                model: [30, 60, 120, 150, 210, 240, 300, 330]
                                delegate: Item {
                                    required property int modelData
                                    anchors.centerIn: clockFace
                                    width: clockFace.width
                                    height: clockFace.height
                                    rotation: modelData

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 16
                                        width: 3
                                        height: 11
                                        radius: 1.5
                                        color: Qt.rgba(1, 1, 1, 0.36)
                                    }
                                }
                            }

                            Repeater {
                                model: [0, 90, 180, 270]
                                delegate: Item {
                                    required property int modelData
                                    anchors.centerIn: clockFace
                                    width: clockFace.width
                                    height: clockFace.height
                                    rotation: modelData

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 12
                                        width: 5
                                        height: 16
                                        radius: 2.5
                                        color: Qt.rgba(1, 1, 1, 0.62)
                                    }
                                }
                            }

                            Item {
                                anchors.centerIn: clockFace
                                rotation: fancyClock.hourAngle
                                Rectangle {
                                    x: -5
                                    y: -46
                                    width: 10
                                    height: 55
                                    radius: 5
                                    color: ColorUtils.transparentize(MatugenColors.md3.tertiary, 0.12)
                                }
                            }
                            Item {
                                anchors.centerIn: clockFace
                                rotation: fancyClock.minuteAngle
                                Rectangle {
                                    x: -4
                                    y: -70
                                    width: 8
                                    height: 78
                                    radius: 4
                                    color: ColorUtils.transparentize(MatugenColors.md3.tertiary, 0.08)
                                }
                            }
                            Item {
                                anchors.centerIn: clockFace
                                rotation: fancyClock.secondAngle
                                Rectangle {
                                    x: -1
                                    y: -72
                                    width: 2
                                    height: 82
                                    radius: 1
                                    color: MatugenColors.md3.error
                                    opacity: 0.75
                                }
                            }

                            Rectangle {
                                anchors.centerIn: clockFace
                                width: 14
                                height: 14
                                radius: 7
                                color: MatugenColors.md3.tertiary
                                border.width: 2
                                border.color: MatugenColors.md3.on_tertiary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8
                            visible: WeatherService.hasData

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                Text {
                                    text: WeatherService.iconFromCode(WeatherService.currentCode)
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 54
                                    color: MatugenColors.md3.primary
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: WeatherService.currentTemp + "°"
                                            font.family: "B612 Mono"
                                            font.weight: 600
                                            font.pixelSize: 46
                                            color: MatugenColors.md3.on_surface
                                        }
                                        ColumnLayout {
                                            spacing: 1
                                            Layout.alignment: Qt.AlignVCenter
                                            Text {
                                                text: Localization.t("dashboard.overview.weather.max", "Max: {temp}°", {
                                                    temp: WeatherService.todayMax
                                                })
                                                font.pixelSize: 12
                                                color: MatugenColors.md3.error
                                                opacity: 0.85
                                            }
                                            Text {
                                                text: Localization.t("dashboard.overview.weather.min", "Min: {temp}°", {
                                                    temp: WeatherService.todayMin
                                                })
                                                font.pixelSize: 12
                                                color: MatugenColors.md3.primary
                                                opacity: 0.70
                                            }
                                        }
                                    }
                                    Text {
                                        text: root.weatherDescription(WeatherService.currentCode)
                                        font.pixelSize: 13
                                        color: MatugenColors.md3.on_surface
                                        opacity: 0.60
                                    }
                                    Text {
                                        text: WeatherService.cityName
                                        font.pixelSize: 11
                                        color: MatugenColors.md3.on_surface
                                        opacity: 0.35
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Repeater {
                                    model: [
                                        {
                                            icon: "thermostat",
                                            label: Localization.t("dashboard.overview.weather.feels", "Feels {temp}°", {
                                                temp: WeatherService.currentFeelsLike
                                            })
                                        },
                                        {
                                            icon: "air",
                                            label: Localization.t("dashboard.overview.weather.wind", "{speed} km/h", {
                                                speed: WeatherService.currentWindSpeed
                                            }),
                                            windIcon: WeatherService.windDirIcon(WeatherService.currentWindDir)
                                        },
                                        {
                                            icon: "water_drop",
                                            label: WeatherService.currentHumidity + "%"
                                        }
                                    ]
                                    delegate: RowLayout {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: 3
                                        Text {
                                            text: modelData.icon
                                            font.family: "Material Symbols Rounded"
                                            font.variableAxes: ({
                                                    "FILL": 1
                                                })
                                            renderType: Text.NativeRendering
                                            font.pixelSize: 13
                                            color: MatugenColors.md3.primary
                                            opacity: 0.75
                                        }
                                        Text {
                                            visible: (modelData.windIcon ?? "") !== ""
                                            text: modelData.windIcon ?? ""
                                            font.family: "MesloLGL Nerd Font Mono"
                                            font.pixelSize: 14
                                            color: MatugenColors.md3.primary
                                            opacity: 0.68
                                        }
                                        Text {
                                            text: modelData.label
                                            Layout.fillWidth: true
                                            font.pixelSize: 12
                                            color: MatugenColors.md3.on_surface
                                            opacity: 0.50
                                            elide: Text.ElideNone
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignVCenter
                            visible: !WeatherService.hasData
                            Text {
                                anchors.centerIn: parent
                                text: WeatherService.loading
                                    ? Localization.t("dashboard.overview.weather.fetching", "Fetching weather...")
                                    : Localization.t("dashboard.overview.weather.noData", "No weather data")
                                font.pixelSize: 13
                                color: MatugenColors.md3.on_surface
                                opacity: 0.35
                            }
                        }
                    }
                }

                Item {
                    id: weatherForecastRollout
                    Layout.fillWidth: true
                    implicitHeight: 22
                    visible: WeatherService.hasData
                    z: 100

                    readonly property int toggleHeight: 22
                    readonly property int hourlyHeight: 84
                    readonly property int dailyToggleHeight: 20
                    readonly property int dailyHeight: 88
                    readonly property int expandedContentHeight: root.win.weatherHourlyOpen ? hourlyHeight + dailyToggleHeight + (root.win.weatherDailyOpen ? dailyHeight : 0) : 0
                    property real curtainHeight: toggleHeight + expandedContentHeight
                    Behavior on curtainHeight {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        visible: weatherForecastRollout.curtainHeight > weatherForecastRollout.toggleHeight
                        x: 0
                        y: 0
                        width: parent.width
                        height: weatherForecastRollout.curtainHeight - weatherForecastRollout.toggleHeight
                        clip: true
                        color: MatugenColors.md3.surface_container_high

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onWheel: function (wheel) {
                                wheel.accepted = true;
                            }
                        }

                        Item {
                            width: parent.width
                            height: weatherForecastRollout.expandedContentHeight

                            Item {
                                id: hourlyForecastRow
                                width: parent.width
                                height: weatherForecastRollout.hourlyHeight

                                Item {
                                    id: hourlyLeftHints
                                    anchors {
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 4
                                    }
                                    width: 28
                                    height: 18
                                    z: 10
                                    opacity: root.win.tabHintMode ? 1.0 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        Text {
                                            text: "←"
                                            font.pixelSize: 10
                                            color: MatugenColors.md3.on_surface
                                            opacity: 0.55
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Rectangle {
                                            width: 14
                                            height: 14
                                            radius: 3
                                            color: MatugenColors.md3.primary
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Y"
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: MatugenColors.md3.on_primary
                                            }
                                        }
                                    }
                                }

                                Item {
                                    id: hourlyRightHints
                                    anchors {
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        rightMargin: 4
                                    }
                                    width: 28
                                    height: 18
                                    z: 10
                                    opacity: root.win.tabHintMode ? 1.0 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        Rectangle {
                                            width: 14
                                            height: 14
                                            radius: 3
                                            color: MatugenColors.md3.primary
                                            Text {
                                                anchors.centerIn: parent
                                                text: "E"
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: MatugenColors.md3.on_primary
                                            }
                                        }
                                        Text {
                                            text: "→"
                                            font.pixelSize: 10
                                            color: MatugenColors.md3.on_surface
                                            opacity: 0.55
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                Flickable {
                                    id: _hourlyFlickable
                                    anchors.fill: parent
                                    contentWidth: WeatherService.hourlySlots.length * 74
                                    contentHeight: height
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    function scrollBy(delta) {
                                        const maxX = Math.max(0, contentWidth - width);
                                        hourlyScrollAnimation.stop();
                                        hourlyScrollAnimation.to = Math.max(0, Math.min(maxX, contentX + delta));
                                        hourlyScrollAnimation.start();
                                    }

                                    function resetScroll() {
                                        hourlyScrollAnimation.stop();
                                        contentX = 0;
                                    }

                                    NumberAnimation {
                                        id: hourlyScrollAnimation
                                        target: _hourlyFlickable
                                        property: "contentX"
                                        duration: 180
                                        easing.type: Easing.OutCubic
                                    }

                                    Row {
                                        height: parent.height
                                        Repeater {
                                            model: WeatherService.hourlySlots
                                            delegate: Item {
                                                required property var modelData
                                                required property int index
                                                width: 74
                                                height: parent.height
                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: modelData.time
                                                        font.pixelSize: 11
                                                        color: MatugenColors.md3.on_surface
                                                        opacity: index === 0 ? 0.85 : 0.45
                                                        font.bold: index === 0
                                                    }
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: WeatherService.iconFromCode(modelData.code)
                                                        font.family: "Material Symbols Rounded"
                                                        font.pixelSize: 26
                                                        color: MatugenColors.md3.primary
                                                        opacity: index === 0 ? 1.0 : 0.65
                                                    }
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        text: modelData.temp + "°"
                                                        font.pixelSize: 13
                                                        font.bold: true
                                                        color: MatugenColors.md3.on_surface
                                                        opacity: index === 0 ? 0.90 : 0.60
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: weatherForecastRollout.dailyToggleHeight
                                y: hourlyForecastRow.height

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    height: 1
                                    color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.93)
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 16
                                    radius: 4
                                    color: MatugenColors.md3.surface_container_high
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 13
                                        font.variableAxes: ({
                                                "FILL": 1
                                            })
                                        renderType: Text.NativeRendering
                                        color: MatugenColors.md3.on_surface
                                        opacity: wDailyToggle.containsMouse ? 0.75 : 0.35
                                        text: root.win.weatherDailyOpen ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 100
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 14
                                    radius: 3
                                    color: MatugenColors.md3.primary
                                    opacity: root.win.tabHintMode ? 1.0 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.win.weatherDailyOpen ? "A" : "H"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: MatugenColors.md3.on_primary
                                    }
                                }
                                MouseArea {
                                    id: wDailyToggle
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.win.weatherDailyOpen = !root.win.weatherDailyOpen
                                        root.win.tabHintMode = false
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: weatherForecastRollout.dailyHeight
                                y: hourlyForecastRow.height + weatherForecastRollout.dailyToggleHeight
                                visible: root.win.weatherDailyOpen
                                Row {
                                    anchors.fill: parent
                                    Repeater {
                                        model: WeatherService.dailySlots
                                        delegate: Item {
                                            required property var modelData
                                            width: parent.width / WeatherService.dailySlots.length
                                            height: parent.height
                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: _calendarWidget.shortWeekdayName(new Date(modelData.date + "T12:00:00").getDay())
                                                    font.pixelSize: 11
                                                    color: MatugenColors.md3.on_surface
                                                    opacity: 0.45
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: WeatherService.iconFromCode(modelData.code)
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: 24
                                                    color: MatugenColors.md3.primary
                                                    opacity: 0.80
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.max + "°"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: MatugenColors.md3.on_surface
                                                    opacity: 0.75
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.min + "°"
                                                    font.pixelSize: 11
                                                    color: MatugenColors.md3.on_surface
                                                    opacity: 0.38
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: weatherHourlyToggle
                        width: parent.width
                        height: weatherForecastRollout.toggleHeight
                        y: weatherForecastRollout.curtainHeight - weatherForecastRollout.toggleHeight
                        z: 10
                        Rectangle {
                            anchors.fill: parent
                            color: MatugenColors.md3.surface_container_high
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 1
                            color: ColorUtils.transparentize(MatugenColors.md3.outline, 0.90)
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 18
                            radius: 4
                            color: MatugenColors.md3.surface_container_high
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 15
                                font.variableAxes: ({
                                        "FILL": 1
                                    })
                                renderType: Text.NativeRendering
                                color: MatugenColors.md3.on_surface
                                opacity: wHourlyToggle.containsMouse ? 0.75 : 0.40
                                text: root.win.weatherHourlyOpen ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 100
                                    }
                                }
                            }
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 4
                            width: 14
                            height: 14
                            radius: 3
                            color: MatugenColors.md3.primary
                            opacity: root.win.tabHintMode ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: root.win.weatherHourlyOpen ? "A" : "H"
                                font.pixelSize: 9
                                font.bold: true
                                color: MatugenColors.md3.on_primary
                            }
                        }
                        MouseArea {
                            id: wHourlyToggle
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.win.weatherHourlyOpen = !root.win.weatherHourlyOpen;
                                if (!root.win.weatherHourlyOpen)
                                    root.win.weatherDailyOpen = false;
                                root.win.tabHintMode = false;
                            }
                        }
                    }
                }
            }

            SectionDivider {}

            DashboardSection {
                win: root.win
                icon: "calendar_today"
                label: Localization.t("dashboard.overview.sections.calendar", "Calendar")

                Item {
                    id: _calendarWidget
                    Layout.fillWidth: true
                    implicitHeight: calCol.implicitHeight + 16
                    property int monthOffset: 0

                    readonly property var _now: new Date()
                    readonly property int _todayY: _now.getFullYear()
                    readonly property int _todayM: _now.getMonth()
                    readonly property int _todayD: _now.getDate()

                    readonly property int viewYear: {
                        const d = new Date(_todayY, _todayM + monthOffset, 1);
                        return d.getFullYear();
                    }
                    readonly property int viewMonth: {
                        const d = new Date(_todayY, _todayM + monthOffset, 1);
                        return d.getMonth();
                    }
                    readonly property string monthLabel: Localization.t("dashboard.overview.calendar.months." + viewMonth, Qt.formatDate(new Date(viewYear, viewMonth, 1), "MMMM")) + " " + viewYear
                    readonly property int firstDayOfWeek: Math.max(0, Math.min(6, Settings.calendarFirstDayOfWeek))
                    readonly property var weekdayLabels: {
                        const labels = [
                            shortWeekdayName(0),
                            shortWeekdayName(1),
                            shortWeekdayName(2),
                            shortWeekdayName(3),
                            shortWeekdayName(4),
                            shortWeekdayName(5),
                            shortWeekdayName(6)
                        ];
                        const ordered = [];
                        for (let i = 0; i < 7; i++)
                            ordered.push(labels[(firstDayOfWeek + i) % 7]);
                        return ordered;
                    }

                    readonly property var cells: {
                        const firstDay = new Date(viewYear, viewMonth, 1).getDay();
                        const lead = (firstDay - firstDayOfWeek + 7) % 7;
                        const days = new Date(viewYear, viewMonth + 1, 0).getDate();
                        const arr = [];
                        for (let i = 0; i < lead; i++)
                            arr.push(0);
                        for (let d = 1; d <= days; d++)
                            arr.push(d);
                        while (arr.length < 42)
                            arr.push(0);
                        return arr;
                    }

                    function shortWeekdayName(day) {
                        return Localization.t("dashboard.overview.calendar.weekdays.short." + day, Qt.formatDate(new Date(2026, 1, 1 + day), "ddd"))
                    }

                    ColumnLayout {
                        id: calCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: 8
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Item {
                                implicitWidth: 28
                                implicitHeight: 28
                                Text {
                                    anchors.centerIn: parent
                                    text: "chevron_left"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 18
                                    font.variableAxes: ({
                                            "FILL": 1
                                        })
                                    renderType: Text.NativeRendering
                                    color: MatugenColors.md3.on_surface
                                    opacity: prevHover.containsMouse ? 0.80 : 0.40
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 80
                                        }
                                    }
                                }
                                MouseArea {
                                    id: prevHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        _calendarWidget.monthOffset--
                                        root.win.tabHintMode = false
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    width: 13
                                    height: 13
                                    radius: 3
                                    z: 1
                                    color: MatugenColors.md3.primary
                                    opacity: root.win.tabHintMode ? 1.0 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "P"
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: MatugenColors.md3.on_primary
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: _calendarWidget.monthLabel
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: MatugenColors.md3.on_surface
                                opacity: 0.80
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Item {
                                implicitWidth: 28
                                implicitHeight: 28
                                Text {
                                    anchors.centerIn: parent
                                    text: "chevron_right"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 18
                                    font.variableAxes: ({
                                            "FILL": 1
                                        })
                                    renderType: Text.NativeRendering
                                    color: MatugenColors.md3.on_surface
                                    opacity: nextHover.containsMouse ? 0.80 : 0.40
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 80
                                        }
                                    }
                                }
                                MouseArea {
                                    id: nextHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        _calendarWidget.monthOffset++
                                        root.win.tabHintMode = false
                                    }
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    width: 13
                                    height: 13
                                    radius: 3
                                    z: 1
                                    color: MatugenColors.md3.primary
                                    opacity: root.win.tabHintMode ? 1.0 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 120
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "N"
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: MatugenColors.md3.on_primary
                                    }
                                }
                            }
                        }

                        Grid {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 0
                            columnSpacing: 0
                            Repeater {
                                model: _calendarWidget.weekdayLabels
                                delegate: Item {
                                    required property string modelData
                                    width: calCol.width / 7
                                    height: 22
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 11
                                        color: MatugenColors.md3.on_surface
                                        opacity: 0.30
                                    }
                                }
                            }
                        }

                        Grid {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 0
                            Repeater {
                                model: _calendarWidget.cells
                                delegate: Item {
                                    required property int modelData
                                    required property int index

                                    readonly property bool isToday: modelData > 0 && _calendarWidget.viewYear === _calendarWidget._todayY && _calendarWidget.viewMonth === _calendarWidget._todayM && modelData === _calendarWidget._todayD
                                    readonly property bool isSameDayOfMonth: modelData > 0 && !isToday && modelData === _calendarWidget._todayD
                                    readonly property int weekday: (_calendarWidget.firstDayOfWeek + (index % 7)) % 7
                                    readonly property bool isWeekend: weekday === 0 || weekday === 6

                                    width: calCol.width / 7
                                    height: 28

                                    Rectangle {
                                        visible: isToday || isSameDayOfMonth
                                        anchors.centerIn: parent
                                        width: isToday ? 24 : 22
                                        height: width
                                        radius: 6
                                        color: isToday ? ColorUtils.transparentize(MatugenColors.md3.primary, 0.72) : ColorUtils.transparentize(MatugenColors.md3.primary, 0.88)
                                        border.width: isToday ? 1 : 0
                                        border.color: ColorUtils.transparentize(MatugenColors.md3.primary, 0.42)
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData > 0 ? modelData : ""
                                        font.pixelSize: 13
                                        font.weight: isToday ? Font.DemiBold : Font.Normal
                                        color: (isToday || isSameDayOfMonth) ? MatugenColors.md3.primary : isWeekend ? ColorUtils.transparentize(MatugenColors.md3.on_surface, 0.35) : MatugenColors.md3.on_surface
                                        opacity: isToday ? 0.92 : isSameDayOfMonth ? 0.72 : isWeekend ? 0.55 : 0.70
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                implicitHeight: 4
            }
        }
    }
}
