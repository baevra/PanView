//
//  PanViewHeight.swift
//  PanView
//
//  Created by Roman Baev on 24.09.2021.
//

import UIKit

public extension PanView {
  enum Height: Equatable {
    /**
     Sets the height to be the maximum height (+ topOffset)
     */
    case maxHeight
    
    /**
     Sets the height to be the max height with a specified top inset.
     - Note: A value of 0 is equivalent to .maxHeight
     */
    case maxHeightWithTopInset(CGFloat)
    
    /**
     Sets the height to be the specified content height
     */
    case contentHeight(CGFloat)
    
    /**
     Sets the height to be the specified content height
     & also ignores the bottomSafeAreaInset
     */
    case contentHeightIgnoringSafeArea(CGFloat)
    
    /**
     Sets the height to be the intrinsic content height
     */
    case intrinsicHeight
  }
}
