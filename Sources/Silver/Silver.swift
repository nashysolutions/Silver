//
//  Created by Rob Nash on 05/04/2019.
//  Copyright © 2019 Nash Property Solutions Ltd. All rights reserved.
//

import CloudKit

/// The state of permission
///
/// - initialState: The user has not made a decision for this application permission
/// - couldNotComplete: An error occurred when getting or setting the application permission status
/// - denied: The user has denied this application permission
/// - granted: The user has granted this application permission
public enum ApplicationPermissionStatus {
    
    case initialState, couldNotComplete(String), denied(String), granted
    
    init(_ status: CKContainer_Application_PermissionStatus, message: String? = nil) {
        switch status {
        case .initialState:
            self = .initialState
        case .couldNotComplete:
            self = .couldNotComplete(CloudError.couldNotDetermine(message))
        case .denied:
            let message = "Your device settings currently block access. Please visit the settings App and go to your AppleID page where you can navigate to the iCloud menu and select 'look me up'. Only your contacts will be able to do this."
            self = .denied(message)
        case .granted:
            self = .granted
        @unknown default:
            fatalError()
        }
    }
}

/// The status of an account
///
/// - couldNotDetermine: An error occurred when getting the account status
/// - available: The iCloud account credentials are available for this application
/// - restricted: Parental Controls / Device Management has denied access to iCloud account credentials
/// - noAccount: No iCloud account is logged in on this device
public enum AccountStatus {
    
    case couldNotDetermine(String), available, restricted(String), noAccount(String)
    
    init(_ status: CKAccountStatus, message: String? = nil) {
        switch status {
        case .couldNotDetermine:
            self = .couldNotDetermine(CloudError.couldNotDetermine(message))
        case .available:
            self = .available
        case .restricted:
            let message = "Your device settings currently block access to iCloud. This could be your parental control settings."
            self = .restricted(message)
        case .noAccount:
            let message = "In the settings App, navigate to the AppleID menu and sign-in to iCloud.\n\nIf you are already signed-in, navigate to the iCloud sub-menu and check this App is listed there as 'enabled'."
            self = .noAccount(message)
        @unknown default:
            fatalError()
        }
    }
}

public struct CurrentUser {
    
    private struct Discoverable {
        
        static func status(_ container: CloudContainer, _ completion: @escaping (CompletionResult<ApplicationPermissionStatus, CloudError>) -> Void) {
            container.status(forApplicationPermission: .userDiscoverability) { completion(parse($0, $1)) }
        }
        
        static func request(_ container: CloudContainer, _ completion: @escaping (CompletionResult<ApplicationPermissionStatus, CloudError>) -> Void) {
            container.requestApplicationPermission(.userDiscoverability) { completion(parse($0, $1)) }
        }
        
        private static var parse: (CKContainer_Application_PermissionStatus, Error?) -> CompletionResult<ApplicationPermissionStatus, CloudError> {
            return { status, error in
                let description = (error as? CKError)?.localizedDescription
                let error = CloudError(error)
                let status = ApplicationPermissionStatus(status, message: description)
                return CompletionResult(value: status, error: error)
            }
        }
    }
    
    public static func account(_ container: CloudContainer, _ completion: @escaping (CompletionResult<AccountStatus, CloudError>) -> Void) {
        container.accountStatus { (status, error) in
            let description = (error as? CKError)?.localizedDescription
            let status = AccountStatus(status, message: description)
            let error = CloudError(error)
            let result = CompletionResult(value: status, error: error)
            completion(result)
        }
    }
    
    public static func discoverability(_ container: CloudContainer, _ completion: @escaping (CompletionResult<ApplicationPermissionStatus, CloudError>) -> Void) {
        Discoverable.status(container) { (result) in
            if case .success(let status) = result {
                if case .initialState = status {
                    Discoverable.request(container, completion)
                    return
                }
            }
            completion(result)
        }
    }
}

public enum CloudError: Error {
    
    case networkFailure(String, Int)
    case serviceUnavailable(String, Int)
    case incompatibleVersion(String)
    case notAuthenticated(String)
    case permissionFailure
    case operationCancelled(String)
    case requestRateLimited(String, Int)
    case userDeletedZone
    case zoneBusy(Int)
    case zoneNotFound
    case serverResponseLost(String)
    case changeTokenExpired
    case unexpected(String)
    
    init?(_ error: Error?) {
        guard let error = (error as? CKError) else {
            return nil
        }
        self.init(error)
    }
    
    private init(_ error: CKError) {
        switch error.code {
        case .networkUnavailable:
            let package = CloudError.networkFailurePackage(error)
            let seconds = package.seconds
            let message = package.message
            self = .networkFailure(message, seconds)
        case .serviceUnavailable:
            let seconds = ErrorHelper.secondsDelay(error)
            let message = "The iCloud service is currently unavailable."
            self = .serviceUnavailable(message, seconds)
        case .networkFailure:
            let package = CloudError.networkFailurePackage(error)
            let seconds = package.seconds
            let message = package.message
            self = .networkFailure(message, seconds)
        case .notAuthenticated:
            let message = "Please sign-in to your iCloud account via the Settings app."
            self = .notAuthenticated(message)
        case .permissionFailure:
            self = .permissionFailure
        case .operationCancelled:
            let message = "iCloud quit unexpectedly. Please try again."
            self = .operationCancelled(message)
        case .incompatibleVersion:
            let message = "Please update this App via the AppStore."
            self = .incompatibleVersion(message)
        case .zoneNotFound:
            self = .zoneNotFound
        case .userDeletedZone:
            self = .userDeletedZone
        case .serverResponseLost:
            let message = "The response from iCloud was lost. Please check your signal and try again."
            self = .serverResponseLost(message)
        case .zoneBusy:
            self = .zoneBusy(ErrorHelper.secondsDelay(error))
        case .requestRateLimited:
            let message = "iCloud is under a lot of pressure at the moment."
            let seconds = ErrorHelper.secondsDelay(error)
            self = .requestRateLimited(message, seconds)
        default:
            let message = CloudError.unexpectedErrorMessage
            self = .unexpected(message)
        }
    }
    
    static func couldNotDetermine(_ message: String?) -> String {
        if let message = message {
            return message
        } else {
            return "We couldn't reach your account details and we're not sure why iCloud is failing. Please try again later."
        }
    }
    
    public static let unexpectedErrorMessage = "There was an unexpected problem. Please try again later."
    
    private static func networkFailurePackage(_ error: CKError) -> (message: String, seconds: Int) {
        let seconds = ErrorHelper.secondsDelay(error)
        let message: String
        if seconds == 0 {
            message = "Please check your signal."
        } else {
            message = "There is a problem connecting to iCloud."
        }
        return (message, seconds)
    }
}

struct ErrorHelper {
    
    static func secondsDelay(_ error: CKError) -> Int {
        let seconds: Double
        if let number = error.userInfo[CKErrorRetryAfterKey] as? NSNumber {
            seconds = number.doubleValue
        } else {
            seconds = 0
        }
        return Int(seconds.rounded(.up))
    }
}

public enum CompletionResult<T, E: Error> {
    case success(T), failure(E?)
}

public extension CompletionResult {
    init(value: T, error: E?) {
        switch (value, error) {
        case (let value, nil):
            self = .success(value)
        case (_, let error?):
            self = .failure(error)
        }
    }
}

public protocol CloudContainer {
    var publicCloudDatabase: CKDatabase { get }
    func accountStatus(completionHandler: @escaping (CKAccountStatus, Error?) -> Void)
    func status(forApplicationPermission applicationPermission: CKContainer_Application_Permissions, completionHandler: @escaping CKContainer_Application_PermissionBlock)
    func requestApplicationPermission(_ applicationPermission: CKContainer_Application_Permissions, completionHandler: @escaping CKContainer_Application_PermissionBlock)
}
