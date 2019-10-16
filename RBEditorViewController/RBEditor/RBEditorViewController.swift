//
//  RBEditorViewController.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 25/09/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class RBCell: RBScrollViewCell {

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    layer.borderColor = UIColor.black.cgColor
    layer.borderWidth = 1
    layer.backgroundColor = UIColor.lightGray.cgColor
    layer.cornerRadius = 8
    layer.masksToBounds = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.borderColor = isSelected ? UIColor.red.cgColor : UIColor.black.cgColor
  }
}

class RBEditorViewController: UIViewController, RBActionViewDelegate, RBScrollViewDataSource, RBScrollViewDelegate {
  let actionView = RBActionView(frame: .zero)
  let toolbarView = RBToolbarView(frame: .zero)
  let patternView = RBScrollView(frame: .zero)
  var mode: RBMode = .rhythm
  var selectedRhythmData: RBRhythmData?
  var data: RBPatternData = RBPatternData()
  var history: RBHistory!
  let actionViewWidth: CGFloat = 60
  let toolbarHeight: CGFloat = 60

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    // Setup history
    history = RBHistory(dataRef: data)
    history.push()

    view.addSubview(actionView)
    actionView.translatesAutoresizingMaskIntoConstraints = false
    actionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    actionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
    actionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    actionView.widthAnchor.constraint(equalToConstant: actionViewWidth).isActive = true
    actionView.selectMode(at: mode.rawValue)
    actionView.delegate = self

    view.addSubview(toolbarView)
    toolbarView.translatesAutoresizingMaskIntoConstraints = false
    toolbarView.leftAnchor.constraint(equalTo: actionView.rightAnchor).isActive = true
    toolbarView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    toolbarView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    toolbarView.heightAnchor.constraint(equalToConstant: toolbarHeight).isActive = true
    updateToolbar()

    view.addSubview(patternView)
    patternView.translatesAutoresizingMaskIntoConstraints = false
    patternView.leftAnchor.constraint(equalTo: actionView.rightAnchor).isActive = true
    patternView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    patternView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
    patternView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor).isActive = true
    patternView.rbDelegate = self
    patternView.rbDataSource = self
    patternView.reloadData()
  }

  func reload() {
//    DispatchQueue.main.async {
      self.patternView.reloadData()
      self.patternView.fixOverlaps()
      self.patternView.snapRangeheadToLastCell()
//    }
  }

  func updateToolbar() {
    switch mode {
    case .record:
      let toolbarMode = RecordToolbarMode(
        props: RecordToolbarModeProps(
          data: data,
          rangeheadPosition: patternView.rangeheadView.position,
          didAddRecordingCallback: recordToolbarDidAddRecording,
          didUpdateRecordingCallback: recordToolbarDidUpdateRecording(duration:),
          didEndRecordingCallback: recordToolbarDidEndRecording))
      toolbarView.render(mode: toolbarMode)
    case .rhythm:
      if selectedRhythmData == nil {
        let toolbarMode = RhythmToolbarMode(
          props: RhythmToolbarModeProps(
            rhythmData: nil,
            didAddRhythmCallback: rhythmToolbar(didAdd:),
            didUpdateRhythmCallback: nil))
        toolbarMode.toolbarTitle = "Add Rhythm"
        toolbarView.render(mode: toolbarMode)
      } else {
        let toolbarMode = RhythmToolbarMode(
          props: RhythmToolbarModeProps(
            rhythmData: selectedRhythmData,
            didAddRhythmCallback: nil,
            didUpdateRhythmCallback: rhythmToolbar(didUpdate:)))
            toolbarMode.toolbarTitle = "Edit Rhythm"
        toolbarView.render(mode: toolbarMode)
      }
    case .arp:
      let toolbarMode = ArpToolbarMode(
        props: ArpToolbarModeProps(
          rhythmData: selectedRhythmData,
          didUpdateArpCallback: arpToolbar(didUpdate:)))
      toolbarView.render(mode: toolbarMode)
    case .ratchet:
      let toolbarMode = RatchetToolbarMode(
        props: RatchetToolbarModeProps(
          rhythmData: selectedRhythmData,
          didUpdateRatchetCallback: ratchetToolbar(didUpdate:)))
      toolbarView.render(mode: toolbarMode)
    case .velocity:
      let toolbarMode = VelocityToolbarMode(
        props: VelocityToolbarModeProps(
          rhythmData: selectedRhythmData,
          didUpdateVelocityCallback: velocityToolbar(didUpdate:globally:)))
      toolbarView.render(mode: toolbarMode)
    case .snapshots:
      let toolbarMode = SnapshotToolbarMode(
        props: SnapshotToolbarModeProps(
          snapshotData: data.snapshots,
          didPressAddButtonCallback: snapshotToolbarDidPressAddButton,
          didPressMIDICCButtonCallback: snapshotToolbarDidPressMIDICCButton,
          didSelectSnapshotAtIndex: snapshotToolbarDidSelectSnapshot(at:)))
      toolbarView.render(mode: toolbarMode)
    }
  }

  // MARK: RBActionViewDelegate

  func actionView(_ actionView: RBActionView, didSelect action: RBAction, sender: UIButton) {
    switch action {
    case .play:
      return
    case .clear:
      selectedRhythmData = nil
      data.cells = []
      history.push()
      reload()
      updateToolbar()
    case .quantize:
      patternView.quantize(zoomLevel: patternView.zoomLevel)
    case .undo:
      data.cells = history.undo() ?? data.cells
      reload()
    case .redo:
      data.cells = history.redo() ?? data.cells
      reload()
    }
  }

  func actionView(_ actionView: RBActionView, didSelect mode: RBMode, sender: UIButton) {
    self.mode = mode
    updateToolbar()
  }

  // MARK: RBScrollViewDataSource

  func numberOfCells(in rbScrollView: RBScrollView) -> Int {
    return data.cells.count
  }

  func rbScrollView(_ rbScrollView: RBScrollView, cellAt index: Int) -> RBScrollViewCell {
    let cellData = data.cells[index]
    let cell = RBCell(frame: .zero)
    cell.position = cellData.position
    cell.duration = cellData.duration
    return cell
  }

  // MARK: RBScrollViewDelegate

  func rbScrollView(_ scrollView: RBScrollView, didUpdate cell: RBScrollViewCell, at index: Int) {
    data.cells[index].position = cell.position
    data.cells[index].duration = cell.duration
  }

  func rbScrollView(_ scrollView: RBScrollView, didDelete cell: RBScrollViewCell, at index: Int) {
    data.cells.remove(at: index)
    history.push()
  }

  func rbScrollView(_ scrollView: RBScrollView, didSelect cell: RBScrollViewCell, at index: Int) {
    selectedRhythmData = data.cells[index]
    updateToolbar()
  }

  func rbScrollViewDidUnselectCells(_ scrollView: RBScrollView) {
    selectedRhythmData = nil
    updateToolbar()
  }

  func rbScrollViewDidUpdatePlayhead(_ scrollView: RBScrollView) {

  }

  func rbScrollViewDidUpdateRangehead(_ scrollView: RBScrollView) {

  }

  func rbScrollViewDidMoveCell(_ scrollView: RBScrollView) {
    history.push()
  }

  func rbScrollViewDidResizeCell(_ scrollView: RBScrollView) {
    history.push()
  }

  func rbScrollViewDidQuantize(_ scrollView: RBScrollView) {
    history.push()
  }

  // MARK: RecordToolbarModeView

  func recordToolbarDidAddRecording() {
    patternView.reloadData()
  }

  func recordToolbarDidUpdateRecording(duration: Double) {
    let index = data.cells.count - 1
    guard index >= 0 else { return }
    patternView.updateDurationOfCell(at: index, duration: duration)
  }

  func recordToolbarDidEndRecording() {
    patternView.snapRangeheadToLastCell()
    history.push()
    updateToolbar()
  }

  // MARK: RhythmToolbarModeView

  func rhythmToolbar(didAdd rhythmData: RBRhythmData) {
    rhythmData.position = patternView.rangeheadView.position
    data.cells.append(rhythmData)
    reload()
    history.push()
  }

  func rhythmToolbar(didUpdate rhythmData: RBRhythmData) {
    reload()
    history.push()
  }

  // MARK: ArpToolbarModeView

  func arpToolbar(didUpdate arp: RBArp) {
    history.push()
    reload()
  }

  // MARK: VelocityToolbarModeView

  func velocityToolbar(didUpdate velocity: Int, globally: Bool) {
    if globally {
      data.cells.forEach({ $0.velocity = velocity })
    }
    history.push()
  }

  // MARK: RatchetToolbarModeView

  func ratchetToolbar(didUpdate ratchet: RBRatchet) {
    history.push()
    reload()
  }

  // MARK: SnapshotToolbarModeView

  func snapshotToolbarDidPressAddButton() {
    data.snapshot()
    updateToolbar()
  }

  func snapshotToolbarDidPressMIDICCButton() {

  }

  func snapshotToolbarDidSelectSnapshot(at index: Int) {
    guard data.snapshots.cells.indices.contains(index) else { return }
    data.cells = data.snapshots.cells[index].map({ $0.copy() }).compactMap({ $0 as? RBRhythmData })
    patternView.unselectCells()
    reload()
    updateToolbar()
  }
}
