//
//  File.swift
//  
//
//  Created by Jake Mor on 4/29/23.
//

import Foundation

/// An enum whose cases indicate whether the paywall was closed by user
/// interaction or because another paywall will show.
@objc(SWKPaywallCloseReason)
public enum PaywallCloseReason: Int, Codable, Equatable, Sendable {
  /// The paywall was closed by system logic, either after a purchase, because
  /// a deeplink was presented, close button pressed, etc.
  case systemLogic

  /// The paywall was automatically closed becacuse another paywall will show.
  ///
  /// This prevents ``Superwall/register(event:params:handler:feature:)`` `feature`
  /// block from executing on dismiss of the paywall, because another paywall is set to show
  case forNextPaywall

  /// The paywall was closed because the webview couldn't be loaded.
  ///
  /// If this happens for a gated paywall, the ``PaywallPresentationHandler/onError(_:)``
  /// handler will be called. If it's for a non-gated paywall, the feature block will be called.
  case webViewFailedToLoad

  /// The paywall hasn't been closed yet.
  case none
}
