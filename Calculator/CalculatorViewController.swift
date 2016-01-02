//
//  CalculatorViewController.swift
//  Calculator
//
//  Created by Adam Rothman on 12/23/15.
//  Copyright © 2015 Adam Rothman. All rights reserved.
//

import UIKit


class CalculatorViewController: UIViewController, UISplitViewControllerDelegate {

    @IBOutlet weak var inputLabel: UILabel!
    @IBOutlet weak var programLabel: UILabel!

    @IBOutlet weak var eˣButton: UIButton!
    @IBOutlet weak var tenˣButton: UIButton!
    @IBOutlet weak var powButton: UIButton!
    @IBOutlet weak var sinButton: UIButton!
    @IBOutlet weak var cosButton: UIButton!
    @IBOutlet weak var tanButton: UIButton!
    @IBOutlet weak var πButton: UIButton!

    let calculator: Calculator = Calculator.sharedCalculator

    var collapseGraph: Bool = true

    var userIsTyping: Bool = false
    var decimalPresent: Bool = false

    var secondMode: Bool = false {
        didSet {
            eˣButton.setTitle(secondMode ? "ln" : "eˣ", forState: .Normal)
            tenˣButton.setTitle(secondMode ? "log₁₀" : "10ˣ", forState: .Normal)
            powButton.setTitle(secondMode ? "√" : "pow", forState: .Normal)
            sinButton.setTitle(secondMode ? "sin⁻¹" : "sin", forState: .Normal)
            cosButton.setTitle(secondMode ? "cos⁻¹" : "cos", forState: .Normal)
            tanButton.setTitle(secondMode ? "tan⁻¹" : "tan", forState: .Normal)
            πButton.setTitle(secondMode ? "e" : "π", forState: .Normal)
        }
    }

    var inputValue: Double {
        get {
            if let input = inputLabel.text, value = calculator.numberFromString(input) {
                return value
            } else {
                return 0
            }
        }

        set { inputLabel.text = calculator.stringFromNumber(newValue) }
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Calculator"
        splitViewController?.delegate = self
        inputValue = 0
        updateDisplay()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = false
        navigationController?.navigationBarHidden = true
    }

    // MARK: Helpers

    func updateDisplay() {
        if !userIsTyping, let value = calculator.evaluate() {
            inputLabel.text = calculator.stringFromNumber(value)
        }
        programLabel.text = calculator.description
    }

    // MARK: Actions

    @IBAction func second(sender: UISwitch) {
        secondMode = sender.on
    }

    @IBAction func digit(sender: UIButton) {
        guard let digit = sender.currentTitle else { return }
        if userIsTyping {
            inputLabel.text! += digit
        } else if digit != "0" {
            inputLabel.text = digit
            userIsTyping = true
        }
    }

    @IBAction func decimal(sender: UIButton) {
        guard !decimalPresent else { return }
        if userIsTyping {
            inputLabel.text! += "."
        } else {
            inputLabel.text = "0."
            userIsTyping = true
        }
        decimalPresent = true
    }

    @IBAction func negative(sender: UIButton) {
        guard userIsTyping else { return }
        inputValue = -1 * inputValue
    }

    @IBAction func symbol(sender: UIButton) {
        if userIsTyping { enter(sender) }
        calculator.pushSymbol(sender.currentTitle!)
        updateDisplay()
    }

    @IBAction func operation(sender: UIButton) {
        if userIsTyping { enter(sender) }
        calculator.pushOperation(sender.currentTitle!)
        updateDisplay()
    }

    @IBAction func enter(sender: UIButton) {
        calculator.pushValue(inputValue)
        updateDisplay()
        userIsTyping = false
        decimalPresent = false
    }

    @IBAction func clear(sender: UIButton) {
        calculator.clear()
        updateDisplay()
        inputValue = 0
        userIsTyping = false
        decimalPresent = false
    }

    @IBAction func graph(sender: UIButton) {
        if userIsTyping { enter(sender) }
        updateDisplay()
        collapseGraph = false
        performSegueWithIdentifier("showGraph", sender: sender)
    }

    // MARK: - UISplitViewControllerDelegate

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return collapseGraph
    }
    
}
