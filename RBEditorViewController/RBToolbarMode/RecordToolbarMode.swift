//
//  RecordToolbarMode.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 16/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class RecordToolbarModeProps: RBToolbarModeProps {
  var data: RBPatternData
  var rangeheadPosition: Double
  var didAddRecordingCallback: (() -> Void)?
  var didUpdateRecordingCallback: ((_ duration: Double) -> Void)?
  var didEndRecordingCallback: (() -> Void)?

  required init() {
    self.data = RBPatternData(name: "recording")
    self.rangeheadPosition = 0
  }

  init(
    data: RBPatternData = RBPatternData(name: "recording"),
    rangeheadPosition: Double = 0,
    didAddRecordingCallback: (() -> Void)?,
    didUpdateRecordingCallback: ((Double) -> Void)?,
    didEndRecordingCallback: (() -> Void)?) {
    self.data = data
    self.rangeheadPosition = rangeheadPosition
    self.didAddRecordingCallback = didAddRecordingCallback
    self.didUpdateRecordingCallback = didUpdateRecordingCallback
    self.didEndRecordingCallback = didEndRecordingCallback
  }
}

class RecordToolbarModeView: RBToolbarModeView<RecordToolbarModeProps>, RBTapRecordViewDelegate {
  var endButton = UIButton(type: .system)

  override func render() {
    super.render()
    let recordView = RBTapRecordView(frame: .zero)
    recordView.bpm = props.data.tempo.bpm
    recordView.startPosition = props.rangeheadPosition
    recordView.delegate = self

    let titleLabel = UILabel()
    titleLabel.text = "Tap to Record"
    titleLabel.textAlignment = .center
    recordView.addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.leftAnchor.constraint(equalTo: recordView.leftAnchor).isActive = true
    titleLabel.rightAnchor.constraint(equalTo: recordView.rightAnchor).isActive = true
    titleLabel.topAnchor.constraint(equalTo: recordView.topAnchor).isActive = true
    titleLabel.bottomAnchor.constraint(equalTo: recordView.bottomAnchor).isActive = true

    endButton.setTitle("End", for: .normal)
    endButton.addTarget(recordView, action: #selector(recordView.doneButtonPressed(sender:)), for: .touchUpInside)
    endButton.isHidden = true

    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    stackView.addArrangedSubview(recordView)
    stackView.addArrangedSubview(endButton)
  }

  func showEndButton() {
    UIView.animate(
      withDuration: 0.3,
      delay: 0,
      usingSpringWithDamping: 1,
      initialSpringVelocity: 0,
      options: [],
      animations: {
        self.endButton.isHidden = false
        self.stackView.layoutIfNeeded()
      },
      completion: nil)
  }

  // MARK: RBTapRecordViewDelegate

  func tapRecordView(_ tapRecordView: RBTapRecordView, didStartRecording position: Double) {
    showEndButton()
    let newCell = RBRhythmData(position: position)
    props.data.cells.append(newCell)
    props.didAddRecordingCallback?()
  }

  func tapRecordView(_ tapRecordView: RBTapRecordView, didUpdateRecording duration: Double) {
    guard let newCell = props.data.cells.last else { return }
    newCell.duration = duration
    props.didUpdateRecordingCallback?(duration)
  }

  func tapRecordView(_ tapRecordView: RBTapRecordView, didEndRecording duration: Double) {
    guard let newCell = props.data.cells.last else { return }
    newCell.duration = duration
    props.didUpdateRecordingCallback?(duration)
  }

  func tapRecordViewDidPressDoneButton(_ tapRecordView: RBTapRecordView) {
    props.didEndRecordingCallback?()
  }

  func tapRecordViewDidPressCancelButton(_ tapRecordView: RBTapRecordView) {
    return
  }
}

final class RecordToolbarMode: RBToolbarMode {
  typealias PropType = RecordToolbarModeProps
  var props = RecordToolbarModeProps()
  var toolbarTitle = "Record Rhythm"

  var view: RBToolbarModeView<RecordToolbarModeProps> {
    return RecordToolbarModeView(props: props)
  }
}
