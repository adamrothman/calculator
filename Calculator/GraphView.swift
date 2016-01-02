//
//  GraphView.swift
//  Calculator
//
//  Created by Adam Rothman on 12/23/15.
//  Copyright © 2015 Adam Rothman. All rights reserved.
//

import UIKit


protocol GraphViewDataSource: class {
    func dataAvailableForGraphView(graphView: GraphView) -> Bool
    func f(x: Double) -> Double?
}


extension CGRect {
    func fuzzyContains(point: CGPoint, tolerance: CGFloat) -> Bool {
        let containsX = point.x >= origin.x - tolerance && point.x <= size.width + tolerance
        let containsY = point.y >= origin.y - tolerance && point.y <= size.height + tolerance
        return containsX && containsY
    }
}


@IBDesignable
class GraphView: UIView {

    private var graphCenter: CGPoint {
        get { return convertPoint(center, fromView: superview) }
    }

    /* Graphs origin in points */
    private var origin: CGPoint! {
        didSet { setNeedsDisplay() }
    }

    private var pointsPerUnit: Double = 10 {
        didSet { setNeedsDisplay() }
    }

    private var color: UIColor = UIColor.blackColor() {
        didSet { setNeedsDisplay() }
    }

    private let axesDrawer: AxesDrawer = AxesDrawer()

    weak var dataSource: GraphViewDataSource?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func drawRect(rect: CGRect) {
        if origin == nil { origin = graphCenter }

        axesDrawer.drawAxesInRect(bounds, origin: origin, pointsPerUnit: CGFloat(pointsPerUnit))

        guard let source = dataSource where source.dataAvailableForGraphView(self) else { return }

        var lastPointIgnored = true
        let path = UIBezierPath()
        for var xInPoints: CGFloat = rect.origin.x; xInPoints < rect.size.width; xInPoints += 1 / contentScaleFactor {
            let xInGraphUnits: Double = Double(-origin.x + xInPoints) / pointsPerUnit
            guard let yInGraphUnits: Double = source.f(xInGraphUnits) where !(isinf(yInGraphUnits) || isnan(yInGraphUnits)) else {
                lastPointIgnored = true
                continue
            }

            let yInPoints: CGFloat = origin.y - CGFloat(yInGraphUnits * pointsPerUnit)
            let point: CGPoint = CGPoint(x: xInPoints, y: yInPoints)
            guard rect.fuzzyContains(point, tolerance: max(100 / CGFloat(pointsPerUnit), 100)) else {
                lastPointIgnored = true
                continue
            }

            if lastPointIgnored {
                path.moveToPoint(point)
            } else {
                path.addLineToPoint(point)
            }
            lastPointIgnored = false
        }
        color.set()
        path.stroke()
    }

    // MARK: Helpers

    private func setup() {
        contentMode = .Redraw
        axesDrawer.contentScaleFactor = contentScaleFactor
    }

    func reset() {
        pointsPerUnit = 10
        origin = graphCenter
    }

    // MARK: Gesture handlers

    func pan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .Changed {
            let translation = gesture.translationInView(self)
            origin = CGPoint(x: origin.x + translation.x, y: origin.y + translation.y)
            gesture.setTranslation(CGPointZero, inView: self)
        }
    }

    func pinch(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
            pointsPerUnit *= Double(gesture.scale)
            gesture.scale = 1
        }
    }

    func longPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            origin = gesture.locationInView(self)
        }
    }

}
