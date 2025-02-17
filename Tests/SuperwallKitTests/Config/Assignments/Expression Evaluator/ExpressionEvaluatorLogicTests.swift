//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/07/2022.
//

import Foundation
import XCTest
@testable import SuperwallKit

@available(iOS 14.0, *)
final class ExpressionEvaluatorLogicTests: XCTestCase {
  func testShouldFire_noMatch() {
    let dependencyContainer = DependencyContainer()
    let storage = StorageMock()
    let evaluator = ExpressionEvaluator(
      storage: storage,
      factory: dependencyContainer
    )
    let shouldFire = evaluator.shouldFire(
      forOccurrence: .stub(),
      ruleMatched: false,
      isPreemptive: false
    )
    XCTAssertFalse(shouldFire)
  }

  func testShouldFire_noOccurrenceRule() {
    let dependencyContainer = DependencyContainer()
    let storage = StorageMock()
    let evaluator = ExpressionEvaluator(
      storage: storage,
      factory: dependencyContainer
    )
    let shouldFire = evaluator.shouldFire(
      forOccurrence: nil,
      ruleMatched: true,
      isPreemptive: false
    )
    XCTAssertTrue(shouldFire)
  }

  func testShouldFire_shouldntFire_maxCountGTCount() {
    let dependencyContainer = DependencyContainer()
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 1)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)
    let evaluator = ExpressionEvaluator(
      storage: storage,
      factory: dependencyContainer
    )
    let shouldFire = evaluator.shouldFire(
      forOccurrence: .stub()
        .setting(\.maxCount, to: 1),
      ruleMatched: true,
      isPreemptive: false
    )
    XCTAssertFalse(shouldFire)
  }

  func testShouldFire_shouldFire_maxCountEqualToCount() {
    let dependencyContainer = DependencyContainer()
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 0)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)
    let evaluator = ExpressionEvaluator(
      storage: storage,
      factory: dependencyContainer
    )
    let shouldFire = evaluator.shouldFire(
      forOccurrence: .stub()
        .setting(\.maxCount, to: 1),
      ruleMatched: true,
      isPreemptive: false
    )
    XCTAssertTrue(shouldFire)
  }

  func testShouldFire_shouldFire_maxCountLtCount() {
    let dependencyContainer = DependencyContainer()
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 1)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)
    let evaluator = ExpressionEvaluator(
      storage: storage,
      factory: dependencyContainer
    )
    let shouldFire = evaluator.shouldFire(
      forOccurrence: .stub()
        .setting(\.maxCount, to: 4),
      ruleMatched: true,
      isPreemptive: false
    )
    XCTAssertTrue(shouldFire)
  }
}
