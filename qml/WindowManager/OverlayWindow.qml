import QtQuick 2.0
import LunaNext 0.1

Item {
    id: overlayWindowItem

    state: "hidden"
    visible: false
    anchors.top: parent.bottom

    states: [
        State {
            name: "hidden"
            AnchorChanges { target: overlayWindowItem; anchors.top: parent.bottom; anchors.bottom: undefined }
            PropertyChanges { target: overlayWindowItem; visible: false }
        },
        State {
            name: "visible"
            AnchorChanges { target: overlayWindowItem; anchors.top: undefined; anchors.bottom: parent.bottom }
            PropertyChanges { target: overlayWindowItem; visible: true }
        }
    ]

    transitions: [
        Transition {
            to: "visible"
            reversible: true

            SequentialAnimation {
                PropertyAction { target: overlayWindowItem; property: "visible" }
                AnchorAnimation { easing.type:Easing.InOutQuad;  duration: 150 }
            }
        }
    ]
}
