//
//  PanView.swift
//  PanView
//
//  Created by Roman Baev on 27.09.2021.
//

import Foundation
import SwiftUI

public final class PanView: UIView {
  public enum PresentationState {
    case hidden
    case short
    case long
  }

  struct Constants {
    static let snapMovementSensitivity = CGFloat(0.7)
  }

  private(set) var state: PresentationState = .hidden
  private var containerView: UIView { self }
  private let presentableViewController: PanViewPresentable & UIViewController

  private var hiddenFormYPosition: CGFloat { containerView.frame.maxY }
  private var shortFormYPosition: CGFloat = 0
  private var longFormYPosition: CGFloat = 0
  private var isPresentedViewAnimating = false
  private var extendsPanScrolling = true
  private var anchorModalToLongForm = true
  private var scrollViewYOffset: CGFloat = 0.0
  private var scrollObserver: NSKeyValueObservation?

  private var anchoredYPosition: CGFloat {
    let defaultTopOffset = presentableViewController.topOffset
    return anchorModalToLongForm ? longFormYPosition : defaultTopOffset
  }
  
  private lazy var panelView: UIView = {
    let view = UIView()
    view.addSubview(presentableViewController.view)
    if presentableViewController.shouldRoundTopCorners {
      view.layer.masksToBounds = true
      view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
      view.layer.cornerRadius = presentableViewController.cornerRadius
    }
    return view
  }()

  private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(didPanOnPresentedView(_ :)))
    gesture.minimumNumberOfTouches = 1
    gesture.maximumNumberOfTouches = 1
    gesture.delegate = self
    return gesture
  }()

  public init(presentableViewController: PanViewPresentable & UIViewController) {
    self.presentableViewController = presentableViewController
    super.init(frame: .zero)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    scrollObserver?.invalidate()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    if panelView.superview == nil {
      containerView.addSubview(panelView)
      containerView.addGestureRecognizer(panGestureRecognizer)
      setNeedsLayoutUpdate()
      transition(to: state, animated: false)
    }
    configureViewLayout()
  }

  public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return panelView.frame.contains(point)
  }
}

// MARK: - Public Methods

public extension PanView {
  /**
   Transition the PanModalPresentationController
   to the given presentation state
   */
  func transition(to state: PresentationState, animated: Bool = true) {
    guard panelView.superview != nil else {
      self.state = state
      return
    }
    guard presentableViewController.shouldTransition(to: state) == true
    else { return }

    presentableViewController.willTransition(to: state)

    switch state {
    case .short:
      snap(toYPosition: shortFormYPosition, animated: animated)
    case .long:
      snap(toYPosition: longFormYPosition, animated: animated)
    case .hidden:
      snap(toYPosition: hiddenFormYPosition, animated: animated)
    }

    self.state = state
  }
  /**
   Operations on the scroll view, such as content height changes,
   or when inserting/deleting rows can cause the pan modal to jump,
   caused by the pan modal responding to content offset changes.
   
   To avoid this, you can call this method to perform scroll view updates,
   with scroll observation temporarily disabled.
   */
  func performUpdates(_ updates: () -> Void) {
    guard let scrollView = presentableViewController.panScrollable else { return }
    
    // Pause scroll observer
    scrollObserver?.invalidate()
    scrollObserver = nil
    
    // Perform updates
    updates()
    
    // Resume scroll observer
    trackScrolling(scrollView)
    observe(scrollView: scrollView)
  }
  /**
   Updates the PanModalPresentationController layout
   based on values in the PanModalPresentable
   
   - Note: This should be called whenever any
   pan modal presentable value changes after the initial presentation
   */
  func setNeedsLayoutUpdate() {
    configureViewLayout()
    adjustPresentedViewFrame()
    observe(scrollView: presentableViewController.panScrollable)
    configureScrollViewInsets()
  }
}

// MARK: - Presented View Layout Configuration

private extension PanView {
  /**
   Boolean flag to determine if the presented view is anchored
   */
  var isPresentedViewAnchored: Bool {
    if !isPresentedViewAnimating
        && extendsPanScrolling
        && panelView.frame.minY.rounded() <= anchoredYPosition.rounded() {
      return true
    }
    return false
  }

  /**
   Reduce height of presentedView so that it sits at the bottom of the screen
   */
  func adjustPresentedViewFrame() {
    let frame = containerView.frame

    let adjustedSize = CGSize(width: frame.size.width, height: frame.size.height - anchoredYPosition)
    let panFrame = panelView.frame
    panelView.frame.size = frame.size

    if ![shortFormYPosition, longFormYPosition].contains(panelView.frame.origin.y) {
          // if the container is already in the correct position, no need to adjust positioning
          // (rotations & size changes cause positioning to be out of sync)
      let yPosition = panFrame.origin.y - panFrame.height + frame.height
      panelView.frame.origin.y = max(yPosition, anchoredYPosition)
    }

    panelView.frame.origin.x = frame.origin.x
    presentableViewController.view.frame = CGRect(origin: .zero, size: adjustedSize)
  }
  
  /**
   Calculates & stores the layout anchor points & options
   */
  func configureViewLayout() {
    shortFormYPosition = presentableViewController.shortFormYPos
    longFormYPosition = presentableViewController.longFormYPos
    anchorModalToLongForm = presentableViewController.anchorModalToLongForm
    extendsPanScrolling = presentableViewController.allowsExtendedPanScrolling
    containerView.isUserInteractionEnabled = presentableViewController.isUserInteractionEnabled
  }
  
  /**
   Configures the scroll view insets
   */
  func configureScrollViewInsets() {
    guard
      let scrollView = presentableViewController.panScrollable,
      !scrollView.isScrolling
    else { return }

    /**
     Disable vertical scroll indicator until we start to scroll
     to avoid visual bugs
     */
    scrollView.showsVerticalScrollIndicator = false
    scrollView.scrollIndicatorInsets = presentableViewController.scrollIndicatorInsets

    /**
     Set the appropriate contentInset as the configuration within this class
     offsets it
     */
    scrollView.contentInset.bottom = safeAreaInsets.bottom
    scrollView.scrollIndicatorInsets.bottom = 0.0

    /**
     As we adjust the bounds during `handleScrollViewTopBounce`
     we should assume that contentInsetAdjustmentBehavior will not be correct
     */
    scrollView.contentInsetAdjustmentBehavior = .never
  }
}

// MARK: - Pan Gesture Event Handler

private extension PanView {
  /**
   The designated function for handling pan gesture events
   */
  @objc func didPanOnPresentedView(_ recognizer: UIPanGestureRecognizer) {
    guard shouldRespond(to: recognizer) else {
      recognizer.setTranslation(.zero, in: recognizer.view)
      return
    }
    switch recognizer.state {
    case .began, .changed:
      /**
       Respond accordingly to pan gesture translation
       */
      respond(to: recognizer)
      /**
       If presentedView is translated above the longForm threshold, treat as transition
       */
      if panelView.frame.origin.y == anchoredYPosition && extendsPanScrolling {
        presentableViewController.willTransition(to: .long)
      }
    default:
      /**
       Use velocity sensitivity value to restrict snapping
       */
      let velocity = recognizer.velocity(in: panelView)
      
      if isVelocityWithinSensitivityRange(velocity.y) {
        /**
         If velocity is within the sensitivity range,
         transition to a presentation state or dismiss entirely.
         
         This allows the user to dismiss directly from long form
         instead of going to the short form state first.
         */
        if velocity.y < 0 {
          transition(to: .long)
          
        } else if (nearest(to: panelView.frame.minY, inValues: [longFormYPosition, containerView.bounds.height]) == longFormYPosition
                    && panelView.frame.minY < shortFormYPosition) || presentableViewController.allowsDragToDismiss == false {
          transition(to: .short)
        } else {
          transition(to: .hidden)
        }
      } else {
        /**
         The `containerView.bounds.height` is used to determine
         how close the presented view is to the bottom of the screen
         */
        let position = nearest(to: panelView.frame.minY, inValues: [containerView.bounds.height, shortFormYPosition, longFormYPosition])
        
        if position == longFormYPosition {
          transition(to: .long)
        } else if position == shortFormYPosition || presentableViewController.allowsDragToDismiss == false {
          transition(to: .short)
        } else {
          transition(to: .hidden)
        }
      }
    }
  }
  
  /**
   Determine if the pan modal should respond to the gesture recognizer.
   
   If the pan modal is already being dragged & the delegate returns false, ignore until
   the recognizer is back to it's original state (.began)
   
   ⚠️ This is the only time we should be cancelling the pan modal gesture recognizer
   */
  func shouldRespond(to panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
    guard presentableViewController.shouldRespond(to: panGestureRecognizer) == true
            || !(panGestureRecognizer.state == .began || panGestureRecognizer.state == .cancelled)
    else {
      panGestureRecognizer.isEnabled = false
      panGestureRecognizer.isEnabled = true
      return false
    }
    return !shouldFail(panGestureRecognizer: panGestureRecognizer)
  }
  
  /**
   Communicate intentions to presentable and adjust subviews in containerView
   */
  func respond(to panGestureRecognizer: UIPanGestureRecognizer) {
    presentableViewController.willRespond(to: panGestureRecognizer)

    var yDisplacement = panGestureRecognizer.translation(in: panelView).y
    
    /**
     If the presentedView is not anchored to long form, reduce the rate of movement
     above the threshold
     */
    if panelView.frame.origin.y < longFormYPosition {
      yDisplacement /= 2.0
    }
    adjust(toYPosition: panelView.frame.origin.y + yDisplacement)
    
    panGestureRecognizer.setTranslation(.zero, in: panelView)
  }
  
  /**
   Determines if we should fail the gesture recognizer based on certain conditions
   
   We fail the presented view's pan gesture recognizer if we are actively scrolling on the scroll view.
   This allows the user to drag whole view controller from outside scrollView touch area.
   
   Unfortunately, cancelling a gestureRecognizer means that we lose the effect of transition scrolling
   from one view to another in the same pan gesture so don't cancel
   */
  func shouldFail(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
    /**
     Allow api consumers to override the internal conditions &
     decide if the pan gesture recognizer should be prioritized.
     
     ⚠️ This is the only time we should be cancelling the panScrollable recognizer,
     for the purpose of ensuring we're no longer tracking the scrollView
     */
    guard !shouldPrioritize(panGestureRecognizer: panGestureRecognizer) else {
      presentableViewController.panScrollable?.panGestureRecognizer.isEnabled = false
      presentableViewController.panScrollable?.panGestureRecognizer.isEnabled = true
      return false
    }
    
    guard
      isPresentedViewAnchored,
      let scrollView = presentableViewController.panScrollable,
      scrollView.contentOffset.y > 0
    else {
      return false
    }
    
    let loc = panGestureRecognizer.location(in: panelView)
    return (scrollView.frame.contains(loc) || scrollView.isScrolling)
  }
  
  /**
   Determine if the presented view's panGestureRecognizer should be prioritized over
   embedded scrollView's panGestureRecognizer.
   */
  func shouldPrioritize(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
    return panGestureRecognizer.state == .began &&
      presentableViewController.shouldPrioritize(panModalGestureRecognizer: panGestureRecognizer) == true
  }
  
  /**
   Check if the given velocity is within the sensitivity range
   */
  func isVelocityWithinSensitivityRange(_ velocity: CGFloat) -> Bool {
    return (abs(velocity) - (1000 * (1 - Constants.snapMovementSensitivity))) > 0
  }
  
  func snap(toYPosition yPos: CGFloat, animated: Bool) {
    guard animated else {
      adjust(toYPosition: yPos)
      return
    }
    PanView.Animator.animate({ [weak self] in
      self?.adjust(toYPosition: yPos)
      self?.isPresentedViewAnimating = true
    }, config: presentableViewController) { [weak self] didComplete in
      self?.isPresentedViewAnimating = !didComplete
    }
  }
  
  /**
   Sets the y position of the presentedView & adjusts the backgroundView.
   */
  func adjust(toYPosition yPos: CGFloat) {
    panelView.frame.origin.y = max(yPos, anchoredYPosition)
  }
  
  /**
   Finds the nearest value to a given number out of a given array of float values
   
   - Parameters:
   - number: reference float we are trying to find the closest value to
   - values: array of floats we would like to compare against
   */
  func nearest(to number: CGFloat, inValues values: [CGFloat]) -> CGFloat {
    guard let nearestVal = values.min(by: { abs(number - $0) < abs(number - $1) })
    else { return number }
    return nearestVal
  }
}

// MARK: - UIScrollView Observer

private extension PanView {
  /**
   Creates & stores an observer on the given scroll view's content offset.
   This allows us to track scrolling without overriding the scrollView delegate
   */
  func observe(scrollView: UIScrollView?) {
    scrollObserver?.invalidate()
    scrollObserver = scrollView?.observe(\.contentOffset, options: .old) { [weak self] scrollView, change in
      /**
       Incase we have a situation where we have two containerViews in the same presentation
       */
      guard self?.containerView != nil
      else { return }
      
      self?.didPanOnScrollView(scrollView, change: change)
    }
  }
  
  /**
   Scroll view content offset change event handler
   
   Also when scrollView is scrolled to the top, we disable the scroll indicator
   otherwise glitchy behaviour occurs
   
   This is also shown in Apple Maps (reverse engineering)
   which allows us to seamlessly transition scrolling from the panContainerView to the scrollView
   */
  func didPanOnScrollView(_ scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
    guard
      !presentableViewController.isBeingDismissed,
      !presentableViewController.isBeingPresented
    else { return }
    
    if !isPresentedViewAnchored && scrollView.contentOffset.y > 0 {
      /**
       Hold the scrollView in place if we're actively scrolling and not handling top bounce
       */
      haltScrolling(scrollView)
      
    } else if scrollView.isScrolling || isPresentedViewAnimating {
      if isPresentedViewAnchored {
        /**
         While we're scrolling upwards on the scrollView,
         store the last content offset position
         */
        trackScrolling(scrollView)
      } else {
        /**
         Keep scroll view in place while we're panning on main view
         */
        haltScrolling(scrollView)
      }
      
    } else if presentableViewController.view.isKind(of: UIScrollView.self)
                && !isPresentedViewAnimating && scrollView.contentOffset.y <= 0 {
      /**
       In the case where we drag down quickly on the scroll view and let go,
       `handleScrollViewTopBounce` adds a nice elegant touch.
       */
      handleScrollViewTopBounce(scrollView: scrollView, change: change)
    } else {
      trackScrolling(scrollView)
    }
  }
  
  /**
   Halts the scroll of a given scroll view & anchors it at the `scrollViewYOffset`
   */
  func haltScrolling(_ scrollView: UIScrollView) {
    scrollView.setContentOffset(CGPoint(x: 0, y: scrollViewYOffset), animated: false)
    scrollView.showsVerticalScrollIndicator = false
  }
  
  /**
   As the user scrolls, track & save the scroll view y offset.
   This helps halt scrolling when we want to hold the scroll view in place.
   */
  func trackScrolling(_ scrollView: UIScrollView) {
    scrollViewYOffset = max(scrollView.contentOffset.y, 0)
    scrollView.showsVerticalScrollIndicator = true
  }
  
  /**
   To ensure that the scroll transition between the scrollView & the modal
   is completely seamless, we need to handle the case where content offset is negative.
   
   In this case, we follow the curve of the decelerating scroll view.
   This gives the effect that the modal view and the scroll view are one view entirely.
   
   - Note: This works best where the view behind view controller is a UIScrollView.
   So, for example, a UITableViewController.
   */
  func handleScrollViewTopBounce(scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
    guard let oldYValue = change.oldValue?.y, scrollView.isDecelerating else { return }
    
    let yOffset = scrollView.contentOffset.y
    let presentedSize = containerView.frame.size
    
    /**
     Decrease the view bounds by the y offset so the scroll view stays in place
     and we can still get updates on its content offset
     */
    panelView.bounds.size = CGSize(width: presentedSize.width, height: presentedSize.height + yOffset)
    
    if oldYValue > yOffset {
      /**
       Move the view in the opposite direction to the decreasing bounds
       until half way through the deceleration so that it appears
       as if we're transferring the scrollView drag momentum to the entire view
       */
      panelView.frame.origin.y = longFormYPosition - yOffset
    } else {
      scrollViewYOffset = 0
      snap(toYPosition: longFormYPosition, animated: true)
    }
    
    scrollView.showsVerticalScrollIndicator = false
  }
}

// MARK: - UIGestureRecognizerDelegate

extension PanView: UIGestureRecognizerDelegate {
  /**
   Do not require any other gesture recognizers to fail
   */
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
  }
  
  /**
   Allow simultaneous gesture recognizers only when the other gesture recognizer's view
   is the pan scrollable view
   */
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return otherGestureRecognizer.view == presentableViewController.panScrollable
  }
}

// MARK: - Helper Extensions

private extension UIScrollView {
  /**
   A flag to determine if a scroll view is scrolling
   */
  var isScrolling: Bool {
    return isDragging && !isDecelerating || isTracking
  }
}
