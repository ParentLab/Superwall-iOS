//
//  InternalPaywallPresentation.swift
//  Paywall
//
//  Created by Yusuf Tör on 04/03/2022.
//

import UIKit

extension Paywall {
  // swiftlint:disable:next function_body_length cyclomatic_complexity
  static func internallyPresent(
    _ presentationInfo: PresentationInfo,
    on presentingViewController: UIViewController? = nil,
    products: PaywallProducts? = nil,
    cached: Bool = true,
    ignoreSubscriptionStatus: Bool = false,
    presentationStyleOverride: PaywallPresentationStyle = .none,
    onPresent: ((PaywallInfo?) -> Void)? = nil,
    onDismiss: PaywallDismissalCompletionBlock? = nil,
    onSkip: ((NSError) -> Void)? = nil
  ) {
    let presentationStyleOverride = presentationStyleOverride == .none ? nil : presentationStyleOverride
    if TriggerDelayManager.shared.hasDelay {
      let trigger = PreConfigTrigger(
        presentationInfo: presentationInfo,
        presentationStyleOverride: presentationStyleOverride,
        viewController: presentingViewController,
        ignoreSubscriptionStatus: ignoreSubscriptionStatus,
        onFail: onSkip,
        onPresent: onPresent,
        onDismiss: onDismiss
      )
      TriggerDelayManager.shared.cachePreConfigTrigger(trigger)
      return
    }

    let eventData = presentationInfo.eventData
    let debugInfo: [String: Any] = [
      "on": presentingViewController.debugDescription,
      "fromEvent": eventData.debugDescription as Any,
      "cached": cached,
      "presentationCompletion": onPresent.debugDescription,
      "dismissalCompletion": onDismiss.debugDescription,
      "fallback": onSkip.debugDescription
    ]

    Logger.debug(
      logLevel: .debug,
      scope: .paywallPresentation,
      message: "Called Paywall.present",
      info: debugInfo
    )

    if SWDebugManager.shared.isDebuggerLaunched {
      // if the debugger is launched, ensure the viewcontroller is the debugger
      guard presentingViewController is SWDebugViewController else {
        return
      }
    }

    let triggerOutcome = PaywallResponseLogic.getTriggerResultAndConfirmAssignment(
      presentationInfo: presentationInfo,
      triggers: ConfigManager.shared.triggers
    )
    let identifiers: ResponseIdentifiers

    switch triggerOutcome.info {
    case .paywall(let responseIdentifiers):
      identifiers = responseIdentifiers
    case let .holdout(error),
      let .noRuleMatch(error):
      SessionEventsManager.shared.triggerSession.activateSession(
        for: presentationInfo,
        on: presentingViewController,
        triggerResult: triggerOutcome.result
      )
      fallthrough
    case let .unknownEvent(error):
      Logger.debug(
        logLevel: .error,
        scope: .paywallPresentation,
        message: "Error Getting Paywall View Controller",
        info: debugInfo,
        error: error
      )
      onSkip?(error)
      return
    }

    PaywallManager.shared.getPaywallViewController(
      from: eventData,
      responseIdentifiers: identifiers,
      substituteProducts: products,
      cached: cached && !SWDebugManager.shared.isDebuggerLaunched
    ) { result in
      // if there's a paywall being presented, don't do anything
      if shared.isPaywallPresented {
        Logger.debug(
          logLevel: .error,
          scope: .paywallPresentation,
          message: "Paywall Already Presented",
          info: ["message": "Paywall.shared.isPaywallPresented is true"]
        )
        return
      }

      switch result {
      case .success(let paywallViewController):
        if InternalPresentationLogic.shouldNotDisplayPaywall(
          isUserSubscribed: shared.isUserSubscribed,
          isDebuggerLaunched: SWDebugManager.shared.isDebuggerLaunched,
          shouldIgnoreSubscriptionStatus: ignoreSubscriptionStatus,
          presentationCondition: paywallViewController.paywallResponse.presentationCondition
        ) {
          onSkip?(
            shared.presentationError(
              domain: "SWPresentationError",
              code: 0,
              title: "Should not display paywall",
              value: "Should not display paywall."
            )
          )
          return
        }

        SessionEventsManager.shared.triggerSession.activateSession(
          for: presentationInfo,
          on: presentingViewController,
          paywallResponse: paywallViewController.paywallResponse,
          triggerResult: triggerOutcome.result
        )

        if presentingViewController == nil {
          shared.createPresentingWindowIfNeeded()
        }

        // Make sure there's a presenter. If there isn't throw an error if no paywall is being presented
        guard let presenter = (presentingViewController ?? shared.presentingWindow?.rootViewController) else {
          Logger.debug(
            logLevel: .error,
            scope: .paywallPresentation,
            message: "No Presentor to Present Paywall",
            info: debugInfo,
            error: nil
          )
          if !shared.isPaywallPresented {
            onSkip?(
              shared.presentationError(
                domain: "SWPresentationError",
                code: 101,
                title: "No UIViewController to present paywall on",
                value: "This usually happens when you call this method before a window was made key and visible."
              )
            )
          }
          return
        }

        paywallViewController.present(
          on: presenter,
          presentationInfo: presentationInfo,
          presentationStyleOverride: presentationStyleOverride,
          dismissalBlock: onDismiss
        ) { success in
          if success {
            self.presentAgain = {
              if let presentingPaywallIdentifier = paywallViewController.paywallResponse.identifier {
                PaywallManager.shared.removePaywall(withIdentifier: presentingPaywallIdentifier)
              }
              internallyPresent(
                presentationInfo,
                on: presentingViewController,
                cached: false,
                presentationStyleOverride: presentationStyleOverride ?? .none,
                onPresent: onPresent,
                onDismiss: onDismiss,
                onSkip: onSkip
              )
            }
            onPresent?(paywallViewController.paywallInfo)
          } else {
            Logger.debug(
              logLevel: .info,
              scope: .paywallPresentation,
              message: "Paywall Already Presented",
              info: debugInfo
            )
          }
        }
      case .failure(let error):
        if InternalPresentationLogic.shouldNotDisplayPaywall(
          isUserSubscribed: shared.isUserSubscribed,
          isDebuggerLaunched: SWDebugManager.shared.isDebuggerLaunched,
          shouldIgnoreSubscriptionStatus: ignoreSubscriptionStatus
        ) {
          return
        }

        Logger.debug(
          logLevel: .error,
          scope: .paywallPresentation,
          message: "Error Getting Paywall View Controller",
          info: debugInfo,
          error: error
        )
        onSkip?(error)
      }
    }
  }

  func presentationError(
    domain: String,
    code: Int,
    title: String,
    value: String
  ) -> NSError {
    let userInfo: [String: Any] = [
      NSLocalizedDescriptionKey: NSLocalizedString(title, value: value, comment: "")
    ]
    return NSError(
      domain: domain,
      code: code,
      userInfo: userInfo
    )
  }

  func dismiss(
    _ paywallViewController: SWPaywallViewController,
    state: PaywallDismissalResult.DismissState,
    completion: (() -> Void)? = nil
  ) {
    onMain {
      let paywallInfo = paywallViewController.paywallInfo
      paywallViewController.dismiss(
        .withResult(
          paywallInfo: paywallInfo,
          state: state
        )
      ) {
        completion?()
      }
    }
  }

  private func createPresentingWindowIfNeeded() {
    if presentingWindow == nil {
      let activeWindow = UIApplication.shared.activeWindow

      if #available(iOS 13.0, *) {
        if let windowScene = activeWindow?.windowScene {
          presentingWindow = UIWindow(windowScene: windowScene)
        }
      } else {
        presentingWindow = UIWindow(frame: activeWindow?.bounds ?? UIScreen.main.bounds)
      }

      presentingWindow?.rootViewController = UIViewController()
      presentingWindow?.windowLevel = .normal
      presentingWindow?.makeKeyAndVisible()
    }
  }

  func destroyPresentingWindow() {
    presentingWindow?.isHidden = true
    presentingWindow = nil
  }
}
