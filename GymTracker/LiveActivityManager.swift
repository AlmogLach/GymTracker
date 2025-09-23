import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RestActivityAttributes>?

    func startRest(durationSeconds: Int, exerciseName: String?, workoutLabel: String?) {
        print("🔍 LiveActivity: Starting rest timer with \(durationSeconds) seconds")
        print("🔍 LiveActivity: Exercise: \(exerciseName ?? "nil")")
        print("🔍 LiveActivity: Workout: \(workoutLabel ?? "nil")")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("❌ LiveActivity: Activities not enabled in system settings")
            return 
        }
        
        guard durationSeconds > 0 else { 
            print("❌ LiveActivity: Duration is 0 or negative")
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
        
        print("🔍 LiveActivity: Creating activity with attributes: \(attributes)")
        print("🔍 LiveActivity: Creating activity with state: \(state)")
        
        do {
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: state, staleDate: nil)
                activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } else {
                activity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            }
            print("✅ LiveActivity: Started successfully! Activity ID: \(activity?.id ?? "unknown")")
        } catch {
            print("❌ LiveActivity: Start error: \(error)")
            print("❌ LiveActivity: Error details: \(error.localizedDescription)")
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
    
    // Test function to manually trigger Live Activity
    func testLiveActivity() {
        print("🧪 Testing Live Activity manually...")
        startRest(durationSeconds: 30, exerciseName: "Test Exercise", workoutLabel: "Test Workout")
    }
    
    // Simple test function with minimal data
    func testSimpleLiveActivity() {
        print("🧪 Testing SIMPLE Live Activity...")
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("❌ LiveActivity: Activities not enabled in system settings")
            return 
        }
        
        let start = Date()
        let end = start.addingTimeInterval(30)
        let attributes = RestActivityAttributes(workoutLabel: "Simple Test")
        let state = RestActivityAttributes.ContentState(
            remainingSeconds: 30,
            exerciseName: "Simple Test",
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
            print("✅ SIMPLE LiveActivity: Started successfully! Activity ID: \(activity?.id ?? "unknown")")
        } catch {
            print("❌ SIMPLE LiveActivity: Start error: \(error)")
            print("❌ SIMPLE LiveActivity: Error details: \(error.localizedDescription)")
        }
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


