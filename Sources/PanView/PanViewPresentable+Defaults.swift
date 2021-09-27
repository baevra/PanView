//
//  PanViewPresentable+Defaults.swift
//  PanView
//
//  Created by Roman Baev on 24.09.2021.
//

import Foundation
import UIKit

public extension PanViewPresentable where Self: UIViewController {
  var topOffset: CGFloat {
    return topLayoutOffset
  }
  
  var shortFormHeight: PanView.Height {
    return longFormHeight
  }
  
  var longFormHeight: PanView.Height {
    
    guard let scrollView = panScrollable
    else { return .maxHeight }
    
    // called once during presentation and stored
    scrollView.layoutIfNeeded()
    return .contentHeight(scrollView.contentSize.height)
  }
  
  var cornerRadius: CGFloat {
    return 8.0
  }
  
  var springDamping: CGFloat {
    return 0.8
  }
  
  var transitionDuration: Double {
    return PanView.Animator.Constants.defaultTransitionDuration
  }
  
  var transitionAnimationOptions: UIView.AnimationOptions {
    return [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
  }
  
  var panModalBackgroundColor: UIColor {
    return UIColor.black.withAlphaComponent(0.7)
  }
  
  var dragIndicatorBackgroundColor: UIColor {
    return UIColor.lightGray
  }
  
  var scrollIndicatorInsets: UIEdgeInsets {
    let top = shouldRoundTopCorners ? cornerRadius : 0
    return UIEdgeInsets(top: CGFloat(top), left: 0, bottom: bottomLayoutOffset, right: 0)
  }
  
  var anchorModalToLongForm: Bool {
    return true
  }
  
  var allowsExtendedPanScrolling: Bool {
    
    guard let scrollView = panScrollable
    else { return false }
    
    scrollView.layoutIfNeeded()
    return scrollView.contentSize.height > (scrollView.frame.height - bottomLayoutOffset)
  }
  
  var allowsDragToDismiss: Bool {
    return true
  }
  
  var allowsTapToDismiss: Bool {
    return true
  }
  
  var isUserInteractionEnabled: Bool {
    return true
  }
  
  var isHapticFeedbackEnabled: Bool {
    return true
  }
  
  var shouldRoundTopCorners: Bool {
    return true
  }
  
  var showDragIndicator: Bool {
    return shouldRoundTopCorners
  }
  
  func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
    return true
  }
  
  func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) {
    
  }
  
  func shouldTransition(to state: PanView.PresentationState) -> Bool {
    return true
  }
  
  func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
    return false
  }
  
  func willTransition(to state: PanView.PresentationState) {
    
  }

  func didTransition(to state: PanView.PresentationState) {

  }
}
