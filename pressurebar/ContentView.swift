//
//  ContentView.swift
//  pressurebar
//
//  Created by gabriel.cerda on 14/4/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var monitor: SystemMonitorModel
    @State private var isShowingAbout = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            metrics
            Divider()
            controls
        }
        .padding(16)
        .frame(width: 300)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PressureBar")
                    .font(.headline)

                HStack(spacing: 8) {
                    Circle()
                        .fill(monitor.snapshot.pressure.color)
                        .frame(width: 8, height: 8)

                    Text(monitor.snapshot.pressure.description)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                isShowingAbout.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isShowingAbout, arrowEdge: .top) {
                AboutView()
            }
        }
    }

    private var metrics: some View {
        VStack(alignment: .leading, spacing: 10) {
            MetricRow(title: "CPU", value: monitor.snapshot.cpuText)
            MetricRow(title: "Memory used", value: monitor.snapshot.memoryUsedText)
            MetricRow(title: "Memory usage", value: monitor.snapshot.memoryUsageText)
            MetricRow(title: "Available", value: monitor.snapshot.availableMemoryText)
            MetricRow(title: "Swap used", value: monitor.snapshot.swapUsedText)
            MetricRow(title: "Refresh", value: monitor.refreshIntervalText)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(
                "Refresh",
                selection: Binding(
                    get: { monitor.refreshInterval },
                    set: { monitor.refreshInterval = $0 }
                )
            ) {
                Text("1 s").tag(1.0)
                Text("2 s").tag(2.0)
                Text("3 s").tag(3.0)
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Quit PressureBar") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")

                Spacer()
            }
        }
    }
}

private struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}

struct MenuBarLabel: View {
    let snapshot: SystemSnapshot

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: snapshot.pressure.symbolName)
                .font(.system(size: 12, weight: .semibold))
            Text(snapshot.menuBarText)
                .monospacedDigit()
        }
    }
}

private struct AboutView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PressureBar")
                .font(.headline)

            DetailRow(title: "Version", value: "\(version) (\(build))")
            DetailRow(title: "Author", value: "Gabriel Cerdá")
            LinkRow(title: "Website", label: "www.inoshi4.com", destination: "https://www.inoshi4.com")

            Divider()

            Text("Lightweight menu bar monitor for CPU and memory pressure.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 260)
    }
}

private struct LinkRow: View {
    let title: String
    let label: String
    let destination: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let url = URL(string: destination) {
                Link(label, destination: url)
            } else {
                Text(label)
            }
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
        }
    }
}
