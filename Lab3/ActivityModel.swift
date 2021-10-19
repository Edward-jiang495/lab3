//
//  ActivityModel.swift
//  Lab3
//
//  Created by Nathan Gage on 10/19/21.
//

import Foundation
import CoreMotion

class ActivityModel {
    static let shared = ActivityModel()

    // MARK: Pedometer
    let pedometer = CMPedometer()

    var yesterdayStepListener: ((Float) -> ()) = { _ in }
    var yesterdaySteps: Float = 0 {
        didSet
        {
            print(yesterdaySteps)
            yesterdayStepListener(yesterdaySteps)
        }
    }

    var todayStepListener: ((Float) -> ()) = { _ in }
    var todaySteps: Float = 0 {
        didSet
        {
            print(todaySteps)
            todayStepListener(todaySteps)
        }
    }

    var goal: Int = 0

    init() {
        goal = UserDefaults.standard.integer(forKey: "stepGoal")
    }

    func updateSteps() {
        // update today's steps
        if CMPedometer.isStepCountingAvailable() {
            let today = Calendar.current.startOfDay(for: Date())

            pedometer.startUpdates(from: today)
            { (pedData: CMPedometerData?, error: Error?) -> Void in
                if let data = pedData {
                    self.todaySteps = data.numberOfSteps.floatValue
                    print(data.numberOfSteps.floatValue)
                }
            }
        }

        // update yesterday's steps
        if CMPedometer.isStepCountingAvailable() {

            let startOfDay = Calendar.current.startOfDay(for: Date().dayBefore)
            let endOfDay = Calendar.current.startOfDay(for: Date()) - 1

            pedometer.queryPedometerData(from: startOfDay, to: endOfDay)
            { (pedData: CMPedometerData?, error: Error?) -> Void in
                if let data = pedData {
                    self.yesterdaySteps = data.numberOfSteps.floatValue
                }
            }
        }
    }

    // MARK: Activity
    let activityManager = CMMotionActivityManager()

    // can't play game cycling/driving
    enum ValidatedActivity {
        case STANDING
        case WALKING
        case RUNNING
        case INVALID
        case UNKNOWN
    }

    private var currentActivity: ValidatedActivity = ValidatedActivity.INVALID {
        didSet {
            print(currentActivity)
            activityChangeCallback()
        }
    }

    // for setting textures
    var activityIconName: String {
        switch currentActivity
        {
        case ValidatedActivity.STANDING:
            return "standing.png"
        case ValidatedActivity.WALKING:
            return "walking.png"
        case ValidatedActivity.RUNNING:
            return "running.png"
        case ValidatedActivity.INVALID:
            return "warning.png"
        default:
            return "unknown.png"
        }
    }

    // callback to update icon
    var activityChangeCallback: (() -> ()) = { } {
        didSet {
            activityChangeCallback()
        }
    }

    func getCurrentActivity() -> ValidatedActivity {
        return currentActivity
    }

    func setCurrentActivity(activity: ValidatedActivity)
    {
        if activity != currentActivity
        {
            currentActivity = activity
        }
    }
    
    func startActivityMonitoring() {
        // if active, let's start processing
        if CMMotionActivityManager.isActivityAvailable() {
            // assign updates to the main queue for activity
            self.activityManager.startActivityUpdates(to: OperationQueue.main)
            { (activity: CMMotionActivity?) -> Void in
                if let unwrappedActivity = activity {
                    if(unwrappedActivity.walking)
                    {
                        self.currentActivity = ValidatedActivity.WALKING
                    }

                    else if(unwrappedActivity.running)
                    {
                        self.currentActivity = ValidatedActivity.RUNNING
                    }

                    else if(unwrappedActivity.stationary)
                    {
                        self.currentActivity = ValidatedActivity.STANDING
                    }

                    else if(unwrappedActivity.automotive || unwrappedActivity.cycling)
                    {
                        self.currentActivity = ValidatedActivity.INVALID
                    }

                    else
                    {
                        self.currentActivity = ValidatedActivity.UNKNOWN
                    }
                }
            }
        }
    }
}

extension Date {

    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}
