//
//  Tests.swift
//  Tests
//
//  Created by cem.olcay on 16/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import XCTest
@testable import RBEditorViewController

class Tests: XCTestCase {

  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
}

 // MARK: - History

extension Tests {

  func testHistory() {
    let data = RBProjectData(name: "Test")
    let history = RBHistory(dataRef: data)
    history.limit = 5

    // Test push & limit

    history.push()
    XCTAssertEqual(history.cursor, 0)
    XCTAssertEqual(history.stack.count, 1)

    let state1 = RBHistoryItem(
      rhythmData: [
        RBRhythmData(position: 0, duration: 1)
      ],
      duration: 1)
    data.rhythm = state1.rhythmData
    data.duration = state1.duration
    history.push()
    XCTAssertEqual(history.cursor, 1)
    XCTAssertEqual(history.stack.count, 2)

    let state2 = RBHistoryItem(
      rhythmData:  [
           RBRhythmData(position: 0, duration: 1),
           RBRhythmData(position: 1, duration: 1),
         ],
      duration: 2)
    data.rhythm = state2.rhythmData
    data.duration = state2.duration
    history.push()
    XCTAssertEqual(history.cursor, 2)
    XCTAssertEqual(history.stack.count, 3)

    let state3 = RBHistoryItem(
      rhythmData: [
        RBRhythmData(position: 0, duration: 1),
        RBRhythmData(position: 1, duration: 1),
        RBRhythmData(position: 2, duration: 1),
      ],
      duration: 3)
    data.rhythm = state3.rhythmData
    data.duration = 3
    history.push()
    XCTAssertEqual(history.cursor, 3)
    XCTAssertEqual(history.stack.count, 4)

    let state4 = RBHistoryItem(
      rhythmData: [
        RBRhythmData(position: 0, duration: 1),
        RBRhythmData(position: 1, duration: 1),
        RBRhythmData(position: 2, duration: 1),
        RBRhythmData(position: 3, duration: 1),
      ],
      duration: 4)
    data.rhythm = state4.rhythmData
    data.duration = state4.duration
    history.push()
    XCTAssertEqual(history.cursor, 4)
    XCTAssertEqual(history.stack.count, 5)

    let state5 = RBHistoryItem(
      rhythmData: [
        RBRhythmData(position: 0, duration: 1),
        RBRhythmData(position: 1, duration: 1),
        RBRhythmData(position: 2, duration: 1),
        RBRhythmData(position: 3, duration: 1),
        RBRhythmData(position: 4, duration: 1),
      ],
      duration: 5)
    data.rhythm = state5.rhythmData
    data.duration = state5.duration
    history.push()
    XCTAssertEqual(history.cursor, 4)
    XCTAssertEqual(history.stack.count, 5)

    let state6 = RBHistoryItem(
      rhythmData: [
        RBRhythmData(position: 0, duration: 1),
        RBRhythmData(position: 1, duration: 1),
        RBRhythmData(position: 2, duration: 1),
        RBRhythmData(position: 3, duration: 1),
        RBRhythmData(position: 4, duration: 1),
        RBRhythmData(position: 5, duration: 1),
      ],
      duration: 6)
    data.rhythm = state6.rhythmData
    data.duration = state6.duration
    history.push()
    XCTAssertEqual(history.cursor, 4)
    XCTAssertEqual(history.stack.count, 5)

    // Test undo
    XCTAssertEqual(history.canRedo, false)
    XCTAssertEqual(history.undo(), state5)
    XCTAssertEqual(history.cursor, 3)
    XCTAssertEqual(history.stack.count, 5)

    XCTAssertEqual(history.undo(), state4)
    XCTAssertEqual(history.cursor, 2)
    XCTAssertEqual(history.stack.count, 5)

    XCTAssertEqual(history.undo(), state3)
    XCTAssertEqual(history.cursor, 1)
    XCTAssertEqual(history.stack.count, 5)

    XCTAssertEqual(history.undo(), state2)
    XCTAssertEqual(history.cursor, 0)
    XCTAssertEqual(history.stack.count, 5)

    XCTAssertEqual(history.canUndo, false)
    XCTAssertEqual(history.undo(), nil)
    XCTAssertEqual(history.cursor, 0)
    XCTAssertEqual(history.stack.count, 5)

    // Test redo
    XCTAssertEqual(history.canRedo, true)
    XCTAssertEqual(history.redo(), state3)
    XCTAssertEqual(history.cursor, 1)
    XCTAssertEqual(history.stack.count, 5)

    XCTAssertEqual(history.redo(), state4)
    XCTAssertEqual(history.cursor, 2)
    XCTAssertEqual(history.stack.count, 5)

    XCTAssertEqual(history.redo(), state5)
    XCTAssertEqual(history.cursor, 3)
    XCTAssertEqual(history.stack.count, 5)

    XCTAssertEqual(history.redo(), state6)
    XCTAssertEqual(history.cursor, 4)
    XCTAssertEqual(history.stack.count, 5)

    XCTAssertEqual(history.canRedo, false)
    XCTAssertEqual(history.redo(), nil)
    XCTAssertEqual(history.cursor, 4)
    XCTAssertEqual(history.stack.count, 5)

    // Test new timeline
    XCTAssertEqual(history.undo(), state5)
    XCTAssertEqual(history.undo(), state4)

    let newState = RBHistoryItem(
      rhythmData: [
        RBRhythmData(position: 0, duration: 0),
        RBRhythmData(position: 10, duration: 0),
      ],
      duration: 0)
    data.rhythm = newState.rhythmData
    data.duration = newState.duration
    history.push()

    XCTAssertEqual(history.cursor, 3)
    XCTAssertEqual(history.stack.count, 4)
    XCTAssertEqual(history.canRedo, false)
  }
}
