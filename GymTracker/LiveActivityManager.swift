import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RestActivityAttributes>?

    func startRest(durationSeconds: Int, exerciseName: String?, workoutLabel: String?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, durationSeconds > 0 else { 
            print("LiveActivity: Activities not enabled or duration is 0")
            return 
        }
        let start = Date()
        let end = start.addingTimeInterval(TimeInterval(durationSeconds))
        let attributes = RestActivityAttributes(workoutLabel: workoutLabel)
        let state = RestActivityAttributes.ContentState(
            remainingSeconds: durationSeconds,
            exerciseName: exerciseName,
            startedAt: start,
            endsAt: end
        )
        do {
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: state, staleDate: nil)
                activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } else {
                activity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            }
            print("LiveActivity started successfully")
        } catch {
            print("LiveActivity start error: \(error)")
        }
    }

    func updateRemaining(_ seconds: Int) {
        guard let activity else { return }
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(max(0, seconds)))
        if #available(iOS 16.2, *) {
            let previous = activity.content.state
            let state = RestActivityAttributes.ContentState(
                remainingSeconds: seconds,
                exerciseName: previous.exerciseName,
                startedAt: previous.startedAt,
                endsAt: end
            )
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
        } else {
            let previous = activity.contentState
            let state = RestActivityAttributes.ContentState(
                remainingSeconds: seconds,
                exerciseName: previous.exerciseName,
                startedAt: previous.startedAt,
                endsAt: end
            )
            Task { await activity.update(using: state) }
        }
    }

    func endRest() {
        guard let activity else { return }
        if #available(iOS 16.2, *) {
            let previous = activity.content.state
            let finalState = RestActivityAttributes.ContentState(
                remainingSeconds: 0,
                exerciseName: previous.exerciseName,
                startedAt: previous.startedAt,
                endsAt: Date()
            )
            Task { await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate) }
        } else {
            let previous = activity.contentState
            let finalState = RestActivityAttributes.ContentState(
                remainingSeconds: 0,
                exerciseName: previous.exerciseName,
                startedAt: previous.startedAt,
                endsAt: Date()
            )
            Task { await activity.end(using: finalState, dismissalPolicy: .immediate) }
        }
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


