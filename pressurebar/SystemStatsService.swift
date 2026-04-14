import Foundation
import SwiftUI
import Darwin
import Darwin.Mach

struct SystemSnapshot: Sendable {
    enum PressureLevel: Sendable {
        case low
        case medium
        case high

        var description: String {
            switch self {
            case .low:
                "Low pressure"
            case .medium:
                "Medium pressure"
            case .high:
                "High pressure"
            }
        }

        var symbolName: String {
            switch self {
            case .low:
                "gauge.with.dots.needle.33percent"
            case .medium:
                "gauge.with.dots.needle.67percent"
            case .high:
                "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .low:
                .green
            case .medium:
                .orange
            case .high:
                .red
            }
        }
    }

    let cpuUsage: Double
    let memoryUsedBytes: UInt64
    let memoryTotalBytes: UInt64
    let availableMemoryBytes: UInt64
    let swapUsedBytes: UInt64
    let pressure: PressureLevel

    static let placeholder = SystemSnapshot(
        cpuUsage: 0,
        memoryUsedBytes: 0,
        memoryTotalBytes: ProcessInfo.processInfo.physicalMemory,
        availableMemoryBytes: ProcessInfo.processInfo.physicalMemory,
        swapUsedBytes: 0,
        pressure: .low
    )

    static let preview = SystemSnapshot(
        cpuUsage: 0.18,
        memoryUsedBytes: 12 * 1_024 * 1_024 * 1_024,
        memoryTotalBytes: 16 * 1_024 * 1_024 * 1_024,
        availableMemoryBytes: 4 * 1_024 * 1_024 * 1_024,
        swapUsedBytes: 256 * 1_024 * 1_024,
        pressure: .medium
    )

    var memoryUsage: Double {
        guard memoryTotalBytes > 0 else { return 0 }
        return Double(memoryUsedBytes) / Double(memoryTotalBytes)
    }

    var cpuText: String {
        percentText(cpuUsage)
    }

    var memoryUsageText: String {
        percentText(memoryUsage)
    }

    var memoryUsedText: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryUsedBytes), countStyle: .memory)
    }

    var availableMemoryText: String {
        ByteCountFormatter.string(fromByteCount: Int64(availableMemoryBytes), countStyle: .memory)
    }

    var swapUsedText: String {
        ByteCountFormatter.string(fromByteCount: Int64(swapUsedBytes), countStyle: .memory)
    }

    var menuBarText: String {
        "C\(compactPercent(cpuUsage)) M\(compactPercent(memoryUsage))"
    }

    private func percentText(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func compactPercent(_ value: Double) -> String {
        percentText(value)
    }
}

final class SystemStatsService {
    private struct CPUSample {
        let totalTicks: UInt64
        let idleTicks: UInt64
    }

    private let queue = DispatchQueue(label: "com.inoshi4.pressurebar.stats", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var previousSample: CPUSample?

    func start(interval: TimeInterval, handler: @escaping @Sendable (SystemSnapshot) -> Void) {
        stop()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            guard let self, let snapshot = self.collectSnapshot() else { return }
            handler(snapshot)
        }

        self.timer = timer
        timer.resume()
    }

    func stop() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
        previousSample = nil
    }

    private func collectSnapshot() -> SystemSnapshot? {
        guard let memory = memoryStats() else {
            return nil
        }

        let cpuUsage = cpuUsage()
        let pressure = pressureLevel(
            availableBytes: memory.availableBytes,
            totalBytes: memory.totalBytes,
            swapUsedBytes: memory.swapUsedBytes
        )

        return SystemSnapshot(
            cpuUsage: cpuUsage,
            memoryUsedBytes: memory.usedBytes,
            memoryTotalBytes: memory.totalBytes,
            availableMemoryBytes: memory.availableBytes,
            swapUsedBytes: memory.swapUsedBytes,
            pressure: pressure
        )
    }

    private func cpuUsage() -> Double {
        guard let sample = cpuSample() else { return 0 }
        defer { previousSample = sample }

        guard let previousSample else { return 0 }

        let totalDelta = sample.totalTicks &- previousSample.totalTicks
        let idleDelta = sample.idleTicks &- previousSample.idleTicks

        guard totalDelta > 0 else { return 0 }

        let busyDelta = totalDelta &- idleDelta
        return min(max(Double(busyDelta) / Double(totalDelta), 0), 1)
    }

    private func cpuSample() -> CPUSample? {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var cpuCount: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &cpuInfo,
            &cpuInfoCount
        )

        guard result == KERN_SUCCESS, let cpuInfo else {
            return nil
        }

        defer {
            let size = vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), size)
        }

        let stride = Int(CPU_STATE_MAX)
        var totalTicks: UInt64 = 0
        var idleTicks: UInt64 = 0

        for index in 0 ..< Int(cpuCount) {
            let offset = index * stride
            let user = UInt64(cpuInfo[offset + Int(CPU_STATE_USER)])
            let system = UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let nice = UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)])
            let idle = UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)])

            totalTicks += user + system + nice + idle
            idleTicks += idle
        }

        return CPUSample(totalTicks: totalTicks, idleTicks: idleTicks)
    }

    private func memoryStats() -> (usedBytes: UInt64, availableBytes: UInt64, totalBytes: UInt64, swapUsedBytes: UInt64)? {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let pageSize = UInt64(vm_kernel_page_size)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        let freeBytes = UInt64(stats.free_count) * pageSize
        let cachedBytes = UInt64(stats.external_page_count) * pageSize

        // Activity Monitor's "Cached Files" is much closer to reusable headroom
        // than inactive pages, so we bias availability toward free + cached.
        let availableBytes = min(totalBytes, freeBytes + cachedBytes)
        let usedBytes = totalBytes &- availableBytes
        let swapUsedBytes = currentSwapUsageBytes()

        return (usedBytes, availableBytes, totalBytes, swapUsedBytes)
    }

    private func currentSwapUsageBytes() -> UInt64 {
        var swap = xsw_usage()
        var size = MemoryLayout.size(ofValue: swap)

        let result = sysctlbyname("vm.swapusage", &swap, &size, nil, 0)
        guard result == 0 else { return 0 }

        return swap.xsu_used
    }

    private func pressureLevel(availableBytes: UInt64, totalBytes: UInt64, swapUsedBytes: UInt64) -> SystemSnapshot.PressureLevel {
        guard totalBytes > 0 else { return .low }

        let headroom = Double(availableBytes) / Double(totalBytes)
        let swapRatio = Double(swapUsedBytes) / Double(totalBytes)

        if headroom < 0.06 || (headroom < 0.10 && swapRatio > 0.5) {
            return .high
        }

        if headroom < 0.18 || (swapUsedBytes > 0 && headroom < 0.28) {
            return .medium
        }

        return .low
    }
}
