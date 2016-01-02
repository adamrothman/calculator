//
//  GraphViewController.swift
//  Calculator
//
//  Created by Adam Rothman on 12/23/15.
//  Copyright © 2015 Adam Rothman. All rights reserved.
//

import UIKit


class GraphViewController: UIViewController, GraphViewDataSource {

    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self

            let panRecognizer = UIPanGestureRecognizer(target: graphView, action: "pan:")
            graphView.addGestureRecognizer(panRecognizer)

            let pinchRecognizer = UIPinchGestureRecognizer(target: graphView, action: "pinch:")
            graphView.addGestureRecognizer(pinchRecognizer)

            let longPressRecognizer = UILongPressGestureRecognizer(target: graphView, action: "longPress:")
            graphView.addGestureRecognizer(longPressRecognizer)
        }
    }

    let calculator: Calculator = Calculator.sharedCalculator

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.title = calculator.descriptionForGraphing
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = true
        navigationController?.navigationBarHidden = false
    }

    // MARK: Actions

    @IBAction func reset(sender: UIBarButtonItem) {
        graphView.reset()
    }

    // MARK: - GraphViewDataSource

    func dataAvailableForGraphView(graphView: GraphView) -> Bool {
        return calculator.hasProgram
    }

    func f(x: Double) -> Double? {
        let variables: [String: Double] = ["x": x]
        return calculator.evaluateForVariableValues(variables)
    }
    
}
