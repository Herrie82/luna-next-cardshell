/*
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

LunaService {
    id: systemService

    name: "org.webosports.luna"

    property variant screenShooter

    onInitialized: {
        console.log("Starting system service ...");
        systemService.registerMethod("/", "takeScreenShot", handleTakeScreenShot);
    }

    function buildErrorResponse(message) {
        return JSON.stringify({ "returnValue": false, "errorMessage": message });
    }

    function handleTakeScreenShot(data) {
        var request = JSON.parse(data);

        if (request === null || request.file === undefined)
            return buildErrorResponse("Invalid parameters.");

        if (systemService.screenShooter == null)
            return buildErrorResponse("Internal error.");

        screenShooter.takeScreenshot(request.file);

        return JSON.stringify({"returnValue":true});
    }
}