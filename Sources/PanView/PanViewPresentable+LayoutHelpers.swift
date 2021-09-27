//
//  PanViewLayoutHelpers.swift
//  PanView
//
//  Created by Roman Baev on 24.09.2021.
//

import UIKit

/**
 ⚠️ [Internal Only] ⚠️
 Helper extensions that handle layout in the PanModalPresentationController
 */
extension PanViewPresentable where Self: UIViewController {
  var containerView: UIView {
    return parent?.view ?? view
  }
  /**
   Length of the top layout guide of the presenting view controller.
   Gives us the safe area inset from the top.
   */
  var topLayoutOffset: CGFloat {
    return containerView.safeAreaInsets.top
  }
  
  /**
   Length of the bottom layout guide of the presenting view controller.
   Gives us the safe area inset from the bottom.
   */
  var bottomLayoutOffset: CGFloat {
    return containerView.safeAreaInsets.bottom
  }
  
  /**
   Returns the short form Y position

   - Note: If voiceover is on, the `longFormYPos` is returned.
   We do not support short form when voiceover is on as it would make it difficult for user to navigate.
   */
  var shortFormYPos: CGFloat {
    guard !UIAccessibility.isVoiceOverRunning
    else { return longFormYPos }
    
    let shortFormYPos = topMargin(from: shortFormHeight) + topOffset
    
    // shortForm shouldn't exceed longForm
    return max(shortFormYPos, longFormYPos)
  }
  
  /**
   Returns the long form Y position
   
   - Note: We cap this value to the max possible height
   to ensure content is not rendered outside of the view bounds
   */
  var longFormYPos: CGFloat {
    return max(topMargin(from: longFormHeight), topMargin(from: .maxHeight)) + topOffset
  }
  
  /**
   Use the container view for relative positioning as this view's frame
   is adjusted in PanModalPresentationController
   */
  var bottomYPos: CGFloat {
    return containerView.bounds.size.height - topOffset
  }
  
  /**
   Converts a given pan modal height value into a y position value
   calculated from top of view
   */
  func topMargin(from: PanView.Height) -> CGFloat {
    switch from {
    case .maxHeight:
      return 0.0
    case let .maxHeightWithTopInset(inset):
      return inset
    case let .contentHeight(height):
      return bottomYPos - (height + bottomLayoutOffset)
    case let .contentHeightIgnoringSafeArea(height):
      return bottomYPos - height
    case .intrinsicHeight:
      view.layoutIfNeeded()
      let targetSize = CGSize(width: view.bounds.width,
                              height: UIView.layoutFittingCompressedSize.height)
      let intrinsicHeight = view.systemLayoutSizeFitting(targetSize).height
      return bottomYPos - (intrinsicHeight + bottomLayoutOffset)
    }
  }
}
