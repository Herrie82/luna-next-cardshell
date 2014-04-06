/*
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import LunaNext.Common 0.1
import LunaNext.Shell 0.1
import LunaNext.Compositor 0.1

import "CardView"
import "StatusBar"
import "LaunchBar"
import "WindowManager"
import "LunaSysAPI"
import "Utils" as Utils
import "Alerts"
import "Connectors"

Item {
    id: root

    Loader {
        anchors.top: root.top
        anchors.left: root.left

        width: 50
        height: 32

        // always on top of everything else!
        z: 1000

        Component {
            id: fpsTextComponent
            Text {
                color: "red"
                font.pixelSize: 20
                text: fpsCounter.fps + " fps"

                FpsCounter {
                    id: fpsCounter
                }
            }
        }

        sourceComponent: Settings.displayFps ? fpsTextComponent : null;
    }

    ScreenShooter {
        id: screenShooter

        property int nbScreenshotsTaken: 0

        function takeScreenshot(path) {
            screenShooter.capture(path);
        }
    }

    Connections {
        target: gestureAreaInstance
        onSwipeRightGesture: screenShooter.takeScreenshot();
    }

    SystemService {
        id: systemService
        screenShooter: screenShooter
        cardViewInstance: cardViewInstance
        compositorInstance: compositor
    }

    Preferences {
        id: preferences
    }

    Loader {
        id: reticleArea
        anchors.fill: parent
        source: Settings.showReticle ? "Utils/ReticleArea.qml" : ""
        z: 1000
    }

    PowerMenu {
        id: powerMenuAlert
        z: 800

        anchors.top: parent.bottom
        anchors.margins: 20

        width: parent.width * 0.6
    }

    VolumeControlAlert {
        id: volumeControlAlert
        z: 900
    }

    // The window manager manages the switch between different window modes
    //     (card, maximized, fullscreen, ...)
    // All the card related management itself is done by the CardView component
    WindowManager {
        id: windowManager

        property real screenwidth: Settings.displayWidth
        property real screenheight: Settings.displayHeight
        property real screenDPI: Settings.dpi

        focus: true
        Keys.forwardTo: [ gestureAreaInstance, launcherInstance, cardViewInstance ]

        anchors.fill: parent

        onSwitchToCardView: {
            // we're back to card view so no card should have the focus
            // for the keyboard anymore
            if( compositor )
                compositor.clearKeyboardFocus();
        }

        Item {
            id: background
            anchors.top: windowManager.top
            anchors.bottom: gestureAreaInstance.top
            anchors.left: windowManager.left
            anchors.right: windowManager.right

            z: -1; // the background item should always be behind other components

            Image {
                id: backgroundImage

                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: preferences.wallpaperFile
                asynchronous: true
                smooth: true
                sourceSize: Qt.size(Settings.displayWidth, Settings.displayHeight)
            }
        }

        CardView {
            id: cardViewInstance

            compositorInstance: compositor
            gestureAreaInstance: gestureAreaInstance
            windowManagerInstance: windowManager

            maximizedCardTopMargin: statusBarInstance.y + statusBarInstance.height

            anchors.top: windowManager.top
            anchors.bottom: gestureAreaInstance.top
            anchors.left: windowManager.left
            anchors.right: windowManager.right

            onStateChanged: {
                if( cardViewInstance.state === "cardList" ) {
                    cardViewInstance.z = 0;   // cardlist under all the rest
                }
                else if( cardViewInstance.state === "maximizedCard" ) {
                    cardViewInstance.z = 2;   // active card over justtype and launcher, under dashboard and statusbar
                }
                else {
                    cardViewInstance.z = 3;   // active card over everything
                }
            }
        }

        Launcher {
            id: launcherInstance

            gestureAreaInstance: gestureAreaInstance
            windowManagerInstance: windowManager

            anchors.top: statusBarInstance.bottom
            anchors.bottom: gestureAreaInstance.top // not sure about this one
            anchors.left: windowManager.left
            anchors.right: windowManager.right

            z: 1 // on top of cardview when no card is active
        }

        OverlaysManager {
            id: overlaysManagerInstance

            anchors.top: statusBarInstance.bottom
            anchors.bottom: gestureAreaInstance.top // not sure about this one
            anchors.left: windowManager.left
            anchors.right: windowManager.right

            z: 4 // on top of everything (including fullscreen)
        }

        StatusBar {
            id: statusBarInstance

            anchors.top: windowManager.top
            anchors.left: windowManager.left
            anchors.right: windowManager.right
            height: Units.length(24);

            z: 2 // can only be hidden by a fullscreen window

            windowManagerInstance: windowManager
            fullLauncherVisible: launcherInstance.fullLauncherVisible
            justTypeLauncherActive: launcherInstance.justTypeLauncherActive
        }

        LunaGestureArea {
            id: gestureAreaInstance

            anchors.bottom: windowManager.bottom
            anchors.left: windowManager.left
            anchors.right: windowManager.right
            height: Units.length(40);

            z: 3 // the gesture area is in front of everything, like the fullscreen window
        }
    }
}
