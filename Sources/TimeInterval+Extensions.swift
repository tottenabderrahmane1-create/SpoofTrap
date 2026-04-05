import Foundation

extension TimeInterval {
    func formatDuration(includeSeconds: Bool = false, useLessThanOne: Bool = false) -> String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if includeSeconds {
            if hours > 0 {
                return String(format: "%dh %dm %ds", hours, minutes, seconds)
            } else if minutes > 0 {
                return String(format: "%dm %ds", minutes, seconds)
            } else {
                return String(format: "%ds", seconds)
            }
        } else {
            if hours > 0 {
                return String(format: "%dh %dm", hours, minutes)
            } else if minutes > 0 {
                return String(format: "%dm", minutes)
            } else if useLessThanOne {
                return "< 1m"
            } else {
                return "0m"
            }
        }
    }
}
