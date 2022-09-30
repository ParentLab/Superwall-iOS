//
//  File.swift
//
//
//  Created by Jake Mor on 11/15/21.
//

import Foundation
import UIKit

@MainActor
final class PaywallManager {
	static let shared = PaywallManager()
  var presentedViewController: SWPaywallViewController? {
    return SWPaywallViewController.cache.first { $0.isActive }
	}

  private var cache = PaywallCache()

  private init() {}

	func removePaywall(withIdentifier identifier: String?) {
    cache.removePaywall(
      withIdentifier: identifier
    )
	}

	func removePaywall(withViewController viewController: SWPaywallViewController) {
    cache.removePaywall(withViewController: viewController)
	}

	func clearCache() {
		cache.clearCache()
	}

  /// First, this gets the paywall response for a specified paywall identifier or trigger event.
  /// It then creates the paywall view controller from that response, and caches it.
  ///
  /// If no `identifier` or `event` is specified, this gets the default paywall for the user.
  ///
  /// - Parameters:
  ///   - presentationInfo: Info concerning the cause of the paywall presentation and data associated with it.
  ///   - cached: Whether or not the paywall is cached.
  ///   - completion: A completion block called with the resulting paywall view controller.
	nonisolated func getPaywallViewController(
    from request: PaywallRequest,
    cached: Bool
  ) async throws -> SWPaywallViewController {
    let response = try await PaywallResponseManager.shared.getResponse(from: request)

    return await MainActor.run {
      if cached,
        let identifier = response.identifier,
        let viewController = self.cache.getPaywall(withIdentifier: identifier) {
        // Set paywall response again incase products have been substituted into paywallResponse.
        viewController.paywallResponse = response
        return viewController
      }

      let paywallViewController = SWPaywallViewController(
        paywallResponse: response,
        delegate: Paywall.shared
      )

      if let window = UIApplication.shared.activeWindow {
        paywallViewController.view.alpha = 0.01
        window.addSubview(paywallViewController.view)
        paywallViewController.view.transform = CGAffineTransform(
          translationX: UIScreen.main.bounds.width,
          y: 0
        )
        .scaledBy(x: 0.1, y: 0.1)
      }

      return paywallViewController
    }
	}
}
