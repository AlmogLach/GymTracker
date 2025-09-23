import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct RestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var exerciseName: String?
        var startedAt: Date
        var endsAt: Date
    }

    var workoutLabel: String?
}

@available(iOS 16.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RestActivityAttributes>?

    func startRest(durationSeconds: Int, exerciseName: String?, workoutLabel: String?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, durationSeconds > 0 else { return }
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval(durationSeconds))
        let attributes = RestActivityAttributes(workoutLabel: workoutLabel)
        let content = RestActivityAttributes.ContentState(
            remainingSeconds: durationSeconds,
            exerciseName: exerciseName,
            startedAt: start,
            endsAt: end
        )
        do {
            activity = try Activity.request(attributes: attributes, contentState: content, pushType: nil)
        } catch {
            print("LiveActivity start error: \(error)")
        }
    }

    func updateRemaining(_ seconds: Int) {
        guard let activity else { return }
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(max(0, seconds)))
        let state = RestActivityAttributes.ContentState(
            remainingSeconds: seconds,
            exerciseName: activity.contentState.exerciseName,
            startedAt: activity.contentState.startedAt,
            endsAt: end
        )
        Task { await activity.update(using: state) }
    }

    func endRest() {
        guard let activity else { return }
        Task { await activity.end(dismissalPolicy: .immediate) }
        self.activity = nil
    }
}

#else

final class LiveActivityManager {
    static let shared = LiveActivityManager(); private init() {}
    func startRest(durationSeconds: Int, exerciseName: String?, workoutLabel: String?) {}
    func updateRemaining(_ seconds: Int) {}
    func endRest() {}
}

#endif


