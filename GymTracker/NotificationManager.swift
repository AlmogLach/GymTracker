import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    // MARK: - Categories & Actions
    enum ActionId: String {
        case restSkip = "REST_SKIP"
        case restStop = "REST_STOP"
        case nextExercise = "NEXT_EXERCISE"
    }

    static let restCategoryId = "REST_CATEGORY"

    private func registerCategories() {
        let skip = UNNotificationAction(identifier: ActionId.restSkip.rawValue, title: "Skip", options: [.foreground])
        let stop = UNNotificationAction(identifier: ActionId.restStop.rawValue, title: "Stop", options: [.foreground, .destructive])
        let next = UNNotificationAction(identifier: ActionId.nextExercise.rawValue, title: "Next", options: [.foreground])
        let category = UNNotificationCategory(identifier: NotificationManager.restCategoryId, actions: [skip, stop, next], intentIdentifiers: [], options: [.customDismissAction])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func scheduleRestEndNotification(after seconds: Int, exerciseName: String? = nil) {
        guard seconds > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "המנוחה הסתיימה"
        if let name = exerciseName, !name.isEmpty {
            content.body = "חזרה ל-\(name)"
        } else {
            content.body = "הגיע הזמן לחזור לאימון"
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "rest_end_notification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancelRestEndNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest_end_notification"])
    }

    // Control notification with actions (shows immediately on Lock Screen)
    func scheduleRestControlsNotification(remaining seconds: Int, exerciseName: String?) {
        let content = UNMutableNotificationContent()
        content.title = exerciseName.map { "Rest: \($0)" } ?? "Rest timer"
        content.body = seconds > 0 ? "~\(seconds) seconds remaining" : "Manage your rest"
        content.categoryIdentifier = NotificationManager.restCategoryId
        content.sound = nil
        let request = UNNotificationRequest(identifier: "rest_controls_notification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func removeRestControlsNotification() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["rest_controls_notification"])
    }

    // Bring app to foreground tap behavior
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case ActionId.restSkip.rawValue:
            NotificationCenter.default.post(name: .restSkipAction, object: nil)
        case ActionId.restStop.rawValue:
            NotificationCenter.default.post(name: .restStopAction, object: nil)
        case ActionId.nextExercise.rawValue:
            NotificationCenter.default.post(name: .nextExerciseAction, object: nil)
        default:
            break
        }
        completionHandler()
    }

    // Show banners while app is in foreground (useful for testing and visibility)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let restSkipAction = Notification.Name("rest_skip_action")
    static let restStopAction = Notification.Name("rest_stop_action")
    static let nextExerciseAction = Notification.Name("next_exercise_action")
}


