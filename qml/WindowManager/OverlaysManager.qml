/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
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
import LunaNext 0.1

import "../Utils"

Item {
    id: overlaysManagerItem

    // a backlink to the window manager instance
    property variant windowManagerInstance

    ExtendedListModel {
        // This model contains the list of the overlays
        id: listOverlaysModel
    }

    function dumpObject(object) {
        console.log("-> Dump of " + object);
        var _property
        for (_property in object) {
          console.log( "---> " + _property + ': ' + object[_property]+'; ' );
        }
    }

    function appendOverlayWindow(window) {
        if( window.windowType === WindowType.Overlay )
        {
            listOverlaysModel.append({"overlayWindow": window});

            console.log("OverlayManager: adding " + window + " as window " + (listOverlaysModel.count-1));

            //dumpObject(window)

            if( listOverlaysModel.getIndexFromProperty("overlayWindow", window.parent) < 0 ) {
                window.parent = overlaysManagerItem;
                window.anchors.bottom = overlaysManagerItem.bottom;
                window.anchors.horizontalCenter = overlaysManagerItem.horizontalCenter;
                window.transformOrigin = Item.Bottom;
                // Scaling: try to fill the whole width, but never fill up more than half the height of the screen
                var maxScale = Math.max(1.0, overlaysManagerItem.height*0.5 / window.height);
                window.scale = Math.min(overlaysManagerItem.width / window.width, maxScale);
                // Hack to ensure the alpha channel of the window will be taken into account
                window.opacity = 0.99;

                // Add a tap action to hide the overlay
                windowManagerInstance.addTapAction("hideOverlay", __hideOverlay, window)
            }
        }
    }

    function removeOverlayWindow(window) {
        if( window.windowType === WindowType.Overlay )
        {
            var index = listOverlaysModel.getIndexFromProperty("overlayWindow", window);
            if( index >= 0 )
                listOverlaysModel.remove(index);
        }
    }

    function __hideOverlay(data) {
        // remove last overlay from the model
        //listOverlaysModel.remove(listOverlaysModel.count-1);
    }
}