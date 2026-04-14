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

    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: monitor)
        } label: {
            MenuBarLabel(snapshot: monitor.snapshot)
        }
        .menuBarExtraStyle(.window)
    }
}
