//
//  RBScrollView.swift
//  RBScrollView
//
//  Created by cem.olcay on 09/09/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

public class MeasureTextLayer: CATextLayer {

  public override init() {
    super.init()
  }

  public override init(layer: Any) {
    super.init(layer: layer)
  }

  public required init(coder aDecoder: NSCoder) {
    super.init(layer: aDecoder)
  }

  public override func draw(in ctx: CGContext) {
    let yDiff = (bounds.size.height - ((string as? NSAttributedString)?.size().height ?? fontSize)) - 3
    ctx.saveGState()
    ctx.translateBy(x: 0.0, y: yDiff)
    super.draw(in: ctx)
    ctx.restoreGState()
  }
}

public protocol RBScrollViewDataSource: class {
  func numberOfCells(in rbScrollView: RBScrollView) -> Int
  func rbScrollView(_ rbScrollView: RBScrollView, cellAt index: Int) -> RBScrollViewCell
}

public protocol RBScrollViewDelegate: class {
  func rbScrollView(_ scrollView: RBScrollView, didUpdate cell: RBScrollViewCell, at index: Int)
  func rbScrollView(_ scrollView: RBScrollView, didDelete cell: RBScrollViewCell, at index: Int)
  func rbScrollView(_ scrollView: RBScrollView, didSelect cell: RBScrollViewCell, at index: Int)
  func rbScrollViewDidUnselectCells(_ scrollView: RBScrollView)
  func rbScrollViewDidUpdatePlayhead(_ scrollView: RBScrollView)
  func rbScrollViewDidUpdateRangehead(_ scrollView: RBScrollView, withPanGesture: Bool)
  func rbScrollViewDidMoveCell(_ scrollView: RBScrollView)
  func rbScrollViewDidResizeCell(_ scrollView: RBScrollView)
  func rbScrollViewDidQuantize(_ scrollView: RBScrollView)
}

enum RBOverlapState {
  case resize
  case moveLeft
  case moveRight
}

public class RBScrollView: UIScrollView, RBScrollViewCellDelegate, RBPlayheadViewDelegate {
  public var measureBarCount: Int = 4
  public var measureCount: Int = 4
  public var measureWidth: CGFloat = 200
  public var minMeasureWidth: CGFloat = 100
  public var maxMeasureWidth: CGFloat = 300
  public var measureHeight: CGFloat = 24
  public var cellVerticalPadding: CGFloat = 8
  public var timeSignatureBeatCount: Int = 4
  public var measureLayer = CALayer()

  private var measureLabels: [MeasureTextLayer] = []
  private var measureLines: [CALayer] = []
  private var measureBottomLine = CALayer()
  private var measureBackgroundLayer = CALayer()

  public var measureLabelTextColor: UIColor = .black
  public var measureLabelTextSize: CGFloat = 13
  public var measureLineColor: UIColor = .black
  public var measureLineSize: CGFloat = 0.5
  public var measureBottomLineColor: UIColor = .black
  public var measureBottomLineSize: CGFloat = 1
  public var measureBackgroundColor: UIColor = .lightGray

  private var zoomGesture = UIPinchGestureRecognizer()
  public var zoomSpeed: CGFloat = 1.0
  public var zoomLevel: Int = 0
  public var minZoomLevel: Int = 0
  public var maxZoomLevel: Int = 2
  public var isQuantizing: Bool = false

  private var cells: [RBScrollViewCell] = []
  private var selectedCellIndex: Int?
  private var movingCellStartPosition: Double?
  private var overlapState: RBOverlapState?

  public var playheadView = RBPlayheadView(frame: .zero)
  public var rangeheadView = RBPlayheadView(frame: .zero)

  public weak var rbDataSource: RBScrollViewDataSource?
  public weak var rbDelegate: RBScrollViewDelegate?

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
    zoomGesture.addTarget(self, action: #selector(didZoom(pinch:)))
    addGestureRecognizer(zoomGesture)
    layer.addSublayer(measureLayer)
    measureLayer.addSublayer(measureBackgroundLayer)
    measureLayer.addSublayer(measureBottomLine)
    // Playhead
    addSubview(playheadView)
    playheadView.delegate = self
    playheadView.layer.zPosition = 10
    playheadView.shapeType = .playhead
    // Rangehead
    addSubview(rangeheadView)
    rangeheadView.delegate = self
    rangeheadView.layer.zPosition = 10
    rangeheadView.shapeType = .range
  }

  // MARK: Lifecycle

  public override func layoutSubviews() {
    super.layoutSubviews()

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    // Check if content size need to refresh
    let contentWidth = CGFloat(measureCount) * measureWidth
    if contentWidth < frame.size.width {
      updateMeasure()
    }

    // Draw measure background
    measureBackgroundLayer.frame = CGRect(x: 0, y: 0, width: contentSize.width, height: measureHeight)
    measureBackgroundLayer.backgroundColor = measureBackgroundColor.cgColor
    measureBottomLine.frame = CGRect(x: 0, y: measureHeight - measureBottomLineSize, width: contentSize.width, height: measureBottomLineSize)
    measureBottomLine.backgroundColor = measureBottomLineColor.cgColor

    // Draw measure lines
    guard measureLines.count == measureCount + 1, measureLabels.count == measureCount + 1
      else { updateMeasure(); setNeedsLayout(); return }

    for i in 0..<measureCount + 1 {
      let currentX = CGFloat(i) * measureWidth
      // Layout label
      let label = measureLabels[i]
      label.frame = CGRect(
        x: currentX,
        y: 0,
        width: measureWidth,
        height: measureHeight)
      // Layout line
      let line = measureLines[i]
      line.frame = CGRect(
        x: currentX,
        y: measureHeight/2,
        width: measureLineSize,
        height: frame.size.height - (measureHeight/2))
    }

    var measureBarWidth: CGFloat = 0
    switch zoomLevel {
    case 0:
      measureBarWidth = measureWidth
    case 1:
      measureBarWidth = measureWidth * CGFloat(timeSignatureBeatCount)
    default:
      measureBarWidth = measureWidth * CGFloat(timeSignatureBeatCount) * 4
    }

    // Draw cells
    for cell in cells {
      let position = CGFloat(cell.position) * measureBarWidth
      let duration = CGFloat(cell.duration) * measureBarWidth
      let height = frame.size.height - measureHeight - (cellVerticalPadding * 2)
      cell.frame = CGRect(
        x: position,
        y: measureHeight + cellVerticalPadding,
        width: duration,
        height: height)
    }

    var lastPosition: Double = 0
    if let cell = cells.last {
      lastPosition = cell.position + cell.duration
    }

    if Int(ceil(lastPosition)) > measureBarCount {
      updateMeasure()
    }

    // Playhead
    playheadView.measureHeight = measureHeight
    playheadView.lineHeight = frame.height - measureHeight
    playheadView.measureWidth = measureBarWidth
    bringSubviewToFront(playheadView)

    // Rangehead
    rangeheadView.measureHeight = measureHeight
    rangeheadView.lineHeight = frame.height - measureHeight
    rangeheadView.measureWidth = measureBarWidth
    bringSubviewToFront(rangeheadView)

    CATransaction.commit()
  }

  public func updateMeasure() {
    // Update bar count
    let minBarCountForScreen = Int(ceil(frame.size.width / measureWidth))
    let minBarCountForCells = Int(farMostCellPosition())
    measureBarCount = max(measureBarCount, max(minBarCountForScreen, minBarCountForCells))

    // Update measure count
    switch zoomLevel {
    case 0:
      measureCount = measureBarCount
    case 1:
      measureCount = measureBarCount * timeSignatureBeatCount
    default:
      measureCount = measureBarCount * timeSignatureBeatCount * 4
    }

    // Update content size
    contentSize.width = CGFloat(measureCount) * measureWidth

    let measureLabelIndicies = measureLabels.indices
    let measureLineIndicies = measureLines.indices
    var currentBar = 1
    var currentBeat = 0
    var currentSubbeat = 0

    // Update measures, add new ones if nessessary.
    for i in 0..<measureCount + 1 {
      // Determine measure Text
      var measureText = ""
      switch zoomLevel {
      case 0:
        measureText = "\(currentBar)"
        currentBar += 1
      case 1:
        measureText = "\(currentBar).\(currentBeat)"
        currentBeat += 1
        if currentBeat >= timeSignatureBeatCount {
          currentBar += 1
          currentBeat = 0
        }
      default:
        measureText = "\(currentBar).\(currentBeat).\(currentSubbeat)"
        currentSubbeat += 1
        if currentSubbeat >= 4 {
          currentSubbeat = 0
          currentBeat += 1
          if currentBeat >= timeSignatureBeatCount {
            currentBar += 1
            currentBeat = 0
          }
        }
      }

      // Add measure label if necessary.
      if measureLabelIndicies.contains(i) == false {
        let label = MeasureTextLayer()
        label.foregroundColor = measureLabelTextColor.cgColor
        label.fontSize = measureLabelTextSize
        label.contentsScale = UIScreen.main.scale
        label.alignmentMode = .left
        measureLayer.addSublayer(label)
        measureLabels.append(label)
      }

      // Update label
      let label = measureLabels[i]
      label.string = measureText

      // Add measure line if necessary.
      if measureLineIndicies.contains(i) == false {
        let line = CALayer()
        line.backgroundColor = measureLineColor.cgColor
        measureLayer.addSublayer(line)
        measureLines.append(line)
      }
    }

    // Remove extra measures
    if measureLines.count > measureCount + 1 {
      Array(measureLines.suffix(from: measureCount + 1)).forEach({ $0.removeFromSuperlayer() })
      measureLines = Array(measureLines.prefix(measureCount + 1))
    }
    if measureLabels.count > measureCount + 1 {
      Array(measureLabels.suffix(from: measureCount + 1)).forEach({ $0.removeFromSuperlayer() })
      measureLabels = Array(measureLabels.prefix(measureCount + 1))
    }
  }

  public func updateDurationOfCell(at index: Int, duration: Double) {
    cells[index].duration = duration
    setNeedsLayout()
  }

  public func reloadData() {
    cells.forEach({ $0.removeFromSuperview() })
    cells = []
    let count = rbDataSource?.numberOfCells(in: self) ?? 0
    if let index = selectedCellIndex, index >= count {
      selectedCellIndex = nil
    }

    for i in 0..<count {
      guard let cell = rbDataSource?.rbScrollView(self, cellAt: i) else { continue }
      cell.isSelected = i == selectedCellIndex
      cell.delegate = self
      addSubview(cell)
      cells.append(cell)
    }
  }

  // MARK: Zooming

  @objc private func didZoom(pinch: UIPinchGestureRecognizer) {
    switch pinch.state {
    case .began, .changed:
      guard pinch.numberOfTouches == 2 else { return }

      var scale = pinch.scale
      scale = ((scale - 1) * zoomSpeed) + 1
      scale = min(scale, maxMeasureWidth/measureWidth)
      scale = max(scale, minMeasureWidth/measureWidth)
      measureWidth *= scale
      pinch.scale = 1

      // Get in new zoom level.
      let oldZoomLevel = zoomLevel
      if measureWidth >= maxMeasureWidth, zoomLevel < maxZoomLevel {
        zoomLevel += 1
        minMeasureWidth = maxMeasureWidth / CGFloat(timeSignatureBeatCount)
        measureWidth = minMeasureWidth
      } else if measureWidth <= minMeasureWidth, zoomLevel > 0 {
        zoomLevel -= 1
        maxMeasureWidth = minMeasureWidth * CGFloat(timeSignatureBeatCount)
        measureWidth = maxMeasureWidth
      }

      // Zoom
      if oldZoomLevel != zoomLevel {
        updateMeasure()
      }

      setNeedsLayout()
    default:
      return
    }
  }

  // MARK: Utils

  func farMostCellPosition() -> Double {
    if let last = cells.map({ ceil($0.position + $0.duration) }).sorted().last {
      return last + 1
    }
    return 0
  }

  func durationForTranslation(_ translation: CGFloat) -> Double {
    var measureBarWidth: CGFloat = 0
    switch zoomLevel {
    case 0:
      measureBarWidth = measureWidth
    case 1:
      measureBarWidth = measureWidth * CGFloat(timeSignatureBeatCount)
    default:
      measureBarWidth = measureWidth * CGFloat(timeSignatureBeatCount) * 4
    }

    return Double(translation / measureBarWidth)
  }

  func quantize(zoomLevel: Int) {
    isQuantizing = true
    var range: Double = 0
    switch zoomLevel {
    case 0:
      range = 1.0
    case 1:
      range = 1.0 / Double(timeSignatureBeatCount)
    case 2:
      range = (1.0 / (Double(timeSignatureBeatCount)) / 4.0)
    default:
      range = 1.0
    }

    for i in 0..<cells.count {
      let factor = Int(round(cells[i].position / range))
      cells[i].position = Double(factor) * range
      rbDelegate?.rbScrollView(self, didUpdate: cells[i], at: i)
    }

    cells.enumerated().forEach({ fixOverlaps(editingCellIndex: $0.offset) })
    isQuantizing = false
    rbDelegate?.rbScrollViewDidQuantize(self)
  }

  func intersects(lhs: RBScrollViewCell, rhs: RBScrollViewCell) -> Bool {
    let lhsEnd = lhs.position + lhs.duration
    let rhsEnd = rhs.position + rhs.duration
    if lhs.position < rhs.position {
      return lhsEnd > rhs.position
    } else if lhs.position > rhs.position {
      return rhsEnd > lhs.position
    } else {
      return true
    }
  }

  func fixOverlaps(editingCellIndex: Int? = nil) {
    guard cells.count > 0,
      let editingCellIndex = editingCellIndex ?? selectedCellIndex,
      let editingCell = cells[safe: editingCellIndex]
      else { return }

    let overlappingCells = cells.filter({ intersects(lhs: editingCell, rhs: $0) && ($0 != editingCell) })

    for overlappingCell in overlappingCells {
      guard let overlappingCellIndex = cells.firstIndex(of: overlappingCell) else { continue }

      // Check if overlapping a cell completely.
      if editingCell.position < overlappingCell.position,
        editingCell.position + editingCell.duration > overlappingCell.position + overlappingCell.duration {
        // Delete overlapped cell
        cells.remove(at: overlappingCellIndex)
        overlappingCell.removeFromSuperview()
        rbDelegate?.rbScrollView(self, didDelete: overlappingCell, at: overlappingCellIndex)
        continue
      }

      let overlapState = self.overlapState ?? .resize

      // Check overlap state
      switch overlapState {
      case .moveRight, .resize:
        if editingCell.position + editingCell.duration > overlappingCell.position {
          // Update position
          let oldPosition = overlappingCell.position
          overlappingCell.position = editingCell.position + editingCell.duration
          // Update duration
          let positionDiff = overlappingCell.position - oldPosition
          overlappingCell.duration = overlappingCell.duration - positionDiff
          // Inform delegate
          rbDelegate?.rbScrollView(self, didUpdate: overlappingCell, at: overlappingCellIndex)
        }
      case .moveLeft:
        if overlappingCell.position + overlappingCell.duration > editingCell.position {
          overlappingCell.duration = editingCell.position - overlappingCell.position
          rbDelegate?.rbScrollView(self, didUpdate: overlappingCell, at: overlappingCellIndex)
        }
      }

      // Make sure cell's duration is valid
      if overlappingCell.duration <= 0 {
        cells.remove(at: overlappingCellIndex)
        overlappingCell.removeFromSuperview()
        rbDelegate?.rbScrollView(self, didDelete: overlappingCell, at: overlappingCellIndex)
      }
    }

    setNeedsLayout()
  }

  func snapRangeheadToLastCell() {
    rangeheadView.position = cells.map({ $0.position + $0.duration }).sorted().last ?? 0
    rbDelegate?.rbScrollViewDidUpdateRangehead(self, withPanGesture: false)
  }

  // MARK: Cell Selection

  func selectCell(_ cell: RBScrollViewCell) {
    selectedCellIndex = nil
    for i in 0..<cells.count {
      cells[i].isSelected = false
      if cells[i] == cell {
        cells[i].isSelected = true
        selectedCellIndex = i
      }
    }

    if let index = selectedCellIndex {
      rbDelegate?.rbScrollView(self, didSelect: cell, at: index)
    }
  }

  func selectCell(at index: Int) {
    guard let cell = cells[safe: index] else { return }
    selectCell(cell)
  }

  func unselectCells() {
    selectedCellIndex = nil
    cells.forEach({ $0.isSelected = false })
    rbDelegate?.rbScrollViewDidUnselectCells(self)
  }

  func getSelectedCell() -> RBScrollViewCell? {
    return cells.first(where: { $0.isSelected })
  }

  // MARK: RBCellDelegate

  public func rbScrollViewCellDidMove(_ rbScrollViewCell: RBScrollViewCell, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubviewToFront(rbScrollViewCell)

    if pan.state == .began {
      selectCell(rbScrollViewCell)
      movingCellStartPosition = rbScrollViewCell.position
    }

    guard rbScrollViewCell.frame.maxX < contentSize.width,
      rbScrollViewCell.frame.minX >= 0,
      let index = cells.firstIndex(of: rbScrollViewCell)
      else { return }

    panChangeState: if pan.state == .changed {
      cells[index].position += durationForTranslation(translation.x)
      if cells[index].position < 0 { cells[index].position = 0 }
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
      rbDelegate?.rbScrollView(self, didUpdate: rbScrollViewCell, at: index)

      guard let startPosition = movingCellStartPosition else { break panChangeState }
      overlapState = cells[index].position > startPosition ? .moveRight : .moveLeft
    }

    if pan.state == .ended {
      fixOverlaps()
      overlapState = nil
      movingCellStartPosition = nil
      rbDelegate?.rbScrollViewDidMoveCell(self)
    }

    setNeedsLayout()
  }

  public func rbScrollViewCellDidResize(_ rbScrollViewCell: RBScrollViewCell, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubviewToFront(rbScrollViewCell)

    if pan.state == .began {
      selectCell(rbScrollViewCell)
      overlapState = .resize
    }

    guard rbScrollViewCell.frame.maxX < contentSize.width,
      rbScrollViewCell.frame.minX >= 0,
      let index = cells.firstIndex(of: rbScrollViewCell)
      else { return }

    if pan.state == .changed {
      cells[index].duration += durationForTranslation(translation.x)
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)

      rbDelegate?.rbScrollView(self, didUpdate: rbScrollViewCell, at: index)
    }

    if pan.state == .ended {
      fixOverlaps()
      overlapState = nil
      rbDelegate?.rbScrollViewDidResizeCell(self)
    }

    setNeedsLayout()
  }

  public func rbScrollViewCellDidTap(_ rbScrollViewCell: RBScrollViewCell) {
    if rbScrollViewCell.isSelected {
      unselectCells()
    } else {
      selectCell(rbScrollViewCell)
    }
  }

  public func rbScrollViewCellDidDelete(_ rbScrollViewCell: RBScrollViewCell) {
    guard let index = cells.firstIndex(of: rbScrollViewCell) else { return }

    if rbScrollViewCell.isSelected {
      unselectCells()
    }

    cells[index].removeFromSuperview()
    cells.remove(at: index)
    rbDelegate?.rbScrollView(self, didDelete: rbScrollViewCell, at: index)
  }

  // MARK: RBPlayheadViewDelegate

  public func playheadView(_ playheadView: RBPlayheadView, didPan panGestureRecognizer: UIPanGestureRecognizer) {
    let translation = panGestureRecognizer.translation(in: self)
    bringSubviewToFront(playheadView)

    guard playheadView.frame.maxX < contentSize.width,
      playheadView.position >= 0
      else { return }

    playheadView.position += durationForTranslation(translation.x)
    if playheadView.position < 0 { playheadView.position = 0 }
    panGestureRecognizer.setTranslation(CGPoint(x: 0, y: translation.y), in: self)

    if panGestureRecognizer.state == .ended {
      if playheadView == self.playheadView {
        rbDelegate?.rbScrollViewDidUpdatePlayhead(self)
      } else if playheadView == self.rangeheadView {
        rbDelegate?.rbScrollViewDidUpdateRangehead(self, withPanGesture: true)
      }
    }

    setNeedsLayout()
  }
}
