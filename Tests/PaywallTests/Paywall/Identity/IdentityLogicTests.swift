//
//  File.swift
//  
//
//  Created by Yusuf Tör on 29/09/2022.
//

import XCTest
@testable import Paywall

final class IdentityLogicTests: XCTestCase {
  func test_shouldGetAssignments_hasAccount_accountExistedPreStaticConfig() {
    let outcome = IdentityLogic.shouldGetAssignments(
      hasAccount: true,
      accountExistedPreStaticConfig: true,
      isFirstAppOpen: true
    )
    XCTAssertTrue(outcome)
  }

  func test_shouldGetAssignments_isAnonymous_firstAppOpen_accountExistedPreStaticConfig() {
    let outcome = IdentityLogic.shouldGetAssignments(
      hasAccount: false,
      accountExistedPreStaticConfig: true,
      isFirstAppOpen: true
    )
    XCTAssertFalse(outcome)
  }

  func test_shouldGetAssignments_hasAccount_noAccountPreStaticConfig() {
    let outcome = IdentityLogic.shouldGetAssignments(
      hasAccount: true,
      accountExistedPreStaticConfig: false,
      isFirstAppOpen: true
    )
    XCTAssertFalse(outcome)
  }

  func test_shouldGetAssignments_isAnonymous_isFirstAppOpen() {
    let outcome = IdentityLogic.shouldGetAssignments(
      hasAccount: false,
      accountExistedPreStaticConfig: false,
      isFirstAppOpen: true
    )
    XCTAssertFalse(outcome)
  }

  func test_shouldGetAssignments_isAnonymous_isNotFirstAppOpen_accountExistedPreStaticConfig() {
    let outcome = IdentityLogic.shouldGetAssignments(
      hasAccount: false,
      accountExistedPreStaticConfig: true,
      isFirstAppOpen: false
    )
    XCTAssertTrue(outcome)
  }

  func test_shouldGetAssignments_isAnonymous_isNotFirstAppOpen_noAccountPreStaticConfig() {
    let outcome = IdentityLogic.shouldGetAssignments(
      hasAccount: false,
      accountExistedPreStaticConfig: false,
      isFirstAppOpen: false
    )
    XCTAssertFalse(outcome)
  }
}
