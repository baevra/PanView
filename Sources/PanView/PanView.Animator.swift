//
//  PanViewAnimator.swift
//  PanView
//
//  Created by Roman Baev on 24.09.2021.
//

import UIKit

extension PanView {
  struct Animator {
    struct Constants {
      static let defaultTransitionDuration: TimeInterval = 0.5
    }
    
    static func animate(
      _ animations: @escaping () -> Void,
      config: PanViewPresentable?,
      _ completion: ((Bool) -> Void)? = nil
    ) {
      let transitionDuration = config?.transitionDuration ?? Constants.defaultTransitionDuration
      let springDamping = config?.springDamping ?? 1.0
      let animationOptions = config?.transitionAnimationOptions ?? []
      
      UIView.animate(
        withDuration: transitionDuration,
        delay: 0,
        usingSpringWithDamping: springDamping,
        initialSpringVelocity: 0,
        options: animationOptions,
        animations: animations,
        completion: completion
      )
    }
  }
}
