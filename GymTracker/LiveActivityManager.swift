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
        print("🔍 LiveActivity: Ending rest/activity")
        
        // End all existing activities first
        let existingActivities = Activity<RestActivityAttributes>.activities
        for existingActivity in existingActivities {
            print("🔍 LiveActivity: Ending existing activity: \(existingActivity.id)")
            if #available(iOS 16.2, *) {
                let previous = existingActivity.content.state
                let finalState = RestActivityAttributes.ContentState(
                    remainingSeconds: 0,
                    exerciseName: previous.exerciseName,
                    startedAt: previous.startedAt,
                    endsAt: Date()
                )
                Task { await existingActivity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate) }
            } else {
                let previous = existingActivity.contentState
                let finalState = RestActivityAttributes.ContentState(
                    remainingSeconds: 0,
                    exerciseName: previous.exerciseName,
                    startedAt: previous.startedAt,
                    endsAt: Date()
                )
                Task { await existingActivity.end(using: finalState, dismissalPolicy: .immediate) }
            }
        }
        
        // Clear our reference
        self.activity = nil
        print("🔍 LiveActivity: All activities ended and cleared")
    }
    
    // Start a workout session Live Activity (for when app goes to background during workout)
    func startWorkoutSession(workoutLabel: String?, exerciseName: String?) async {
        print("🔍 LiveActivity: Starting workout session Live Activity")
        print("🔍 LiveActivity: Workout: \(workoutLabel ?? "nil")")
        print("🔍 LiveActivity: Current Exercise: \(exerciseName ?? "nil")")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("❌ LiveActivity: Activities not enabled in system settings")
            return 
        }
        
        // Check if there are any existing activities in the system first
        let existingActivities = Activity<RestActivityAttributes>.activities
        if !existingActivities.isEmpty {
            print("🔍 LiveActivity: Found \(existingActivities.count) existing activities")
            
            // If we already have an activity reference, just update it
            if let currentActivity = activity, existingActivities.contains(where: { $0.id == currentActivity.id }) {
                print("🔍 LiveActivity: Updating existing activity instead of creating new one")
                await updateWorkoutInfo(exerciseName: exerciseName)
                return
            }
            
            // If we have activities but no reference, end them all first
            print("🔍 LiveActivity: Ending all existing activities first")
            for existingActivity in existingActivities {
                print("🔍 LiveActivity: Ending existing activity: \(existingActivity.id)")
                if #available(iOS 16.2, *) {
                    Task { await existingActivity.end(ActivityContent(state: existingActivity.content.state, staleDate: nil), dismissalPolicy: .immediate) }
                } else {
                    Task { await existingActivity.end(using: existingActivity.contentState, dismissalPolicy: .immediate) }
                }
            }
            
            // Wait for cleanup
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        }
        
        // Check if we still have an active activity after cleanup
        if activity != nil {
            print("🔍 LiveActivity: Still have activity reference, updating instead")
            await updateWorkoutInfo(exerciseName: exerciseName)
            return
        }
        
        print("🔍 LiveActivity: Creating new activity")
        
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour default duration
        let attributes = RestActivityAttributes(workoutLabel: workoutLabel)
        let state = RestActivityAttributes.ContentState(
            remainingSeconds: 0, // 0 means no countdown, just showing workout info
            exerciseName: exerciseName ?? "Workout in Progress",
            startedAt: start,
            endsAt: end
        )
        
        print("🔍 LiveActivity: Creating workout session activity")
        
        do {
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: state, staleDate: nil)
                activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } else {
                activity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            }
            print("✅ LiveActivity: Workout session started successfully! Activity ID: \(activity?.id ?? "unknown")")
        } catch {
            print("❌ LiveActivity: Workout session start error: \(error)")
            print("❌ LiveActivity: Error details: \(error.localizedDescription)")
            
            // Don't retry if it's a visibility error - just skip
            if error.localizedDescription.contains("Target is not foreground") || error.localizedDescription.contains("visibility") {
                print("⚠️ LiveActivity: Skipping due to visibility error - app may not be in foreground")
                return
            }
        }
    }
    
    // Update existing workout Live Activity with new exercise info
    func updateWorkoutInfo(exerciseName: String?) async {
        guard let activity = activity else { return }
        
        let now = Date()
        let end = now.addingTimeInterval(3600)
        let state = RestActivityAttributes.ContentState(
            remainingSeconds: 0,
            exerciseName: exerciseName ?? "Workout in Progress",
            startedAt: now,
            endsAt: end
        )
        
        Task {
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            } else {
                await activity.update(using: state)
            }
            print("✅ LiveActivity: Updated workout info with exercise: \(exerciseName ?? "nil")")
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


