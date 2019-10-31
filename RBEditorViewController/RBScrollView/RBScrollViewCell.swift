//
//  RBScrollViewCell.swift
//  RBScrollView
//
//  Created by cem.olcay on 11/09/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//
import UIKit

/// Delegate functions to inform about editing or deleting cell.
public protocol RBScrollViewCellDelegate: class {
  func rbScrollViewCellDidMove(_ rbScrollViewCell: RBScrollViewCell, pan: UIPanGestureRecognizer)
  func rbScrollViewCellDidResize(_ rbScrollViewCell: RBScrollViewCell, pan: UIPanGestureRecognizer)
  func rbScrollViewCellDidTap(_ rbScrollViewCell: RBScrollViewCell)
  func rbScrollViewCellDidDelete(_ rbScrollViewCell: RBScrollViewCell)
}

/// Defines a custom menu item for the `MIDITimeTableCellView` to show when you long press it.
public struct RBScrollViewCellCustomMenuItem {
  /// Title of the custom menu item.
  public private(set) var title: String
  /// Action handler of the custom menu item.
  public private(set) var action: Selector

  /// Creates and returns a `UIMenuItem` from itself.
  public var menuItem: UIMenuItem {
    return UIMenuItem(title: title, action: action)
  }

  /// Initilizes custom `UIMenuItem` for `MIDITimeTableCellView`.
  ///
  /// - Parameters:
  ///   - title: Title of the custom menu item.
  ///   - action: Action handler of the custom menu item.
  public init(title: String, action: Selector) {
    self.title = title
    self.action = action
  }
}

/// Base cell view that shows on `MIDITimeTableView`. Has abilitiy to move, resize and delete.
open class RBScrollViewCell: UIView {
  /// View that holds the pan gesture on right most side in the view to use in resizing cell.
  private let resizeView = UIView()
  /// Inset from the rightmost side on the cell to capture resize gesture.
  open var resizePanThreshold: CGFloat = 20
  /// Delegate that informs about editing cell.
  open weak var delegate: RBScrollViewCellDelegate?
  /// Custom items other than delete, when you long press cell.
  open var customMenuItems = [RBScrollViewCellCustomMenuItem]()
  /// When cell's position or duration editing, is selected.
  open var isSelected: Bool = false { didSet { setNeedsLayout() }}

  open override var canBecomeFirstResponder: Bool {
    return true
  }
  
  public let id: String
  public var position: Double = 0
  public var duration: Double = 0

  // MARK: Init

  public override init(frame: CGRect) {
    id = UUID().uuidString
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder aDecoder: NSCoder) {
    id = UUID().uuidString
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    addSubview(resizeView)
    let resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(didResize(pan:)))
    resizeView.addGestureRecognizer(resizeGesture)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(tap:)))
    addGestureRecognizer(tapGesture)

    let moveGesture = UIPanGestureRecognizer(target: self, action: #selector(didMove(pan:)))
    addGestureRecognizer(moveGesture)

    let longPressGesure = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(longPress:)))
    addGestureRecognizer(longPressGesure)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(menuControllerWillHideNotification),
                                           name: UIMenuController.willHideMenuNotification,
                                           object: nil)
  }

  // MARK: Layout

  open override func layoutSubviews() {
    super.layoutSubviews()
    resizeView.frame = CGRect(
      x: frame.size.width - resizePanThreshold,
      y: 0,
      width: resizePanThreshold,
      height: frame.size.height)
  }

  // MARK: Gestures

  @objc public func didTap(tap: UITapGestureRecognizer) {
    delegate?.rbScrollViewCellDidTap(self)
  }

  @objc public func didMove(pan: UIPanGestureRecognizer) {
    delegate?.rbScrollViewCellDidMove(self, pan: pan)
  }

  @objc public func didResize(pan: UIPanGestureRecognizer) {
    delegate?.rbScrollViewCellDidResize(self, pan: pan)
  }

  @objc public func didLongPress(longPress: UILongPressGestureRecognizer) {
    guard let superview = superview else { return }
    becomeFirstResponder()
    isSelected = true

    let menu = UIMenuController.shared
    menu.menuItems = [
      UIMenuItem(
        title: i18n.delete.description,
        action: #selector(didPressDeleteButton))
      ] + customMenuItems.map({ $0.menuItem })
    menu.arrowDirection = .up
    menu.setTargetRect(frame, in: superview)
    menu.setMenuVisible(true, animated: true)
  }

  @objc public func didPressDeleteButton() {
    delegate?.rbScrollViewCellDidDelete(self)
  }

  @objc public func menuControllerWillHideNotification() {
    isSelected = false
  }
}
