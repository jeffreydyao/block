//
//  BlockSessionManager.swift
//  Block
//
//  Created by [Your Name] on [Date].
//

import SwiftUI
import Combine
import ManagedSettings
import FamilyControls
import ActivityKit // If you want Live Activities

struct AlertMessage: Identifiable {
    let id = UUID()          // Allows SwiftUI to identify this alert uniquely
    let text: String         // The actual alert text
}


/// Manages the current "block session" state: starting, ending, and timers.
/// Integrates with ManagedSettings to block/unblock distracting apps.
/// Integrates with FamilyControls to show the native FamilyActivityPicker.
class BlockSessionManager: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    /// Indicates whether a block session is currently active.
    @Published var isBlocking: Bool = false
    
    /// The date/time when the block session started (used for timer calculations).
    @Published var blockStartDate: Date?
    
    /// A string for user-facing alerts (e.g., errors or confirmations).
    @Published var alertMessage: AlertMessage?
    
    // MARK: - FamilyControls Integration
    
    /// Controls whether the FamilyActivityPicker sheet is presented.
    @Published var isShowingFamilyActivityPicker: Bool = false
    
    /// The FamilyControls selection object, containing selected apps/categories.
    @Published var familyActivitySelection = FamilyActivitySelection()
    
    // MARK: - Private Properties
    
    private let nfcManager = NFCManager()
    
    /// A store for applying "shields" (blocks) on apps via ManagedSettings.
    private let store = ManagedSettingsStore()
    
    /// A repeating timer that updates once per second to refresh the block time display.
    private var timer: Timer?
    
    // Keys for persisting data in UserDefaults
    private let selectionKey = "FamilyActivitySelectionData"
    private let isBlockingKey = "BlockSessionIsActive"
    private let blockStartDateKey = "BlockSessionStartDate"
    
    // MARK: - Initialization
    
    override init() {
        super.init()

        // Load persisted FamilyActivitySelection
        loadFamilyActivitySelection()
        
        // 2. Load session state (were we blocking?)
        loadSessionState()
        
        // If the session was blocking, restore it
        if isBlocking, let start = blockStartDate {
            restoreBlockSession(from: start)
        }
    }
    
    // MARK: - Blocking Session Logic
    
    /// Called when user taps "Block distractions".
    /// Prompts NFC scanning to verify a Block tag. If valid, starts the session.
    func prepareToStartBlockSession() {
        nfcManager.beginScanning(for: .startBlock) { [weak self] success, message in
            guard let self = self else { return }
            if success {
                self.startBlockSession()
            } else {
                self.alertMessage = AlertMessage(text: message)
            }
        }
    }
    
    /// Called when user taps "Unlock".
    /// Prompts NFC scanning to verify a Block tag. If valid, ends the session.
    func prepareToEndBlockSession() {
        nfcManager.beginScanning(for: .endBlock) { [weak self] success, message in
            guard let self = self else { return }
            if success {
                self.endBlockSession()
            } else {
                self.alertMessage = AlertMessage(text: message)
            }
        }
    }
    
    /// Directly calls NFCManager to add a Brick (write the "Block" signature to an NTAG215).
    func addBrick() {
        nfcManager.beginScanning(for: .addBrick) { [weak self] success, message in
            guard let self = self else { return }
            if success {
                // Possibly show a success alert or handle completion
                self.alertMessage = AlertMessage(text: "Brick added successfully!")
            } else {
                self.alertMessage = AlertMessage(text: message)
            }
        }
    }
    
    /// Starts the block session, sets up ManagedSettings, begins a timer, etc.
    func startBlockSession() {
        isBlocking = true
        blockStartDate = Date()
        
        startTimer()
        shieldApps()        // Use ManagedSettings to block
        startLiveActivity() // Optional, if using Live Activities
        
        persistSessionState()
    }
    
    /// Ends the block session, unshields apps, stops the timer, etc.
    func endBlockSession() {
        isBlocking = false
        blockStartDate = nil
        
        stopTimer()
        unshieldApps()
        endLiveActivity()  // Optional, if using Live Activities
        
        persistSessionState()
    }
    
    /// Called at init if isBlocking was true and we have a blockStartDate
    private func restoreBlockSession(from savedDate: Date) {
        // We do NOT overwrite the blockStartDate with Date()
        // Instead, we keep the old date so the timer remains correct
        startTimer()
        shieldApps()
        startLiveActivity()
    }
    
    // MARK: - Managing "Distracting Apps"
    
    /// Called when user taps "Manage distracting apps" in Settings.
    /// We show the FamilyActivityPicker to let them choose apps/categories.
    ///
    /// The actual presentation is done from SwiftUI, e.g.:
    ///   .sheet(isPresented: $blockSessionManager.isShowingFamilyActivityPicker) {
    ///       FamilyActivityPicker(selection: $blockSessionManager.familyActivitySelection)
    ///           .onChange(of: blockSessionManager.familyActivitySelection) { _ in
    ///               blockSessionManager.storeSelectedApps()
    ///           }
    ///   }
    func manageDistractingApps() {
        isShowingFamilyActivityPicker = true
    }
    
    /// Convert the user’s chosen FamilyActivitySelection into
    /// a set of `ApplicationToken`s. These tokens represent specific apps.
    func storeSelectedApps() {
        persistFamilyActivitySelection()
    }
    
    /// Immediately ends a block session (for dev or emergency).
    /// Must remove or hide in production.
    func emergencyUnblock() {
        endBlockSession()
    }
    
    // MARK: - Persistence
    
    private func persistFamilyActivitySelection() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(familyActivitySelection)
            UserDefaults.standard.set(data, forKey: selectionKey)
        } catch {
            print("Error encoding FamilyActivitySelection: \(error)")
        }
    }
    
    private func loadFamilyActivitySelection() {
        guard let data = UserDefaults.standard.data(forKey: selectionKey) else { return }
        let decoder = JSONDecoder()
        do {
            let selection = try decoder.decode(FamilyActivitySelection.self, from: data)
            familyActivitySelection = selection
        } catch {
            print("Error decoding FamilyActivitySelection: \(error)")
        }
    }
    
    /// Persist isBlocking and blockStartDate
    private func persistSessionState() {
        UserDefaults.standard.set(isBlocking, forKey: isBlockingKey)
        
        // If blockStartDate is non-nil, store it as a TimeInterval
        if let start = blockStartDate {
            UserDefaults.standard.set(start.timeIntervalSince1970, forKey: blockStartDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: blockStartDateKey)
        }
    }
    
    /// Load isBlocking and blockStartDate from UserDefaults
    private func loadSessionState() {
        let blocking = UserDefaults.standard.bool(forKey: isBlockingKey)
        isBlocking = blocking
        
        // If no date is saved, blockStartDate remains nil
        let timestamp = UserDefaults.standard.double(forKey: blockStartDateKey)
        if timestamp > 0 {
            blockStartDate = Date(timeIntervalSince1970: timestamp)
        }
    }
    
    // MARK: - Timer / Elapsed Time
    
    /// Returns a string in "HH:MM:SS" showing how long the block session has been active.
    /// If not blocking, returns "00:00:00".
    var blockTimerString: String {
        guard let start = blockStartDate, isBlocking else {
            return "00:00:00"
        }
        let elapsed = Int(Date().timeIntervalSince(start))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - ManagedSettings Shielding
    
    /// Shields the selected apps via ManagedSettings.
    /// For categories, see `familyActivitySelection.categoryTokens`.
    private func shieldApps() {
        // Since the final ManagedSettings API doesn't have notifications=all,
        // we can only shield the apps themselves.
        
        // 1. Set the chosen app tokens. This blocks those apps.
        store.shield.applications = familyActivitySelection.applicationTokens
        
        // 2. By default, app categories can be set to .none or .all, etc.
        //    We'll set them to .none so that only the selected apps are blocked.
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(familyActivitySelection.categoryTokens)
        // 3. There's no direct property to block all notifications.
        //    If you want to block the app entirely, it generally includes notifications from it.
    }
    
    /// Unshields all apps, removing any restrictions.
    private func unshieldApps() {
        // Clear everything from the store
        store.clearAllSettings()
        
        // Alternatively, you could individually set:
        // store.shield.applicationTokens = []
        // store.shield.applicationCategories = .none
    }
    
    // MARK: - Live Activities (Optional)
    
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Example:
        /*
        do {
            let activity = try Activity<MyAttributes>.request(
                attributes: MyAttributes(),
                contentState: MyAttributes.ContentState(elapsedSeconds: 0),
                pushType: nil
            )
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Error starting live activity: \(error)")
        }
        */
    }
    
    private func endLiveActivity() {
        /*
        Task {
            for activity in Activity<MyAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        */
    }
    
    // MARK: - Timer Helpers
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            // Update SwiftUI views once per second
            self.objectWillChange.send()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
