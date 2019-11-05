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

public protocol RBGridViewDataSource: class {
  func numberOfCells(in gridView: RBGridView) -> Int
  func rbScrollView(_ gridView: RBGridView, cellAt index: Int) -> RBGridViewCell
}

public protocol RBGridViewDelegate: class {
  func gridView(_ gridView: RBGridView, didUpdate cell: RBGridViewCell, at index: Int)
  func gridView(_ gridView: RBGridView, didDelete cell: RBGridViewCell, at index: Int)
  func gridView(_ gridView: RBGridView, didSelect cell: RBGridViewCell, at index: Int)
  func gridViewDidUnselectCells(_ gridView: RBGridView)
  func gridViewDidUpdatePlayhead(_ gridView: RBGridView)
  func gridViewDidUpdateRangehead(_ gridView: RBGridView, withPanGesture: Bool)
  func gridViewDidMoveCell(_ gridView: RBGridView)
  func gridViewDidResizeCell(_ gridView: RBGridView)
  func gridViewDidQuantize(_ gridView: RBGridView)
}

public enum RBOverlapState {
  case resize
  case moveLeft
  case moveRight
}

public enum RBZoomLevel: Int {
  case bar
  case beat
  case subbeat

  var zoomIn: RBZoomLevel? {
    return RBZoomLevel(rawValue: rawValue + 1)
  }

  var zoomOut: RBZoomLevel? {
    return RBZoomLevel(rawValue: rawValue - 1)
  }

  func multiplier(timeSignature beats: Int) -> Int {
    switch self {
    case .bar:
      return 1
    case .beat:
      return beats
    case .subbeat:
      return beats * 4
    }
  }
}

public class RBGridView: UIScrollView, RBGridViewCellDelegate, RBPlayheadViewDelegate {
  public var measureCount: Int = 0
  public var measureWidth: CGFloat = 200
  public var maxMeasureWidth: CGFloat = 300
  public var minMeasureWidth: CGFloat = 100
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
  public var zoomLevel: RBZoomLevel = .bar
  public var isQuantizing: Bool = false

  private var cells: [RBGridViewCell] = []
  private var selectedCellIndex: Int?
  private var movingCellStartPosition: Double?
  private var overlapState: RBOverlapState?
  private var farMostCellPosition: CGFloat = 0

  public var playheadView = RBPlayheadView(frame: .zero)
  public var rangeheadView = RBPlayheadView(frame: .zero)

  public weak var rbDataSource: RBGridViewDataSource?
  public weak var rbDelegate: RBGridViewDelegate?

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

    // Check if we should draw measure
    let multiplier = CGFloat(zoomLevel.multiplier(timeSignature: timeSignatureBeatCount))
    let cellPosition = ceil(farMostCellPosition * multiplier) + 1
    let rangePosition = CGFloat(ceil(CGFloat(rangeheadView.position) * multiplier) + 1)
    let availableSpace = ceil(frame.size.width / measureWidth)
    let newMeasureCount = Int(max(cellPosition, rangePosition, availableSpace))
    
    if measureCount != newMeasureCount {
      measureCount = newMeasureCount
      drawMeasure()
    }

    // Update content size
    contentSize.width = CGFloat(measureCount) * measureWidth

    // Draw measure background
    measureBackgroundLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width + contentOffset.x, height: measureHeight)
    measureBackgroundLayer.backgroundColor = measureBackgroundColor.cgColor
    measureBottomLine.frame = CGRect(x: 0, y: measureHeight - measureBottomLineSize, width: frame.size.width + contentOffset.x, height: measureBottomLineSize)
    measureBottomLine.backgroundColor = measureBottomLineColor.cgColor

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

    // Draw cells
    for cell in cells {
      let position = CGFloat(cell.position) * measureWidth * multiplier
      let duration = CGFloat(cell.duration) * measureWidth * multiplier
      let height = frame.size.height - measureHeight - (cellVerticalPadding * 2)
      cell.frame = CGRect(
        x: position,
        y: measureHeight + cellVerticalPadding,
        width: duration,
        height: height)
    }

    // Playhead
    playheadView.measureHeight = measureHeight
    playheadView.lineHeight = frame.height - measureHeight
    playheadView.measureWidth = measureWidth * multiplier
    bringSubviewToFront(playheadView)

    // Rangehead
    rangeheadView.measureHeight = measureHeight
    rangeheadView.lineHeight = frame.height - measureHeight
    rangeheadView.measureWidth = measureWidth * multiplier
    bringSubviewToFront(rangeheadView)

    CATransaction.commit()
  }

  public func drawMeasure() {
    let measureLabelIndicies = measureLabels.indices
    let measureLineIndicies = measureLines.indices
    var currentBar = 1
    var currentBeat = 1
    var currentSubbeat = 1

    // Update measures, add new ones if nessessary.
    for i in 0..<measureCount + 1 {
      // Determine measure Text
      var measureText = ""
      switch zoomLevel {
      case .bar:
        measureText = "\(currentBar)"
        currentBar += 1
      case .beat:
        measureText = "\(currentBar).\(currentBeat)"
        currentBeat += 1
        if currentBeat > timeSignatureBeatCount {
          currentBar += 1
          currentBeat = 1
        }
      case .subbeat:
        measureText = "\(currentBar).\(currentBeat).\(currentSubbeat)"
        currentSubbeat += 1
        if currentSubbeat > 4 {
          currentSubbeat = 1
          currentBeat += 1
          if currentBeat > timeSignatureBeatCount {
            currentBar += 1
            currentBeat = 1
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

    farMostCellPosition = 0
    for i in 0..<count {
      guard let cell = rbDataSource?.rbScrollView(self, cellAt: i) else { continue }
      cell.isSelected = i == selectedCellIndex
      cell.delegate = self
      addSubview(cell)
      cells.append(cell)
      // Calculate far most position
      let rightPosition = CGFloat(cell.position + cell.duration)
      if rightPosition > farMostCellPosition {
        farMostCellPosition = rightPosition
      }
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
      if measureWidth >= maxMeasureWidth, let zoomIn = zoomLevel.zoomIn {
        zoomLevel = zoomIn
        minMeasureWidth = maxMeasureWidth / CGFloat(timeSignatureBeatCount)
        measureWidth = minMeasureWidth
      } else if measureWidth <= minMeasureWidth, let zoomOut = zoomLevel.zoomOut {
        zoomLevel = zoomOut
        maxMeasureWidth = minMeasureWidth * CGFloat(timeSignatureBeatCount)
        measureWidth = maxMeasureWidth
      }

      setNeedsLayout()
    default:
      return
    }
  }

  // MARK: Utils

  func durationForTranslation(_ translation: CGFloat) -> Double {
    let multiplier = zoomLevel.multiplier(timeSignature: timeSignatureBeatCount)
    return Double(translation / (measureWidth * CGFloat(multiplier)))
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
      rbDelegate?.gridView(self, didUpdate: cells[i], at: i)
    }

    cells.enumerated().forEach({ fixOverlaps(editingCellIndex: $0.offset) })
    isQuantizing = false
    rbDelegate?.gridViewDidQuantize(self)
  }

  func intersects(lhs: RBGridViewCell, rhs: RBGridViewCell) -> Bool {
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
        rbDelegate?.gridView(self, didDelete: overlappingCell, at: overlappingCellIndex)
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
          rbDelegate?.gridView(self, didUpdate: overlappingCell, at: overlappingCellIndex)
        }
      case .moveLeft:
        if overlappingCell.position + overlappingCell.duration > editingCell.position {
          overlappingCell.duration = editingCell.position - overlappingCell.position
          rbDelegate?.gridView(self, didUpdate: overlappingCell, at: overlappingCellIndex)
        }
      }

      // Make sure cell's duration is valid
      if overlappingCell.duration <= 0 {
        cells.remove(at: overlappingCellIndex)
        overlappingCell.removeFromSuperview()
        rbDelegate?.gridView(self, didDelete: overlappingCell, at: overlappingCellIndex)
      }
    }

    setNeedsLayout()
  }

  func snapRangeheadToLastCell() {
    rangeheadView.position = cells.map({ $0.position + $0.duration }).sorted().last ?? 0
    rbDelegate?.gridViewDidUpdateRangehead(self, withPanGesture: false)
  }

  func calculateFarMostCellPosition() {
    farMostCellPosition = cells.map({ ceil(CGFloat($0.position + $0.duration)) }).sorted().last ?? 0
  }

  // MARK: Cell Selection

  func selectCell(_ cell: RBGridViewCell) {
    selectedCellIndex = nil
    for i in 0..<cells.count {
      cells[i].isSelected = false
      if cells[i] == cell {
        cells[i].isSelected = true
        selectedCellIndex = i
      }
    }

    if let index = selectedCellIndex {
      rbDelegate?.gridView(self, didSelect: cell, at: index)
    }
  }

  func selectCell(at index: Int) {
    guard let cell = cells[safe: index] else { return }
    selectCell(cell)
  }

  func unselectCells() {
    selectedCellIndex = nil
    cells.forEach({ $0.isSelected = false })
    rbDelegate?.gridViewDidUnselectCells(self)
  }

  func getSelectedCell() -> RBGridViewCell? {
    return cells.first(where: { $0.isSelected })
  }

  // MARK: RBCellDelegate

  public func gridViewCellDidMove(_ gridViewCell: RBGridViewCell, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubviewToFront(gridViewCell)

    if pan.state == .began {
      selectCell(gridViewCell)
      movingCellStartPosition = gridViewCell.position
    }

    guard gridViewCell.frame.minX >= 0,
      let index = cells.firstIndex(of: gridViewCell)
      else { return }

    panChangeState: if pan.state == .changed {
      cells[index].position += durationForTranslation(translation.x)
      if cells[index].position < 0 { cells[index].position = 0 }
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)
      rbDelegate?.gridView(self, didUpdate: gridViewCell, at: index)

      guard let startPosition = movingCellStartPosition else { break panChangeState }
      overlapState = cells[index].position > startPosition ? .moveRight : .moveLeft
    }

    if pan.state == .ended {
      fixOverlaps()
      overlapState = nil
      movingCellStartPosition = nil
      calculateFarMostCellPosition()
      rbDelegate?.gridViewDidMoveCell(self)
    }

    setNeedsLayout()
  }

  public func gridViewCellDidResize(_ gridViewCell: RBGridViewCell, pan: UIPanGestureRecognizer) {
    let translation = pan.translation(in: self)
    bringSubviewToFront(gridViewCell)

    if pan.state == .began {
      selectCell(gridViewCell)
      overlapState = .resize
    }

    guard gridViewCell.frame.minX >= 0,
      let index = cells.firstIndex(of: gridViewCell)
      else { return }

    if pan.state == .changed {
      cells[index].duration += durationForTranslation(translation.x)
      pan.setTranslation(CGPoint(x: 0, y: translation.y), in: self)

      rbDelegate?.gridView(self, didUpdate: gridViewCell, at: index)
    }

    if pan.state == .ended {
      fixOverlaps()
      overlapState = nil
      calculateFarMostCellPosition()
      rbDelegate?.gridViewDidResizeCell(self)
    }

    setNeedsLayout()
  }

  public func gridViewCellDidTap(_ gridViewCell: RBGridViewCell) {
    if gridViewCell.isSelected {
      unselectCells()
    } else {
      selectCell(gridViewCell)
    }
  }

  public func gridViewCellDidDelete(_ gridViewCell: RBGridViewCell) {
    guard let index = cells.firstIndex(of: gridViewCell) else { return }

    if gridViewCell.isSelected {
      unselectCells()
    }

    cells[index].removeFromSuperview()
    cells.remove(at: index)
    rbDelegate?.gridView(self, didDelete: gridViewCell, at: index)
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
        rbDelegate?.gridViewDidUpdatePlayhead(self)
      } else if playheadView == self.rangeheadView {
        rbDelegate?.gridViewDidUpdateRangehead(self, withPanGesture: true)
      }
    }

    setNeedsLayout()
  }
}
