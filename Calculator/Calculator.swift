//
//  Calculator.swift
//  Calculator
//
//  Created by Adam Rothman on 12/23/15.
//  Copyright © 2015 Adam Rothman. All rights reserved.
//

import Foundation


class Calculator {

    static let sharedCalculator: Calculator = Calculator()

    enum Item: CustomStringConvertible {
        case Value(Double)
        case Symbol(String)
        case UnaryOperation(String, (Double) -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)

        var description: String {
            get {
                switch self {
                case .Value(let value):
                    return Calculator.sharedCalculator.stringFromNumber(value)!
                case .Symbol(let symbol):
                    return symbol
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                }
            }
        }

        var operandCount: Int {
            get {
                switch self {
                case .Value, .Symbol:
                    return 0
                case .UnaryOperation:
                    return 1
                case .BinaryOperation:
                    return 2
                }
            }
        }
    }

    private let numberFormatter: NSNumberFormatter = NSNumberFormatter()

    private var operations: [String: Item] = [:]

    private let constants: [String: Double] = ["π": M_PI, "e": M_E]
    private var variables: [String: Double] = [:]

    private var stack: [Item] = []

    var hasProgram: Bool {
        get { return stack.count > 0 }
    }

    var description: String {
        get {
            guard stack.count > 0 else { return "..." }
            var descriptions: [String] = []
            var items = stack
            while !items.isEmpty {
                descriptions.append(stripOuterParentheses(prettyPop(&items)))
            }
            return descriptions.joinWithSeparator(", ")
        }
    }

    var descriptionForGraphing: String {
        get {
            guard stack.count > 0 else { return "" }
            var items = stack
            let description = prettyPop(&items)
            return "y = \(stripOuterParentheses(description))"
        }
    }

    init() {
        numberFormatter.maximumFractionDigits = numberFormatter.maximumIntegerDigits
        numberFormatter.numberStyle = .DecimalStyle

        func learnOperation(operation: Item) {
            operations[operation.description] = operation
        }

        // Arithmetic
        learnOperation(Item.BinaryOperation("+", +))
        learnOperation(Item.BinaryOperation("-", -))
        learnOperation(Item.BinaryOperation("×", *))
        learnOperation(Item.BinaryOperation("÷", /))

        // Exponentiation
        learnOperation(Item.UnaryOperation("eˣ", exp))
        learnOperation(Item.UnaryOperation("ln", log))
        learnOperation(Item.UnaryOperation("10ˣ") { pow(10, $0) })
        learnOperation(Item.UnaryOperation("log₁₀", log10))
        learnOperation(Item.BinaryOperation("pow", pow))
        learnOperation(Item.UnaryOperation("√", sqrt))

        // Trigonometry
        learnOperation(Item.UnaryOperation("sin", sin))
        learnOperation(Item.UnaryOperation("cos", cos))
        learnOperation(Item.UnaryOperation("tan", tan))
        learnOperation(Item.UnaryOperation("sin⁻¹", asin))
        learnOperation(Item.UnaryOperation("cos⁻¹", acos))
        learnOperation(Item.UnaryOperation("tan⁻¹", atan))
    }

    // MARK: Utilities

    func numberFromString(string: String) -> Double? {
        if let double = numberFormatter.numberFromString(string) as? Double {
            return double
        } else {
            return nil
        }
    }

    func stringFromNumber(number: Double) -> String? {
        if let string = numberFormatter.stringFromNumber(number) {
            return string
        } else {
            return nil
        }
    }

    // MARK: Math

    private func evaluate(stack: [Item], variables: [String: Double]) -> (result: Double?, remainingItems: [Item]) {
        guard !stack.isEmpty else { return (nil, stack) }

        var remainingItems = stack
        let item = remainingItems.removeLast()
        switch item {
        case .Value(let value):
            return (value, remainingItems)
        case .Symbol(let symbol):
            if let constantValue = constants[symbol] {
                return (constantValue, remainingItems)
            } else if let variableValue = variables[symbol] {
                return (variableValue, remainingItems)
            } else {
                return (nil, remainingItems)
            }
        case .UnaryOperation(_, let operation):
            let results = evaluate(remainingItems, variables: variables)
            if let operand = results.result {
                return (operation(operand), results.remainingItems)
            } else {
                return (nil, results.remainingItems)
            }
        case .BinaryOperation(_, let operation):
            let rightResults = evaluate(remainingItems, variables: variables)
            let leftResults = evaluate(rightResults.remainingItems, variables: variables)
            if let leftOperand = leftResults.result, rightOperand = rightResults.result {
                return (operation(leftOperand, rightOperand), leftResults.remainingItems)
            } else {
                return (nil, leftResults.remainingItems)
            }
        }
    }

    func evaluateForVariableValues(variables: [String: Double]) -> Double? {
        let (result, _) = evaluate(stack, variables: variables)
        return result
    }

    func evaluate() -> Double? {
        return evaluateForVariableValues(variables)
    }

    // MARK: Description

    private func stripOuterParentheses(expression: String) -> String {
        if expression[expression.startIndex] == "(" && expression[expression.endIndex.advancedBy(-1)] == ")" {
            let range = Range<String.Index>(start: expression.startIndex.advancedBy(1), end: expression.endIndex.advancedBy(-1))
            return expression.substringWithRange(range)
        } else {
            return expression
        }
    }

    private func prettyPop(inout stack: [Item]) -> String {
        var expression: String = ""

        if let item = stack.popLast() {
            switch item {
            case .Value, .Symbol:
                expression = item.description
            case .UnaryOperation(let symbol, _):
                let operand = prettyPop(&stack)

                if symbol == "eˣ" {
                    expression = "e ^ (\(stripOuterParentheses(operand)))"
                } else if symbol == "10ˣ" {
                    expression = "10 ^ (\(stripOuterParentheses(operand)))"
                } else {
                    expression = "\(item.description)(\(stripOuterParentheses(operand)))"
                }
            case .BinaryOperation(let symbol, _):
                let rightOperand = prettyPop(&stack)
                let leftOperand = prettyPop(&stack)

                if symbol == "×" || symbol == "÷" {
                    expression = "\(leftOperand) \(item.description) \(rightOperand)"
                } else if symbol == "pow" {
                    expression = "((\(stripOuterParentheses(leftOperand))) ^ (\(stripOuterParentheses(rightOperand))))"
                } else {
                    expression = "(\(leftOperand) \(item.description) \(rightOperand))"
                }
            }
        }

        return expression
    }

    // MARK: Stack manipulation

    func pushValue(value: Double) {
        stack.append(Item.Value(value))
    }

    func pushSymbol(symbol: String) {
        stack.append(Item.Symbol(symbol))
    }

    func pushOperation(symbol: String) {
        guard let operation = operations[symbol] where stack.count >= operation.operandCount else { return }
        stack.append(operation)
    }

    func clear() {
        stack.removeAll()
    }

}