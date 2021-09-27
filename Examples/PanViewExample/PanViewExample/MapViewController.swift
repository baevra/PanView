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
    view.addSubview(panelView)
    panelView.transition(to: .short)
    panelView.transition(to: .long)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    mapView.frame = view.bounds
    panelView.frame = view.bounds
  }

}
