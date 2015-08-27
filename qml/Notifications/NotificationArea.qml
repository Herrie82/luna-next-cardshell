/*
 * Copyright (C) 2014 Christophe Chapuis <chris.chapuis@gmail.com>
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
import QtQml.Models 2.1

import LunaNext.Common 0.1
import LunaNext.Compositor 0.1
import LunaNext.Shell.Notifications 0.1
import LuneOS.Service 1.0

import "../Utils"

// The notification area can take three states:
//  - hidden: nothing is shown
//  - minimized: only notification icons are shown
//  - open: all notifications with their content are shown

Rectangle {
    id: notificationArea

    property QtObject compositorInstance
    property Item windowManagerInstance
    readonly property int maxDashboardWindowHeight: parent.height/2
    readonly property int dashboardCardFixedHeight: 56 // this value comes from the CSS of the dashboard cards
    readonly property int bannerNotificationFixedHeight: 24 // this value comes from the CSS of the banner

    height: 0
    color: "black"
    /* hidden by default as long as we don't any notifications */
    state: "hidden"

    NotificationManager {
        id: notificationMgr
    }

    NotificationListModel {
        id: notificationModel

        // the signal itemAdded is declared in C++, without a qmltype declaration,
        // so QML isn't able to guess the name of the signal argument.
        onItemAdded: {
            var notifObject = arguments[0];

            // Banner in all cases
            notificationArea.state = "minimized";
            freshNewItemsPopups.popupModel.append({"object" : notifObject});

            // If the notification's duration is long enough, also add it to the notification list
            if( typeof notifObject.expireTimeout !== 'undefined' && notifObject.expireTimeout > 1 )
            {
                // Sticky notification
                mergedModel.append({"notifType": "notification", "window": null, "notifObject": notifObject, "iconUrl": notifObject.iconUrl});
            }
        }
    }
    WindowModel {
        id: listDashboardsModel
        windowTypeFilter: WindowType.Dashboard

        onRowsInserted: {
            var window = listDashboardsModel.getByIndex(last);
            mergedModel.append({"notifType": "dashboard", "window": window, "notifObject": {}, "iconUrl": window.appIcon});
        }
        onRowsAboutToBeRemoved: {
            var window = listDashboardsModel.getByIndex(last);
            for( var i=0; i<mergedModel.count; ++i ) {
                if( mergedModel.get(i).window && mergedModel.get(i).window === window ) {
                    mergedModel.remove(i);
                    break;
                }
            }
        }
    }

    ListModel {
        id: mergedModel
    }

    Component {
        id: notificationItemDelegate

        NotificationItem {
            id: notificationItem

            property var notifObject: loaderNotifObject;

            signal clicked()
            signal closed()

            //height: dashboardCardFixedHeight // was : Units.gu(6)
            title: notifObject.title
            body: notifObject.body
            iconUrl: getIconUrlOrDefault(notifObject.iconUrl)

            onClicked: notificationArea.launchApplication(notifObject.launchId, notifObject.launchParams);
            onClosed: notificationMgr.closeById(notifObject.replacesId);
        }
    }
    Component {
        id: dashboardDelegate

        Item {
            id: dashboardItem

            property Item dashboardWindow: loaderWindow;

            signal clicked()
            signal closed()

            // height: dashboardCardFixedHeight
            onWidthChanged: if(dashboardWindow) dashboardWindow.changeSize(Qt.size(dashboardItem.width, dashboardItem.height));

            children: [ dashboardWindow ]

            Component.onCompleted: {
                if( dashboardWindow ) {
                    dashboardWindow.parent = dashboardItem;

                    /* This resizes only the quick item which contains the child surface but
                                             * doesn't really resize the client window */
                    dashboardWindow.anchors.fill = dashboardItem;

                    /* Resize the real client window to have the right size */
                    dashboardWindow.changeSize(Qt.size(dashboardItem.width, dashboardItem.height));
                }
            }

            onClosed: compositorInstance.closeWindowWithId(dashboardWindow.winId);
        }
    }

    function getIconUrlOrDefault(path) {
        var mypath = path.toString();
        if (mypath.length === 0)
        {
            return Qt.resolvedUrl("../images/default-app-icon.png");
        }
        
        if(mypath.slice(-1) === "/")
        {
            mypath = mypath + "icon.png"
        }
        return mypath
    }

    // Minimized view
    Row {
        id: minimizedListView

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Units.gu(1)/2
        }

        height: mergedModel.count > 0 ? Units.gu(3) : 0;

        layoutDirection: Qt.RightToLeft

        Repeater {
            model: mergedModel
            delegate: Image {
                    id: notifIconImage
                    source: getIconUrlOrDefault(iconUrl)
                    height:  minimizedListView.height
                    fillMode: Image.PreserveAspectFit
                }
        }
    }

    function minimizeNotificationArea() {
        if( notificationArea.state === "open" )
            notificationArea.state = "minimized";
    }

    MouseArea {
        anchors.fill: minimizedListView
        enabled: minimizedListView.visible
        onClicked: {
            freshNewItemsPopups.popupModel.clear();
            notificationArea.state = "open";
            windowManagerInstance.addTapAction("minimizeNotificationArea", minimizeNotificationArea, null)
        }
    }

    ListView {
        id: openListView

        visible: false
        interactive: height === maxDashboardWindowHeight
        clip: interactive
        orientation: ListView.Vertical
        cacheBuffer: maxDashboardWindowHeight
        height: Math.min(maxDashboardWindowHeight, contentHeight);
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Units.gu(1)/2
        }

        spacing: Units.gu(1) / 2
        model: mergedModel

        delegate:
            SlidingItemArea {
                id: slidingNotificationArea

                property var delegateNotifObject: typeof notifObject !== 'undefined' ? notifObject : undefined;
                property Item delegateWindow: typeof window !== 'undefined' ? window : null;
                property string delegateType: notifType;
                property int delegateIndex: index

                slidingTargetItem: notificationItemLoader

                height: notificationItemLoader.height
                width: notificationItemLoader.width

                Loader {
                    id: notificationItemLoader
                    width: notificationArea.width - Units.gu(1)
                    height: dashboardCardFixedHeight
                    anchors.verticalCenter: slidingNotificationArea.verticalCenter

                    sourceComponent: slidingNotificationArea.delegateType === "notification" ? notificationItemDelegate : dashboardDelegate
                    property var loaderNotifObject: slidingNotificationArea.delegateNotifObject
                    property Item loaderWindow: slidingNotificationArea.delegateWindow

                    signal clicked()
                    signal closed()

                    onClicked: {
                        item.clicked();
                    }
                    onClosed: {
                        item.closed();
                        mergedModel.remove(slidingNotificationArea.delegateIndex);

                        slidingNotificationArea.resetSlidingArea();
                    }
                }

                onClicked: notificationItemLoader.clicked();
                onSlidedLeft: notificationItemLoader.closed();
                onSlidedRight: notificationItemLoader.closed();

                Component.onCompleted: {
                    // avoid putting property binding
                    if( delegateType === "dashboard" ) {
                        slidingEnabled = false;  // necessary for now in order to be able to interact with the dashboard, unfortunately
                    }
                }
        }

        Behavior on height {
            NumberAnimation { duration: 150 }
        }
    }

    // Banner popup view
    NotificationTemporaryPopupArea {
        id: freshNewItemsPopups
        visible: popupModel.count>0

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Units.gu(1)/2
        }

        height: popupModel.count > 0 ? bannerNotificationFixedHeight : 0;
    }

    states: [
        State {
            name: "hidden"
            PropertyChanges { target: minimizedListView; visible: false }
            PropertyChanges { target: openListView; visible: false }
            PropertyChanges { target: notificationArea; height: freshNewItemsPopups.height }
        },
        State {
            name: "minimized"
            PropertyChanges { target: minimizedListView; visible: true }
            PropertyChanges { target: openListView; visible: false }
            PropertyChanges { target: notificationArea; height: minimizedListView.height+Units.gu(1) }
        },
        State {
            name: "open"
            PropertyChanges { target: minimizedListView; visible: false }
            PropertyChanges { target: openListView; visible: true }
            PropertyChanges { target: notificationArea; height: openListView.height+Units.gu(1) }
        }
    ]

    // have an object that surveys the count of notifications and notify the display if something interesting happens
    QtObject {
        property int count: mergedModel.count
        onCountChanged: {
            if (count === 0 && __previousCount !== 0) {
                // notify the display
                displayService.call("luna://com.palm.display/control/alert",
                                    JSON.stringify({"status": "banner-deactivated"}), undefined, onDisplayControlError)

                notificationArea.state = "hidden";
            }
            else if (count !== 0 && __previousCount === 0){
                // notify the display
                displayService.call("luna://com.palm.display/control/alert",
                                    JSON.stringify({"status": "banner-activated"}), undefined, onDisplayControlError)

                notificationArea.state = "minimized";
            }

            __previousCount = count;
        }
        function onDisplayControlError(message) {
            console.log("Failed to call display service: " + message);
        }
        property int __previousCount: 0
    }
    LunaService {
        id: displayService

        name: "org.webosports.luna"
        usePrivateBus: true
    }
}
