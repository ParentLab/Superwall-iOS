//
//  File.swift
//  
//
//  Created by Brian Anglin on 2/21/22.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import SuperwallKit

final class ExpressionEvaluatorTests: XCTestCase {
  func testExpressionMatchesAll() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expression, to: nil)
        .setting(\.expressionJs, to: nil),
      eventData: .stub(),
      isPreemptive: false
    )
    XCTAssertTrue(result)
  }

  // MARK: - Expression

  func testExpressionEvaluator_expressionTrue() async  {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes(["a": "b"])
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expression, to: "user.a == \"b\""),
      eventData: EventData(name: "ss", parameters: [:], createdAt: Date()),
      isPreemptive: false
    )
    XCTAssertTrue(result)
  }

  func testExpressionEvaluator_expressionParams() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expression, to: "params.a == \"b\""),
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date()),
      isPreemptive: false
    )
    XCTAssertTrue(result)
  }

  func testExpressionEvaluator_expressionDeviceTrue() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expression, to: "device.platform == \"iOS\""),
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date()),
      isPreemptive: false
    )
    XCTAssertTrue(result)
  }

  func testExpressionEvaluator_expressionDeviceFalse() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let result = await evaluator.evaluateExpression(
        fromRule: .stub()
          .setting(\.expression, to: "device.platform == \"Android\""),
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date()),
        isPreemptive: false
    )
    XCTAssertFalse(result)
  }

  func testExpressionEvaluator_expressionFalse() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expression, to: "a == \"b\""),
      eventData: .stub(),
      isPreemptive: false
    )
    XCTAssertFalse(result)
  }
/*
  func testExpressionEvaluator_events() {
    let triggeredEvents: [String: [EventData]] = [
      "a": [.stub()]
    ]
    let storage = StorageMock(internalTriggeredEvents: triggeredEvents)
    let result = ExpressionEvaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expression, to: "events[\"a\"][\"$count_24h\"] == 1"),
      eventData: .stub(),
      storage: storage
    )
    XCTAssertTrue(result)
  }*/

  // MARK: - ExpressionJS

  func testExpressionEvaluator_expressionJSTrue() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expressionJs, to: "function superwallEvaluator(){ return true }; superwallEvaluator"),
      eventData: .stub(),
      isPreemptive: false
    )
    XCTAssertTrue(result)
  }

  func testExpressionEvaluator_expressionJSValues_true() async {
      let dependencyContainer = DependencyContainer()
      let evaluator = ExpressionEvaluator(
        storage: dependencyContainer.storage,
        factory: dependencyContainer
      )
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expressionJs, to: "function superwallEvaluator(values) { return values.params.a ==\"b\" }; superwallEvaluator"),
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date()),
      isPreemptive: false
    )
    XCTAssertTrue(result)
  }

  func testExpressionEvaluator_expressionJSValues_false() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expressionJs, to: "function superwallEvaluator(values) { return values.params.a ==\"b\" }; superwallEvaluator"),
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date()),
      isPreemptive: false
    )
    XCTAssertTrue(result)
  }

  func testExpressionEvaluator_expressionJSNumbers() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expressionJs, to: "function superwallEvaluator(values) { return 1 == 1 }; superwallEvaluator"),
      eventData: .stub(),
      isPreemptive: false
    )
    XCTAssertTrue(result)
  }
/*
  func testExpressionEvaluator_expressionJSValues_events() {
    let triggeredEvents: [String: [EventData]] = [
      "a": [.stub()]
    ]
    let storage = StorageMock(internalTriggeredEvents: triggeredEvents)
    let result = ExpressionEvaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expressionJs, to: "function superwallEvaluator(values) { return values.events.a.$count_24h == 1 }; superwallEvaluator"),
      eventData: .stub(),
      storage: storage
    )
    XCTAssertTrue(result)
  }*/

  func testExpressionEvaluator_expressionJSEmpty() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    let result = await evaluator.evaluateExpression(
      fromRule: .stub()
        .setting(\.expressionJs, to: ""),
      eventData: .stub(),
      isPreemptive: false
    )
    XCTAssertFalse(result)
  }
}
