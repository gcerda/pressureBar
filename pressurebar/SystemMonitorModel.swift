import Foundation
import Combine

@MainActor
final class SystemMonitorModel: ObservableObject {
    @Published var snapshot: SystemSnapshot
    @Published var refreshInterval: Double {
        didSet {
            restartService()
        }
    }

    private let service: SystemStatsService

    init(snapshot: SystemSnapshot, refreshInterval: Double = 3.0, startService: Bool = true) {
        self.snapshot = snapshot
        self.refreshInterval = refreshInterval
        self.service = SystemStatsService()

        if startService {
            restartService()
        }
    }

    convenience init() {
        self.init(snapshot: .placeholder)
    }

    var refreshIntervalText: String {
        "\(Int(refreshInterval)) s"
    }

    private func restartService() {
        service.start(interval: refreshInterval) { [weak self] snapshot in
            DispatchQueue.main.async {
                self?.snapshot = snapshot
            }
        }
    }
}
