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
import LunaNext.Common 0.1
import "../Connectors"
import "Indicators"

Row {
    id: indicatorsRow

    anchors.margins: 8
    spacing: 8

    BatteryService {
        id: batteryService
    }

    TelephonyService {
        id: telephonyService
    }

    WiFiService {
        id: wifiService
    }

    FlightmodeStatusIndicator {
        id: flightmodeStatusIndicator

        name: "flightmode-status"

        anchors.top: indicatorsRow.top
        anchors.bottom: indicatorsRow.bottom

        enabled: telephonyService.offlineMode
    }

    WifiIndicator {
        id: wifiIndicator

        name: "wifi"

        anchors.top: indicatorsRow.top
        anchors.bottom: indicatorsRow.bottom

        enabled: wifiService.powered
        signalBars: wifiService.signalBars
    }

    WanStatusIndicator {
        id: wanStatusIndicator

        name: "wan-status"

        anchors.top: indicatorsRow.top
        anchors.bottom: indicatorsRow.bottom

        enabled: telephonyService.wanConnected
        technology: telephonyService.wanTechnology
    }

    TelephonySignalIndicator {
        id: telephonySignalIndicator

        name: "telephony-signal"

        anchors.top: indicatorsRow.top
        anchors.bottom: indicatorsRow.bottom

        enabled: telephonyService.online && !telephonyService.offlineMode
        strength: telephonyService.strength
    }

    BatteryIndicator {
        id: batteryIndicator

        name: "battery"

        anchors.top: indicatorsRow.top
        anchors.bottom: indicatorsRow.bottom

        level: batteryService.level
        charging: batteryService.charging
    }
}
