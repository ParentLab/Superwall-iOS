//
//  File.swift
//  
//
//  Created by Yusuf Tör on 26/09/2022.
//
// swiftlint:disable strict_fileprivate

import UIKit
import Combine

struct PresentablePipelineOutput {
  let request: PaywallPresentationRequest
  let debugInfo: DebugInfo
  let paywallViewController: SWPaywallViewController
  let presenter: UIViewController
}

extension AnyPublisher where Output == PaywallVcPipelineOutput, Failure == Error {
  func checkPaywallIsPresentable(
    _ paywallStatePublisher: PassthroughSubject<PaywallState, Never>
  ) -> AnyPublisher<PresentablePipelineOutput, Error> {
    mainMap { input in
      if InternalPresentationLogic.shouldNotDisplayPaywall(
        isUserSubscribed: Paywall.shared.isUserSubscribed,
        isDebuggerLaunched: SWDebugManager.shared.isDebuggerLaunched,
        shouldIgnoreSubscriptionStatus: input.request.paywallOverrides?.ignoreSubscriptionStatus,
        presentationCondition: input.paywallViewController.paywallResponse.presentationCondition
      ) {
        throw PresentationPipelineError.cancelled
      }

      SessionEventsManager.shared.triggerSession.activateSession(
        for: input.request.presentationInfo,
        on: input.request.presentingViewController,
        paywallResponse: input.paywallViewController.paywallResponse,
        triggerResult: input.triggerOutcome.result
      )

      if input.request.presentingViewController == nil {
        Paywall.shared.createPresentingWindowIfNeeded()
      }

      // Make sure there's a presenter. If there isn't throw an error if no paywall is being presented
      let providedViewController = input.request.presentingViewController
      let rootViewController = Paywall.shared.presentingWindow?.rootViewController

      guard let presenter = (providedViewController ?? rootViewController) else {
        Logger.debug(
          logLevel: .error,
          scope: .paywallPresentation,
          message: "No Presentor to Present Paywall",
          info: input.debugInfo,
          error: nil
        )
        if !Paywall.shared.isPaywallPresented {
          let error = InternalPresentationLogic.presentationError(
            domain: "SWPresentationError",
            code: 101,
            title: "No UIViewController to present paywall on",
            value: "This usually happens when you call this method before a window was made key and visible."
          )
          let state: PaywallState = .skipped(.error(error))
          paywallStatePublisher.send(state)
          paywallStatePublisher.send(completion: .finished)
        }
        throw PresentationPipelineError.cancelled
      }

      return PresentablePipelineOutput(
        request: input.request,
        debugInfo: input.debugInfo,
        paywallViewController: input.paywallViewController,
        presenter: presenter
      )
    }
    .eraseToAnyPublisher()
  }
}

extension Paywall {
  fileprivate func createPresentingWindowIfNeeded() {
    guard presentingWindow == nil else {
      return
    }
    let activeWindow = UIApplication.shared.activeWindow

    if let windowScene = activeWindow?.windowScene {
      presentingWindow = UIWindow(windowScene: windowScene)
    }

    presentingWindow?.rootViewController = UIViewController()
    presentingWindow?.windowLevel = .normal
    presentingWindow?.makeKeyAndVisible()
  }
}
