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

  func testHistory() {
    let data = RBPatternData()
    let history = RBHistory(dataRef: data)
    history.limit = 5

    // Test push & limit

    history.push()
    XCTAssertEqual(history.cursor, 0)
    XCTAssertEqual(history.stack.count, 1)

    let state1 = [
      RBRhythmData(position: 0, duration: 1)
    ]
    data.cells = state1
    history.push()
    XCTAssertEqual(history.cursor, 1)
    XCTAssertEqual(history.stack.count, 2)

    let state2 = [
      RBRhythmData(position: 0, duration: 1),
      RBRhythmData(position: 1, duration: 1),
    ]
    data.cells = state2
    history.push()
    XCTAssertEqual(history.cursor, 2)
    XCTAssertEqual(history.stack.count, 3)

    let state3 = [
      RBRhythmData(position: 0, duration: 1),
      RBRhythmData(position: 1, duration: 1),
      RBRhythmData(position: 2, duration: 1),
    ]
    data.cells = state3
    history.push()
    XCTAssertEqual(history.cursor, 3)
    XCTAssertEqual(history.stack.count, 4)

    let state4 = [
      RBRhythmData(position: 0, duration: 1),
      RBRhythmData(position: 1, duration: 1),
      RBRhythmData(position: 2, duration: 1),
      RBRhythmData(position: 3, duration: 1),
    ]
    data.cells = state4
    history.push()
    XCTAssertEqual(history.cursor, 4)
    XCTAssertEqual(history.stack.count, 5)

    let state5 = [
      RBRhythmData(position: 0, duration: 1),
      RBRhythmData(position: 1, duration: 1),
      RBRhythmData(position: 2, duration: 1),
      RBRhythmData(position: 3, duration: 1),
      RBRhythmData(position: 4, duration: 1),
    ]
    data.cells = state5
    history.push()
    XCTAssertEqual(history.cursor, 4)
    XCTAssertEqual(history.stack.count, 5)

    let state6 = [
      RBRhythmData(position: 0, duration: 1),
      RBRhythmData(position: 1, duration: 1),
      RBRhythmData(position: 2, duration: 1),
      RBRhythmData(position: 3, duration: 1),
      RBRhythmData(position: 4, duration: 1),
      RBRhythmData(position: 5, duration: 1),
    ]
    data.cells = state6
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

    let newState = [
      RBRhythmData(position: 0, duration: 0),
      RBRhythmData(position: 10, duration: 0),
    ]
    data.cells = newState
    history.push()

    XCTAssertEqual(history.cursor, 3)
    XCTAssertEqual(history.stack.count, 4)
    XCTAssertEqual(history.canRedo, false)
  }
}
