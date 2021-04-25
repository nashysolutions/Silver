# This repository is no longer maintained

Every [CloudKit](https://developer.apple.com/icloud/cloudkit/) has a [silver lining](https://www.vocabulary.com/dictionary/silver%20lining).

# Usage

```swift
CurrentUser.account { [weak self] (result) in
    switch result {
    case .success(let status):
        DispatchQueue.main.async { self?.handle(success: status) }
    case .failure(let error):
        DispatchQueue.main.async { self?.handle(error: error) }
    }
}

func handle(success status: AccountStatus) {
    switch status {
    case .available:
    case .couldNotDetermine(let message):
    case .noAccount(let message):
    case .restricted(let message):
    }
}

func handle(error: CloudError?) {
    guard let error = error else {
        unexpected(unexpectedErrorMessage)
        return
    }
    switch error {
    case .incompatibleVersion(let message):
    case .networkFailure(let message, let seconds): // delay before retry
    case .notAuthenticated(let message):
    case .operationCancelled(let message):
    case .requestRateLimited(let message, let seconds):  // delay before retry
    case .serverResponseLost(let message):
    case .serviceUnavailable(let message, let seconds):
    default:
        unexpected(unexpectedErrorMessage)
    }
}

CurrentUser.discoverability { (result) in
    switch result {
    case .success(let status):
        DispatchQueue.main.async { self.handle(success: status) }
    case .failure(let error):
        DispatchQueue.main.async { self.handle(error: error) }
    }
}

func handle(success status: ApplicationPermissionStatus) {
    switch status {
    case .granted:
    case .couldNotComplete(let message):
    case .denied(let message):
    }
}

private func handle(error: CloudError?) {
    guard let error = error else {
        unexpected(unexpectedErrorMessage)
        return
    }
    switch error {
    case .incompatibleVersion(let message):
    case .networkFailure(let message, let seconds): // delay before retry
    case .operationCancelled(let message):
    case .requestRateLimited(let message, let seconds): // delay before retry
    case .serverResponseLost(let message):
    case .serviceUnavailable(let message, let seconds): // delay before retry
    default:
        unexpected(unexpectedErrorMessage)
    }
}
```

# Installation

List this in your `Package.swift` manifest file as a [Swift Package](https://swift.org/package-manager/) dependency. [Releases Page](https://github.com/nashysolutions/Silver/releases/).
