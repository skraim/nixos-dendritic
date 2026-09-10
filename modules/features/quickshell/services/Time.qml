pragma Singleton

import QtQuick
import Quickshell

Singleton {
  readonly property string time: {
    Qt.formatDateTime(clock.date, "hh:mm")
  }

  readonly property string date: {
    Qt.formatDateTime(clock.date, "MMM d")
  }

  SystemClock {
    id: clock
  }
}
