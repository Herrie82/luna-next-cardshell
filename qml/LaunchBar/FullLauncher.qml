/*
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
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import LunaNext.Common 0.1

import "../LunaSysAPI" as LunaSysAPI


Image {
    id: fullLauncher

    property real iconSize: 64
    property real bottomMargin: 80

    function calculateAppIconHMargin(_parent, appIconWidth) {
        var nbCellsPerLine = Math.floor(_parent.width / (appIconWidth + 10));
        var remainingHSpace = _parent.width - nbCellsPerLine * appIconWidth;
        return Math.floor(remainingHSpace / nbCellsPerLine);
    }

    property real appIconWidth: iconSize*1.5
    property real appIconHMargin: calculateAppIconHMargin(fullLauncher, appIconWidth)

    property real cellWidth: appIconWidth + appIconHMargin
    property real cellHeight: iconSize + iconSize*0.4*2 // we give margin for two lines of text

    signal startLaunchApplication(string appId, string appParams)

    state: "hidden"
    visible: false
    anchors.top: parent.bottom

    source: "../images/launcher/launcher-bg.png"
    fillMode: Image.Tile

    states: [
        State {
            name: "hidden"
            AnchorChanges { target: fullLauncher; anchors.top: parent.bottom; anchors.bottom: undefined }
            PropertyChanges { target: fullLauncher; visible: false }
        },
        State {
            name: "visible"
            AnchorChanges { target: fullLauncher; anchors.top: parent.top; anchors.bottom: parent.bottom }
            PropertyChanges { target: fullLauncher; visible: true }
        }
    ]

    transitions: [
        Transition {
            to: "visible"
            reversible: true

            SequentialAnimation {
                PropertyAction { target: fullLauncher; property: "visible" }
                AnchorAnimation { easing.type:Easing.InOutQuad;  duration: 150 }
            }
        }
    ]

    ListView {
        id: tabRowList
        anchors.top: parent.top
        width: parent.width
        height: Units.gu(4)        
        orientation: ListView.Horizontal
        onCurrentIndexChanged: tabContentList.currentIndex = currentIndex
        delegate: Button {
            id: tabRowDelegate
            width: Units.gu(20)
            height: tabRowList.height
            checked: tabRowDelegate.ListView.isCurrentItem
            style: ButtonStyle {
                id: tabButtonStyle
                property string neutralButtonImage: Qt.resolvedUrl("../images/launcher/tab-bg.png");
                property string neutralButtonImagePressed: Qt.resolvedUrl("../images/launcher/tab-selected-bg.png");

                background: BorderImage {
                    property int borderSize: tabButtonStyle.control.checked ? 20 : 4
                    border { top: 20; bottom: 20; left: borderSize; right: borderSize }
                    source: tabButtonStyle.control.checked ? neutralButtonImagePressed: neutralButtonImage;
                }
                label: Text {
                    color: "white"
                    text: tabButtonStyle.control.text
                    font.family: Settings.fontStatusBar
                    font.pixelSize: tabRowDelegate.height*0.6
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            onClicked: {
                tabRowDelegate.ListView.view.currentIndex = index;
            }
            text: model.text

            // the separator on the left should only be visible if is not adjacent to a selected tab
            Image {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                source: Qt.resolvedUrl("../images/launcher/tab-divider.png");
                visible: !tabRowDelegate.ListView.isCurrentItem &&
                         tabRowDelegate.ListView.view.currentIndex !== index - 1 &&
                         index !== 0
            }
        }
        model: ListModel {
            ListElement { text: "Apps" }
            ListElement { text: "Downloads" }
            ListElement { text: "Favorites" }
            ListElement { text: "Prefs" }
        }
    }

    LunaSysAPI.ApplicationModel {
        id: commonAppsModel
    }

    ListView {
        id: tabContentList
        anchors.top: tabRowList.bottom
        anchors.bottom: parent.bottom
        anchors.bottomMargin: fullLauncher.bottomMargin
        width: fullLauncher.width
        clip: true
        orientation: ListView.Horizontal
        cacheBuffer: fullLauncher.width*tabRowList.model.count // don't destroy the delegates

        snapMode: ListView.SnapOneItem

        preferredHighlightBegin: 0
        preferredHighlightEnd: width
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 300
        onCurrentIndexChanged: tabRowList.currentIndex = currentIndex

        model: tabRowList.model

        delegate: Item {
            id: tabContentItem
            width: ListView.view.width
            height: ListView.view.height

            property string tabId: model.text

            DropArea {
                // drop area on the left side of the grid
                anchors {
                    top: parent.top; bottom: parent.bottom
                    left: parent.left
                }
                width: 0.1 * parent.width
                Timer {
                    id: turnLeftTimer
                    interval: 500; running: false; repeat: false
                    property Item draggedItem;
                    onTriggered: {
                        tabContentList.decrementCurrentIndex();
                        tabContentList.currentItem.tabChangedDuringDrag(draggedItem, true);
                    }
                }
                onEntered: {
                    turnLeftTimer.draggedItem = drag.source;
                    turnLeftTimer.start();
                }
                onExited: turnLeftTimer.stop();
            }
            DropArea {
                // drop area on the right side of the grid
                anchors {
                    top: parent.top; bottom: parent.bottom
                    right: parent.right
                }
                width: 0.1 * parent.width
                Timer {
                    id: turnRightTimer
                    interval: 500; running: false; repeat: false
                    property Item draggedItem;
                    onTriggered: {
                        tabContentList.incrementCurrentIndex();
                        tabContentList.currentItem.tabChangedDuringDrag(draggedItem, false);
                    }
                }
                onEntered: {
                    turnRightTimer.draggedItem = drag.source;
                    turnRightTimer.start();
                }
                onExited: turnRightTimer.stop();
            }
            GridView {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Units.gu(1)
                width: Math.floor(fullLauncher.width / fullLauncher.cellWidth) * fullLauncher.cellWidth
                height: parent.height

                model: DraggableAppIconDelegateModel {
                        id: draggableAppIconDelegateModel
                        // list of icons, filtered on that tab
                        model: TabApplicationModel {
                            appsModel: commonAppsModel // one app model for all tab models
                            launcherTab: tabContentItem.tabId
                            isDefaultTab: tabContentItem.tabId === "Apps" // apps without any tab indication go to the Apps tab
                        }

                        dragParent: fullLauncher
                        dragAxis: Drag.XAndYAxis
                        iconWidth: fullLauncher.appIconWidth
                        iconSize: fullLauncher.iconSize

                        onStartLaunchApplication: fullLauncher.startLaunchApplication(appId, appParams);

                        property Connections _tabChangedConnect: Connections {
                            target: tabContentItem
                            onTabChangedDuringDrag: {
                                draggedItem.createPlaceHolderAt(draggableAppIconDelegateModel, isLeftBorder ? 0 : draggableAppIconDelegateModel.count);
                            }
                        }

                        onSaveCurrentLayout: {
                                if( Settings.isTestEnvironment ) return;

                                // first, clean up the DB
                                __queryDB("del",
                                          {query:{from:"org.webosports.lunalaunchertab:1"},
                                            where: [ {prop:"tab",op:"=",val:tabContentItem.tabId} ]},
                                          function (message) {});

                                // then build up the object to save
                                var data = [];
                                for( var i=0; i<draggableAppIconDelegateModel.items.count; ++i ) {
                                    var obj = draggableAppIconDelegateModel.items.get(i);
                                    data.push({_kind: "org.webosports.lunalaunchertab:1",
                                                  pos: obj.itemsIndex,
                                                  tab:tabContentItem.tabId,
                                                  appId: obj.model.appId});
                                }

                                // and put it in the DB
                                __queryDB("put", {objects: data}, function (message) {});
                        }
                }


                cellWidth: fullLauncher.cellWidth
                cellHeight: fullLauncher.cellHeight

                moveDisplaced: Transition {
                    NumberAnimation { properties: "x, y"; duration: 200 }
                }
            }

            signal tabChangedDuringDrag(Item draggedItem, bool isLeftBorder);
        }
    }
}
