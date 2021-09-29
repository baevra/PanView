//
//  MapViewController.swift
//  PanViewExample
//
//  Created by Roman Baev on 27.09.2021.
//

import Foundation
import UIKit
import MapKit
import PanView

final class MapViewController: UIViewController {
  let mapView: MKMapView = {
    let mapView = MKMapView()
    return mapView
  }()

  let button: UIButton = {
    let button = UIButton()
    button.setTitle("Change", for: .normal)
    button.addTarget(self, action: #selector(change), for: .touchUpInside)
    return button
  }()

  lazy var panelView: PanView = {
    let presentableViewController = PlacesViewController()
    let panelView = PanView(
      presentableViewController: presentableViewController
    )
    addChild(presentableViewController)
    return panelView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(mapView)
    view.addSubview(button)
    view.addSubview(panelView)
    panelView.transition(to: .long)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    mapView.frame = view.bounds
    button.frame = CGRect(x: 20, y: 100, width: 300, height: 44)
    panelView.frame = view.bounds
  }

  @objc
  func change() {
    switch panelView.state {
    case .hidden:
      panelView.transition(to: .short)
    case .short:
      panelView.transition(to: .long)
    case .long:
      panelView.transition(to: .hidden)
    }
  }
}
