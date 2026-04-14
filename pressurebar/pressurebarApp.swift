//
//  pressurebarApp.swift
//  pressurebar
//
//  Created by gabriel.cerda on 14/4/26.
//

import SwiftUI

@main
struct PressureBarApp: App {
    @StateObject private var monitor = SystemMonitorModel()
    @StateObject private var launchAtLogin = LaunchAtLoginManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: monitor, launchAtLogin: launchAtLogin)
        } label: {
            MenuBarLabel(snapshot: monitor.snapshot)
        }
        .menuBarExtraStyle(.window)
    }
}
