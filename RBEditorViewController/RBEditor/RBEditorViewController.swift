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
  @IBOutlet weak var contentView: UIView?
  let actionView = RBActionView(frame: .zero)
  let toolbarView = RBToolbarView(frame: .zero)
  let patternView = RBScrollView(frame: .zero)
  let actionViewWidth: CGFloat = 80
  let toolbarHeight: CGFloat = 80

  var projectData: RBPatternData!
  var history: RBHistory!
  var mode: RBMode = .rhythm
  var selectedRhythmData: RBRhythmData?

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    contentView?.addSubview(actionView)
    actionView.translatesAutoresizingMaskIntoConstraints = false
    actionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
    actionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    actionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    actionView.widthAnchor.constraint(equalToConstant: actionViewWidth).isActive = true
    actionView.selectMode(at: mode.rawValue)
    actionView.delegate = self

    contentView?.addSubview(toolbarView)
    toolbarView.translatesAutoresizingMaskIntoConstraints = false
    toolbarView.leftAnchor.constraint(equalTo: actionView.rightAnchor).isActive = true
    toolbarView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    toolbarView.heightAnchor.constraint(equalToConstant: toolbarHeight).isActive = true
    updateToolbar()

    contentView?.addSubview(patternView)
    patternView.translatesAutoresizingMaskIntoConstraints = false
    patternView.leftAnchor.constraint(equalTo: actionView.rightAnchor).isActive = true
    patternView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    patternView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    patternView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor).isActive = true

  }

  func intialize() {
    history = RBHistory(dataRef: projectData)
    history.push()
    patternView.rbDelegate = self
    patternView.rbDataSource = self
    patternView.reloadData()
    patternView.rangeheadView.position = projectData.duration
    projectDataDidChange()
  }

  func reload() {
    self.patternView.reloadData()
    self.patternView.fixOverlaps()
    self.patternView.snapRangeheadToLastCell()
  }

  func updateToolbar() {
    switch mode {
    case .record:
      let toolbarMode = RecordToolbarMode(
        props: RecordToolbarModeProps(
          data: projectData,
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
    case .transpose:
      let toolbarMode = TransposeToolbarMode(
        props: TransposeToolbarModeProps(
          rhythmData: selectedRhythmData,
          didUpdateTransposeCallback: transposeToolbar(didUpdate:)))
      toolbarView.render(mode: toolbarMode)
    case .snapshots:
      let toolbarMode = SnapshotToolbarMode(
        props: SnapshotToolbarModeProps(
          snapshotData: projectData.snapshots,
          didPressAddButtonCallback: snapshotToolbarDidPressAddButton,
          didPressMIDICCButtonCallback: snapshotToolbarDidPressMIDICCButton,
          didSelectSnapshotAtIndex: snapshotToolbarDidSelectSnapshot(at:)))
      toolbarView.render(mode: toolbarMode)
    }
  }

  func projectDataDidChange() {}

  // MARK: RBActionViewDelegate

  func actionView(_ actionView: RBActionView, didSelect action: RBAction, sender: UIButton) {
    switch action {
    case .clear:
      selectedRhythmData = nil
      projectData.cells = []
      history.push()
      reload()
      updateToolbar()
    case .quantize:
      patternView.quantize(zoomLevel: patternView.zoomLevel)
    case .undo:
      projectData.cells = history.undo() ?? projectData.cells
      reload()
    case .redo:
      projectData.cells = history.redo() ?? projectData.cells
      reload()
    }
  }

  func actionView(_ actionView: RBActionView, didSelect mode: RBMode, sender: UIButton) {
    self.mode = mode
    updateToolbar()
  }

  // MARK: RBScrollViewDataSource

  func numberOfCells(in rbScrollView: RBScrollView) -> Int {
    return projectData.cells.count
  }

  func rbScrollView(_ rbScrollView: RBScrollView, cellAt index: Int) -> RBScrollViewCell {
    let cellData = projectData.cells[index]
    let cell = RBCell(frame: .zero)
    cell.position = cellData.position
    cell.duration = cellData.duration
    return cell
  }

  // MARK: RBScrollViewDelegate

  func rbScrollView(_ scrollView: RBScrollView, didUpdate cell: RBScrollViewCell, at index: Int) {
    projectData.cells[index].position = cell.position
    projectData.cells[index].duration = cell.duration
    projectDataDidChange()
  }

  func rbScrollView(_ scrollView: RBScrollView, didDelete cell: RBScrollViewCell, at index: Int) {
    projectData.cells.remove(at: index)
    history.push()
    projectDataDidChange()
  }

  func rbScrollView(_ scrollView: RBScrollView, didSelect cell: RBScrollViewCell, at index: Int) {
    selectedRhythmData = projectData.cells[index]
    updateToolbar()
  }

  func rbScrollViewDidUnselectCells(_ scrollView: RBScrollView) {
    selectedRhythmData = nil
    updateToolbar()
  }

  func rbScrollViewDidUpdatePlayhead(_ scrollView: RBScrollView) {

  }

  func rbScrollViewDidUpdateRangehead(_ scrollView: RBScrollView) {
    projectData.duration = scrollView.rangeheadView.position
    if mode == .record {
      updateToolbar()
    }
  }

  func rbScrollViewDidMoveCell(_ scrollView: RBScrollView) {
    history.push()
    projectDataDidChange()
  }

  func rbScrollViewDidResizeCell(_ scrollView: RBScrollView) {
    history.push()
    projectDataDidChange()
  }

  func rbScrollViewDidQuantize(_ scrollView: RBScrollView) {
    history.push()
    projectDataDidChange()
  }

  // MARK: RecordToolbarModeView

  func recordToolbarDidAddRecording() {
    patternView.reloadData()
    projectDataDidChange()
  }

  func recordToolbarDidUpdateRecording(duration: Double) {
    let index = projectData.cells.count - 1
    guard index >= 0 else { return }
    patternView.updateDurationOfCell(at: index, duration: duration)
    projectDataDidChange()
  }

  func recordToolbarDidEndRecording() {
    patternView.snapRangeheadToLastCell()
    history.push()
    updateToolbar()
    projectDataDidChange()
  }

  // MARK: RhythmToolbarModeView

  func rhythmToolbar(didAdd rhythmData: RBRhythmData) {
    rhythmData.position = patternView.rangeheadView.position
    projectData.cells.append(rhythmData)
    reload()
    history.push()
    projectDataDidChange()
  }

  func rhythmToolbar(didUpdate rhythmData: RBRhythmData) {
    reload()
    history.push()
    projectDataDidChange()
  }

  // MARK: ArpToolbarModeView

  func arpToolbar(didUpdate arp: RBArp) {
    history.push()
    reload()
    projectDataDidChange()
  }

  // MARK: VelocityToolbarModeView

  func velocityToolbar(didUpdate velocity: Int, globally: Bool) {
    if globally {
      projectData.cells.forEach({ $0.velocity = velocity })
    }
    history.push()
    projectDataDidChange()
  }

  // MARK: RatchetToolbarModeView

  func ratchetToolbar(didUpdate ratchet: RBRatchet) {
    history.push()
    reload()
    projectDataDidChange()
  }

  // MARK: TransposeToolbarModeView

  func transposeToolbar(didUpdate transpose: Int) {
    history.push()
    projectDataDidChange()
  }

  // MARK: SnapshotToolbarModeView

  func snapshotToolbarDidPressAddButton() {
    projectData.snapshot()
    updateToolbar()
  }

  func snapshotToolbarDidPressMIDICCButton() {

  }

  func snapshotToolbarDidSelectSnapshot(at index: Int) {
    guard projectData.snapshots.cells.indices.contains(index) else { return }
    projectData.cells = projectData.snapshots.cells[index].map({ $0.copy() }).compactMap({ $0 as? RBRhythmData })
    patternView.unselectCells()
    reload()
    updateToolbar()
    projectDataDidChange()
  }
}
