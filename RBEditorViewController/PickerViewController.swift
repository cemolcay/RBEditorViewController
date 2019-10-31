//
//  PickerViewController.swift
//  RhythmBud
//
//  Created by cem.olcay on 30/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

extension UIViewController {
  func presentPicker(data: PickerData) {
    let picker = PickerViewController(data: data)
    let navigation = UINavigationController(rootViewController: picker)
    navigation.modalPresentationStyle = .formSheet
    present(navigation, animated: true, completion: nil)
  }
}

struct PickerData {
  var title: String
  var rows: [String]
  var initialSelectionIndex: Int
  var cancelCallback: (() -> Void)?
  var doneCallback: ((_ item: String, _ index: Int) -> Void)?
}


class PickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
  var pickerView: UIPickerView?
  var data: PickerData

  // MARK: Init

  init(data: PickerData) {
    self.data = data
    super.init(nibName: nil, bundle: nil)
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    self.data = PickerData(title: "", rows: [], initialSelectionIndex: 0, cancelCallback: nil, doneCallback: nil)
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    self.data = PickerData(title: "", rows: [], initialSelectionIndex: 0, cancelCallback: nil, doneCallback: nil)
    super.init(coder: aDecoder)
  }

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupRhythmBudTheme()
    title = data.title

    // Cancel
    let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(sender:)))
    navigationItem.leftBarButtonItem = cancelButton

    // Done
    let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(sender:)))
    navigationItem.rightBarButtonItem = doneButton

    // Picker
    pickerView = UIPickerView()
    guard let pickerView = pickerView else { return }
    pickerView.delegate = self
    pickerView.dataSource = self
    pickerView.translatesAutoresizingMaskIntoConstraints = false
    pickerView.selectRow(data.initialSelectionIndex, inComponent: 0, animated: false)

    view.addSubview(pickerView)
    pickerView.translatesAutoresizingMaskIntoConstraints = false
    pickerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
    pickerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    pickerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    pickerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
  }

  @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
    if let index = pickerView?.selectedRow(inComponent: 0) {
      let item = data.rows[index]
      data.doneCallback?(item, index)
    }
    dismiss(animated: true, completion: nil)
  }

  // MARK: UIPickerViewDataSource

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return data.rows.count
  }

  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    return NSAttributedString(
      string: data.rows[row],
      attributes: [
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)
      ])
  }
}
