//
//  UsersViewController.swift
//  PanPanel
//
//  Created by Roman Baev on 24.09.2021.
//

import Foundation
import UIKit
import PanView

final class PlacesViewController: UIViewController, UITableViewDataSource {
  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    tableView.dataSource = self
    return tableView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(tableView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.frame = view.bounds
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return places.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
    cell.textLabel?.text = places[indexPath.row]
    return cell
  }
}

extension PlacesViewController: PanViewPresentable {
  var shortFormHeight: PanView.Height {
    return .contentHeight(44)
  }

  var longFormHeight: PanView.Height {
    return .maxHeightWithTopInset(0)
  }

  var panScrollable: UIScrollView? {
    return tableView
  }
}

extension PlacesViewController {
  var places: [String] {
    return [
      "Afghanistan",
      "Albania",
      "Algeria",
      "Andorra",
      "Angola",
      "Antigua and Barbuda",
      "Argentina",
      "Armenia",
      "Australia",
      "Austria",
      "Austrian Empire*",
      "Azerbaijan"
    ]
  }
}
