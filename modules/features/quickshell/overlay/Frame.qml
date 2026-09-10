import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.utils
import Qt5Compat.GraphicalEffects

Scope {
    Variants {
        model: Quickshell.screens

        ShellRoot {
            property var modelData
            property color black_color: "#000"
            id: shell_root

            PanelWindow {
                screen: shell_root.modelData
                color: "transparent"
                height: Globals.screenCornerRadius
                width: Globals.screenCornerRadius
                margins.left: -65

                WlrLayershell.layer: WlrLayer.Overlay

                anchors {
                    top: true
                    left: true
                }

                Item {
                    anchors.fill: parent
                    layer.enabled: true

                    Shape {
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false

                        ShapePath {
                            strokeWidth: -1
                            fillColor: Qt.rgba(shell_root.black_color.r, shell_root.black_color.g, shell_root.black_color.b, 1)

                            PathLine {
                                relativeX: Globals.screenCornerRadius
                            }

                            PathArc {
                                relativeX: -Globals.screenCornerRadius
                                relativeY: Globals.screenCornerRadius
                                radiusX: Globals.screenCornerRadius
                                radiusY: Globals.screenCornerRadius
                                direction: PathArc.Counterclockwise
                            }
                        }
                    }
                }
            }

            PanelWindow {
                screen: shell_root.modelData
                color: "transparent"
                height: Globals.screenCornerRadius
                width: Globals.screenCornerRadius
                margins.left: -65

                WlrLayershell.layer: WlrLayer.Overlay

                anchors {
                    bottom: true
                    left: true
                }

                Item {
                    anchors.fill: parent
                    layer.enabled: true

                    Shape {
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false

                        ShapePath {
                            strokeWidth: -1
                            fillColor: Qt.rgba(shell_root.black_color.r, shell_root.black_color.g, shell_root.black_color.b, 1)

                            PathArc {
                                relativeX: Globals.screenCornerRadius
                                relativeY: Globals.screenCornerRadius
                                radiusX: Globals.screenCornerRadius
                                radiusY: Globals.screenCornerRadius
                                direction: PathArc.Counterclockwise
                            }

                            PathLine {
                                relativeX: -Globals.screenCornerRadius
                                relativeY: Globals.screenCornerRadius
                            }
                        }
                    }
                }
            }

            PanelWindow {
                screen: shell_root.modelData
                color: "transparent"
                height: Globals.screenCornerRadius
                width: Globals.screenCornerRadius

                WlrLayershell.layer: WlrLayer.Overlay

                anchors {
                    bottom: true
                    right: true
                }

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 9
                        samples: 17
                        color: shell_root.black_color
                    }

                    Shape {
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false

                        ShapePath {
                            strokeWidth: -1
                            fillColor: Qt.rgba(shell_root.black_color.r, shell_root.black_color.g, shell_root.black_color.b, 1)
                            startX: Globals.screenCornerRadius

                            PathArc {
                                relativeX: -Globals.screenCornerRadius
                                relativeY: Globals.screenCornerRadius
                                radiusX: Globals.screenCornerRadius
                                radiusY: Globals.screenCornerRadius
                                direction: PathArc.Clockwise
                            }

                            PathLine {
                                relativeX: Globals.screenCornerRadius
                                relativeY: Globals.screenCornerRadius
                            }
                        }
                    }
                }
            }

            PanelWindow {
                screen: shell_root.modelData
                color: "transparent"
                height: Globals.screenCornerRadius
                width: Globals.screenCornerRadius

                WlrLayershell.layer: WlrLayer.Overlay

                anchors {
                    top: true
                    right: true
                }

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 9
                        samples: 17
                        color: shell_root.black_color
                    }

                    Shape {
                        preferredRendererType: Shape.CurveRenderer
                        enabled: false

                        ShapePath {
                            strokeWidth: -1
                            fillColor: Qt.rgba(shell_root.black_color.r, shell_root.black_color.g, shell_root.black_color.b, 1)

                            PathLine {
                                relativeX: Globals.screenCornerRadius
                            }

                            PathLine {
                                relativeX: 0
                                relativeY: Globals.screenCornerRadius
                            }

                            PathArc {
                                relativeX: -Globals.screenCornerRadius
                                relativeY: -Globals.screenCornerRadius
                                radiusX: Globals.screenCornerRadius
                                radiusY: Globals.screenCornerRadius
                                direction: PathArc.Counterclockwise
                            }
                        }
                    }
                }
            }

            // Bottom edge shadow
            PanelWindow {
                screen: shell_root.modelData
                color: "transparent"
                height: 14
                width: shell_root.modelData.width
                exclusionMode: ExclusionMode.Ignore
                margins.bottom: -4

                WlrLayershell.layer: WlrLayer.Top

                anchors {
                    bottom: true
                    left: true
                    right: true
                }

                Item {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 4
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 9
                        samples: 17
                        color: shell_root.black_color
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: MatugenColors.md3.surface
                    }
                }
            }

            // Right edge shadow
            PanelWindow {
                screen: shell_root.modelData
                color: "transparent"
                height: shell_root.modelData.height
                width: 14
                exclusionMode: ExclusionMode.Ignore
                margins.right: -4

                WlrLayershell.layer: WlrLayer.Top

                anchors {
                    top: true
                    bottom: true
                    right: true
                }

                Item {
                    anchors.bottom: parent.bottom
                    anchors.top: parent.top
                    anchors.right: parent.right
                    width: 4
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 9
                        samples: 17
                        color: shell_root.black_color
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: MatugenColors.md3.surface
                    }
                }
            }

            // Top edge shadow
            PanelWindow {
                screen: shell_root.modelData
                color: "transparent"
                height: 14
                width: shell_root.modelData.width
                exclusionMode: ExclusionMode.Ignore
                margins.top: -4

                WlrLayershell.layer: WlrLayer.Top

                anchors {
                    top: true
                    left: true
                    right: true
                }

                Item {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.right: parent.right
                    height: 4
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 0
                        radius: 9
                        samples: 17
                        color: shell_root.black_color
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: MatugenColors.md3.surface
                    }
                }
            }

        }
    }
}
