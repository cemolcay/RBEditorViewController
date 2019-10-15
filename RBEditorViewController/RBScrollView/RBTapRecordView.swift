//
//  RBTapRecordView.swift
//  RBScrollView
//
//  Created by cem.olcay on 11/09/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

public protocol RBTapRecordViewDelegate: class {
  func tapRecordView(_ tapRecordView: RBTapRecordView, didStartRecording position: Double)
  func tapRecordView(_ tapRecordView: RBTapRecordView, didUpdateRecording duration: Double)
  func tapRecordView(_ tapRecordView: RBTapRecordView, didEndRecording duration: Double)
  func tapRecordViewDidPressDoneButton(_ tapRecordView: RBTapRecordView)
  func tapRecordViewDidPressCancelButton(_ tapRecordView: RBTapRecordView)
}

public class RBTapRecordView: UIView {
  private var runLoop: CADisplayLink!
  public var bpm: Double = 120

  private var currentPosition: Double = 0
  private var currentDuration: Double = 0
  private var recordingStartPosition: Double = 0
  private var startTimestamp: Double = 0
  private var hasStarted: Bool = false
  private var isTouching: Bool = false

  public weak var delegate: RBTapRecordViewDelegate?

  // MARK: Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    runLoop = CADisplayLink(target: self, selector: #selector(update))
    runLoop.add(to: .main, forMode: .common)
  }

  // MARK: Lifecycle

  @objc func update() {
    guard hasStarted else { return }
    let currentTimestamp = runLoop.timestamp - startTimestamp
    currentPosition = currentTimestamp / (bpm / 60.0)

    if isTouching {
      currentDuration = currentPosition - recordingStartPosition
      delegate?.tapRecordView(self, didUpdateRecording: currentDuration)
    }
  }

  // MARK: Actions

  @IBAction func doneButtonPressed(sender: UIButton) {
    runLoop.invalidate()
    delegate?.tapRecordViewDidPressDoneButton(self)
  }

  @IBAction func cancelButtonPressed(sender: UIButton) {
    runLoop.invalidate()
    delegate?.tapRecordViewDidPressCancelButton(self)
  }

  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)

    if !hasStarted {
      hasStarted = true
      startTimestamp = runLoop.timestamp
    }

    isTouching = true
    recordingStartPosition = currentPosition
    delegate?.tapRecordView(self, didStartRecording: currentPosition)
  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    isTouching = false
    delegate?.tapRecordView(self, didEndRecording: currentDuration)
  }
}
