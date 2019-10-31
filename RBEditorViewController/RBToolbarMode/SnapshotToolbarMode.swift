//
//  SnapshotToolbarMode.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class SnapshotToolbarModeProps: RBToolbarModeProps {
  var snapshotData: RBSnapshotData
  var didPressAddButtonCallback: (() -> Void)?
  var didPressMIDICCButtonCallback: (() -> Void)?
  var didSelectSnapshotAtIndex: ((_ index: Int) -> Void)?
  var didDeleteSnapshotAtIndex: ((_ index: Int) -> Void)?
  var didRequestSnapshotImageAt: ((_ index: Int) -> UIImage?)?

  required init() {
    snapshotData = RBSnapshotData()
  }

  init(
    snapshotData: RBSnapshotData,
    didPressAddButtonCallback: (() -> Void)?,
    didPressMIDICCButtonCallback: (() -> Void)?,
    didSelectSnapshotAtIndex: ((_ index: Int) -> Void)?,
    didDeleteSnapshotAtIndex: ((_ index: Int) -> Void)?,
    didRequestSnapshotImageAt: ((_ index: Int) -> UIImage?)?) {
    self.snapshotData = snapshotData
    self.didPressAddButtonCallback = didPressAddButtonCallback
    self.didPressMIDICCButtonCallback = didPressMIDICCButtonCallback
    self.didSelectSnapshotAtIndex = didSelectSnapshotAtIndex
    self.didDeleteSnapshotAtIndex = didDeleteSnapshotAtIndex
    self.didRequestSnapshotImageAt = didRequestSnapshotImageAt
  }
}

class RBSnapshotCellView: UIView {
  var button = UIButton(type: .system)
  var imageView = UIImageView()
  var didPressDeleteButtonCallback: (() -> Void)?

  open override var canBecomeFirstResponder: Bool {
    return true
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func commonInit() {
    addSubview(imageView)
    addSubview(button)

    imageView.image = nil
    button.setTitle(nil, for: .normal)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    button.translatesAutoresizingMaskIntoConstraints = false
    button.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    button.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    button.topAnchor.constraint(equalTo: topAnchor).isActive = true
    button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    let longPressGesure = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(longPress:)))
    addGestureRecognizer(longPressGesure)
  }

  @objc public func didLongPress(longPress: UILongPressGestureRecognizer) {
    guard let superview = superview else { return }
    becomeFirstResponder()

    let menu = UIMenuController.shared
    menu.menuItems = [
      UIMenuItem(
        title: i18n.delete.description,
        action: #selector(didPressDeleteButton))
      ]
    menu.arrowDirection = .up
    menu.setTargetRect(frame, in: superview)
    menu.setMenuVisible(true, animated: true)
  }

  @objc public func didPressDeleteButton() {
    didPressDeleteButtonCallback?()
  }
}

class SnapshotToolbarModeView: RBToolbarModeView<SnapshotToolbarModeProps> {
  var addButton = UIButton(type: .system)
  var ccButton = UIButton(type: .system)
  var snapshotScroll = UIScrollView()
  var snapshotStack = UIStackView()

  override func render() {
    super.render()
    let snapshots = props.snapshotData

    addButton.setTitle(i18n.add.description, for: .normal)
    addButton.setTitleColor(UIColor.toolbarButtonTextColor, for: .normal)
    addButton.addTarget(self, action: #selector(addButtonPressed(sender:)), for: .touchUpInside)

    ccButton.setTitle("CC#\(snapshots.cc)", for: .normal)
    ccButton.setTitleColor(UIColor.toolbarButtonTextColor, for: .normal)
    ccButton.addTarget(self, action: #selector(ccButtonPressed(sender:)), for: .touchUpInside)

    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    scrollView.isScrollEnabled = false
    stackView.spacing = 16
    stackView.addArrangedSubview(addButton)
    stackView.addArrangedSubview(snapshotScroll)
    stackView.addArrangedSubview(ccButton)

    snapshotScroll.addSubview(snapshotStack)
    snapshotStack.axis = .horizontal
    snapshotStack.spacing = 8
    snapshotStack.translatesAutoresizingMaskIntoConstraints = false
    snapshotStack.leftAnchor.constraint(equalTo: snapshotScroll.leftAnchor).isActive = true
    snapshotStack.rightAnchor.constraint(equalTo: snapshotScroll.rightAnchor).isActive = true
    snapshotStack.topAnchor.constraint(equalTo: snapshotScroll.topAnchor).isActive = true
    snapshotStack.bottomAnchor.constraint(equalTo: snapshotScroll.bottomAnchor).isActive = true
    snapshotStack.heightAnchor.constraint(equalTo: snapshotScroll.heightAnchor).isActive = true

    for index in 0..<snapshots.snapshots.count {
      let cell = RBSnapshotCellView(frame: .zero)
      snapshotStack.addArrangedSubview(cell)

      cell.translatesAutoresizingMaskIntoConstraints = false
      cell.widthAnchor.constraint(equalTo: cell.heightAnchor).isActive = true
      cell.layer.borderColor = UIColor.black.cgColor
      cell.layer.borderWidth = 1
      cell.button.tag = index
      cell.button.addTarget(self, action: #selector(snapshotSelected(sender:)), for: .touchUpInside)
      cell.didPressDeleteButtonCallback = {
        self.props.didDeleteSnapshotAtIndex?(index)
      }

      // Request snapshot image.
      DispatchQueue.global(qos: .background).async {
        if let image = self.props.didRequestSnapshotImageAt?(index) {
          DispatchQueue.main.async {
            cell.imageView.image = image
          }
        }
      }
    }
  }

  @IBAction func addButtonPressed(sender: UIButton) {
    props.didPressAddButtonCallback?()
  }

  @IBAction func ccButtonPressed(sender: UIButton) {
    props.didPressMIDICCButtonCallback?()
  }

  @IBAction func snapshotSelected(sender: UIButton) {
    props.didSelectSnapshotAtIndex?(sender.tag)
  }
}

final class SnapshotToolbarMode: RBToolbarMode {
  typealias PropType = SnapshotToolbarModeProps
  var props = SnapshotToolbarModeProps()
  var toolbarTitle: String = i18n.snapshots.description

  var view: RBToolbarModeView<SnapshotToolbarModeProps> {
    return SnapshotToolbarModeView(props: props)
  }
}
