//
//  EquationEngine.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-04-04.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import Foundation

class EquationEngine {
    private let expressionRegex = "([a-z]|[A-Z]|([0-9]+(\\.?[0-9]+)?)|\\*|(\\/([0-9]+(\\.?[0-9]+)?))|(\\^([0-9]+(\\.?[0-9]+)?))|(\\(.*\\)))*([a-z]|[A-Z])([a-z]|[A-Z]|([0-9]+(\\.?[0-9]+)?)|\\*|(\\/([0-9]+(\\.?[0-9]+)?))|(\\^([0-9]+(\\.?[0-9]+)?))|(\\(.*\\)))*"
    private let numberRegex = "(\\-?[0-9]+(\\.?[0-9]+)?)"
    private let letterRegex = "([a-z]|[A-Z])"
    private let operatorRegex = "(\\-|\\+|\\*|\\/|\\^)"
    private let bracketsRegex = "(\\(.*\\))"
    
    
    var equation: Equation
    
    init(equation: String) {
        self.equation = Equation(id: -1, name: "test", description: "This is a test equation", equationStr: equation)
    }

    public func validateEquation(equation: String) -> Bool {
        let equRange = NSRange(location: 0, length: equation.characters.count).toRange()!
        let singleOperation = "(((" + expressionRegex + ")|" + numberRegex + "|" + bracketsRegex + ")" + operatorRegex + "((" + expressionRegex + ")|" + numberRegex + "|" + bracketsRegex + "))"
        let largerEquation = singleOperation + "(" + operatorRegex + "((" + expressionRegex + ")|" + numberRegex + "))*"
        let equationRegex = "(" + largerEquation + "|(" + expressionRegex + ")|" + numberRegex + ")(\\=(" + largerEquation + "|(" + expressionRegex + ")|" + numberRegex + "))?"
        let regex = try! NSRegularExpression(pattern: equationRegex)
        let matches = regex.matches(in: equation, range: NSMakeRange(0, equation.characters.count))
        var success = false;
        for match in matches {
            let matchRange = match.rangeAt(0).toRange()!
            if (matchRange == equRange) {
                success = true
                break
            }
        }
        return success
    }
    
    public func processEquation() throws -> Equation {
        var result: Double?
        if !validateEquation(equation: equation.EquString) {
            throw EquationErrors.invalidEquation
        }
        equation.EquString = removeWhitespace(equation: equation.EquString)
        equation.EquString = insertAllAsterisks(equation: equation.EquString)
        
        if (equation.VarIndex != nil) {
            if equation.getEqualsIndex() == nil {
                equation.EquString.insert(contentsOf: "=0".characters, at: equation.EquString.endIndex)
            }
            self.equation.WorkingRange = equation.getOtherSideRange()!
            result = try solveEquation()
            try solveForVariable(equationRange: equation.getVariableRange()!, equals: result!)
        }
        else {
            if equation.getEqualsIndex() == nil {
                self.equation.WorkingRange = equation.EquString.startIndex..<equation.EquString.endIndex
                _ = try solveEquation()
            }
            else {
                self.equation.WorkingRange = equation.EquString.startIndex..<equation.getEqualsIndex()!
                let res1 = try solveEquation()
                self.equation.WorkingRange = equation.EquString.index(equation.getEqualsIndex()!, offsetBy: 1)..<equation.EquString.endIndex
                var res2 = try solveEquation()
                if (res1 != 0) {
                    res2 = res2-res1
                    equation.Steps.append("=" + String(res2))
                }
            }
        }
        return equation
    }
    private func solveForVariable(equationRange: Range<String.Index>, equals: Double) throws {
        self.equation.WorkingRange = equationRange
        var result = equals
        while let bracketRange = findInnerBracket() {
            if bracketRange.contains(self.equation.getVarIndex()) {
                self.equation.Replacements.append(self.equation.EquString[bracketRange])
                self.equation.EquString.removeSubrange(bracketRange)
                self.equation.EquString.insert(self.equation.SolveFor!, at: bracketRange.lowerBound)
            }
            else {
                self.equation.WorkingRange = bracketRange
                _ = try solveEquation()
            }
            self.equation.WorkingRange = self.equation.getVariableRange()
        }
        
        result = try isolateVariable(equals: result)
        if (self.equation.Replacements.count != 0) {
            for index in 0..<self.equation.Replacements.count {
                var rep = self.equation.Replacements.reversed()[index]
                rep.remove(at: rep.index(rep.endIndex, offsetBy: -1))
                rep.remove(at: rep.startIndex)
                self.equation.EquString = rep + "=" + String(result)
                self.equation.Replacements[(self.equation.Replacements.count-1)-index] = ""
                result = try isolateVariable(equals: result)
            }
        }
    }

    private func isolateVariable(equals: Double) throws -> Double {
        var result = equals
        var done: Bool = false
        while !done {
            var equRange = self.equation.getVariableRange()!
            var res: Double!
            let compare = self.equation.EquString
            if let minusRange = self.equation.EquString.range(of: "((" + expressionRegex + ")+\\-" + numberRegex + ")|(" + numberRegex + "\\-(" + expressionRegex + "))", options: .regularExpression, range: equRange) {
                let minusIndex = self.equation.EquString.range(of: "-", range: self.equation.EquString.index(after: minusRange.lowerBound)..<minusRange.upperBound)?.lowerBound
                if (self.equation.getVarIndex() < self.equation.EquString.index(after: minusIndex!)) {
                    self.equation.WorkingRange = self.equation.EquString.index(after: minusIndex!)..<equRange.upperBound
                    res = try solveEquation()
                    equRange = self.equation.getVariableRange()!
                    self.equation.EquString.removeSubrange(minusIndex!..<equRange.upperBound)
                    result = res + result
                }
                else {
                    self.equation.WorkingRange = equRange.lowerBound..<minusIndex!
                    res = try solveEquation()
                    self.equation.EquString.removeSubrange(equRange.lowerBound..<self.equation.EquString.index(after: minusIndex!))
                    result = res - result
                }
            }
            else if let plusRange = self.equation.EquString.range(of: "((" + expressionRegex + ")+\\+" + numberRegex + ")|(" + numberRegex + "\\+(" + expressionRegex + "))", options: .regularExpression, range: equRange) {
                let plusIndex = self.equation.EquString.range(of: "+", range: self.equation.EquString.index(after: plusRange.lowerBound)..<plusRange.upperBound)?.lowerBound
                if (self.equation.getVarIndex() < self.equation.EquString.index(after: plusIndex!)) {
                    self.equation.WorkingRange = self.equation.EquString.index(after: plusIndex!)..<equRange.upperBound
                    res = try solveEquation()
                    equRange = self.equation.getVariableRange()!
                    self.equation.EquString.removeSubrange(plusIndex!..<equRange.upperBound)
                }
                else {
                    self.equation.WorkingRange = equRange.lowerBound..<plusIndex!
                    res = try solveEquation()
                    self.equation.EquString.removeSubrange(equRange.lowerBound..<self.equation.EquString.index(after: plusIndex!))
                }
                result = result - res
            }
            else if let multiRange = self.equation.EquString.range(of: "((" + expressionRegex + ")+\\*" + numberRegex + ")|(" + numberRegex + "\\*(" + expressionRegex + "))", options: .regularExpression, range: equRange) {
                let multiIndex = self.equation.EquString.range(of: "*", range: multiRange)?.lowerBound
                if (self.equation.getVarIndex() < self.equation.EquString.index(after: multiIndex!)) {
                    self.equation.WorkingRange = self.equation.EquString.index(after: multiIndex!)..<equRange.upperBound
                    res = try solveEquation()
                    equRange = self.equation.getVariableRange()!
                    self.equation.EquString.removeSubrange(multiIndex!..<equRange.upperBound)
                }
                else {
                    self.equation.WorkingRange = equRange.lowerBound..<multiIndex!
                    res = try solveEquation()
                    self.equation.EquString.removeSubrange(equRange.lowerBound..<self.equation.EquString.index(after: multiIndex!))
                }
                result = result/res
            }
            else if let divideRange = self.equation.EquString.range(of: "((" + expressionRegex + ")+\\/" + numberRegex + ")|(" + numberRegex + "\\/(" + expressionRegex + "))", options: .regularExpression, range: equRange) {
                let divideIndex = self.equation.EquString.range(of: "/", range: divideRange)?.lowerBound
                if (self.equation.getVarIndex() < self.equation.EquString.index(after: divideIndex!)) {
                    self.equation.WorkingRange = self.equation.EquString.index(after: divideIndex!)..<equRange.upperBound
                    res = try solveEquation()
                    equRange = self.equation.getVariableRange()!
                    self.equation.EquString.removeSubrange(divideIndex!..<equRange.upperBound)
                    result = result*res
                }
                else {
                    self.equation.WorkingRange = equRange.lowerBound..<divideIndex!
                    res = try solveEquation()
                    self.equation.EquString.removeSubrange(equRange.lowerBound..<self.equation.EquString.index(after: divideIndex!))
                    result = res/result
                }
            }
            else if let caretRange = self.equation.EquString.range(of: "((" + expressionRegex + ")+\\^" + numberRegex + ")|(" + numberRegex + "\\^(" + expressionRegex + "))", options: .regularExpression, range: equRange) {
                let caretIndex = self.equation.EquString.range(of: "^", range: caretRange)?.lowerBound
                if (self.equation.getVarIndex() < self.equation.EquString.index(after: caretIndex!)) {
                    self.equation.WorkingRange = self.equation.EquString.index(after: caretIndex!)..<equRange.upperBound
                    res = try solveEquation()
                    equRange = self.equation.getVariableRange()!
                    self.equation.EquString.removeSubrange(caretIndex!..<equRange.upperBound)
                    result = pow(result, (1/res))
                }
                else {
                    self.equation.WorkingRange = equRange.lowerBound..<caretIndex!
                    res = try solveEquation()
                    self.equation.EquString.removeSubrange(equRange.lowerBound..<self.equation.EquString.index(after: caretIndex!))
                    result = log2(result)/log2(res)
                }
            }
            else {
                done = true
            }
            if (compare != self.equation.EquString) {
                self.equation.EquString.removeSubrange(self.equation.getOtherSideRange()!)
                self.equation.EquString.insert(contentsOf: String(result).characters, at: self.equation.getOtherSideRange()!.lowerBound)
                self.equation.addStep()
            }
        }
        return result
    }
    
    private func solveEquation() throws -> Double {
        var result: Double?
        var done: Bool = false
        var count: Int = 0;
        while !done {
            while let test = findInnerBracket() {
                let replacement = try resolveAndReplace()
                if (self.equation.EquString != replacement) {
                    self.equation.EquString = replacement
                    self.equation.addStep()
                }
                else {
                    self.equation.EquString.remove(at: replacement.index(test.upperBound, offsetBy: -1))
                    self.equation.EquString.remove(at: test.lowerBound)
                    self.equation.WorkingRange = self.equation.WorkingRange!.lowerBound..<replacement.index(self.equation.WorkingRange!.upperBound, offsetBy: -2)
                }
            }
            let replacement = try resolveAndReplace()
            if (self.equation.EquString != replacement) {
//                self.equation.Steps.append(replacement)
                self.equation.EquString = replacement
                self.equation.addStep()
            }
            if let res = Double(self.equation.EquString[self.equation.WorkingRange!]) {
                done = true
                result = res
            }
            count += 1
            if (count == 100) {
                throw EquationErrors.invalidEquation
            }
        }
        return result!
    }
    private func resolveAndReplace() throws -> String {
        var equ = self.equation.EquString
        var equ2 = equ[self.equation.WorkingRange!]
        var filterRange = self.equation.WorkingRange!
        if let brackets = findInnerBracket() {
            filterRange = brackets
        }
        var expRange: Range<String.Index>?
        var result: Double?
        
        if let exRange = equ.range(of: "([0-9]+(\\.?[0-9]+)?)\\^([0-9]+(\\.?[0-9]+)?)", options: .regularExpression, range: self.equation.WorkingRange!.clamped(to: filterRange)) {
            let testString = equ[exRange]
            let filterString = equ[filterRange]
            let filterRange2 = equ2.range(of: filterString)
            expRange = equ2.range(of: testString, range: filterRange2)
            if let exIndex = equ.range(of: "^", range: exRange)?.lowerBound {
                let opp1 = Double(equ[exRange.lowerBound..<exIndex])
                let opp2 = Double(equ[equ.index(exIndex, offsetBy: 1)..<exRange.upperBound])
                if (opp1 != nil && opp2 != nil) {
                    result = pow(opp1!, opp2!)
                }
                else {
                    throw EquationErrors.invalidEquation
                }
            }
            
        }
        else if let exRange = equ.range(of: "([0-9]+(\\.?[0-9]+)?)\\/([0-9]+(\\.?[0-9]+)?)", options: .regularExpression, range: self.equation.WorkingRange!.clamped(to: filterRange)) {
            let testString = equ[exRange]
            let filterString = equ[filterRange]
            let filterRange2 = equ2.range(of: filterString)
            expRange = equ2.range(of: testString, range: filterRange2)
            if let exIndex = equ.range(of: "/", range: exRange)?.lowerBound {
                let opp1 = Double(equ[exRange.lowerBound..<exIndex])
                let opp2 = Double(equ[equ.index(exIndex, offsetBy: 1)..<exRange.upperBound])
                if (opp1 != nil && opp2 != nil) {
                    result = opp1!/opp2!
                }
                else {
                    throw EquationErrors.invalidEquation
                }
            }
            
        }
        else if let exRange = equ.range(of: "([0-9]+(\\.?[0-9]+)?)\\*([0-9]+(\\.?[0-9]+)?)", options: .regularExpression, range: self.equation.WorkingRange!.clamped(to: filterRange)) {
            let testString = equ[exRange]
            let filterString = equ[filterRange]
            let filterRange2 = equ2.range(of: filterString)
            expRange = equ2.range(of: testString, range: filterRange2)
            if let exIndex = equ.range(of: "*", range: exRange)?.lowerBound {
                let opp1 = Double(equ[exRange.lowerBound..<exIndex])
                let opp2 = Double(equ[equ.index(exIndex, offsetBy: 1)..<exRange.upperBound])
                if (opp1 != nil && opp2 != nil) {
                    result = opp1!*opp2!
                }
                else {
                    throw EquationErrors.invalidEquation
                }
            }
            
        }
        else if let exRange = equ.range(of: "([0-9]+(\\.?[0-9]+)?)\\+([0-9]+(\\.?[0-9]+)?)", options: .regularExpression, range: self.equation.WorkingRange!.clamped(to: filterRange)) {
            let testString = equ[exRange]
            let filterString = equ[filterRange]
            let filterRange2 = equ2.range(of: filterString)
            expRange = equ2.range(of: testString, range: filterRange2)
            if let exIndex = equ.range(of: "+", range: equ.index(after: exRange.lowerBound)..<exRange.upperBound)?.lowerBound {
                let opp1 = Double(equ[exRange.lowerBound..<exIndex])
                let opp2 = Double(equ[equ.index(exIndex, offsetBy: 1)..<exRange.upperBound])
                if (opp1 != nil && opp2 != nil) {
                    result = opp1!+opp2!
                }
                else {
                    throw EquationErrors.invalidEquation
                }
            }
            
        }
        else if let exRange = equ.range(of: "([0-9]+(\\.?[0-9]+)?)\\-([0-9]+(\\.?[0-9]+)?)", options: .regularExpression, range: self.equation.WorkingRange!.clamped(to: filterRange)) {
            let testString = equ[exRange]
            let filterString = equ[filterRange]
            let filterRange2 = equ2.range(of: filterString)
            expRange = equ2.range(of: testString, range: filterRange2)
            if let exIndex = equ.range(of: "-", range: equ.index(after: exRange.lowerBound)..<exRange.upperBound)?.lowerBound {
                let opp1 = Double(equ[exRange.lowerBound..<exIndex])
                let opp2 = Double(equ[equ.index(exIndex, offsetBy: 1)..<exRange.upperBound])
                if (opp1 != nil && opp2 != nil) {
                    result = opp1!-opp2!
                }
                else {
                    throw EquationErrors.invalidEquation
                }
            }
        }
        
        if (expRange != nil && result != nil) {
            equ2.removeSubrange(expRange!)
            equ2.insert(contentsOf: String(result!).characters, at: (expRange?.lowerBound)!)
            equ.removeSubrange(self.equation.WorkingRange!)
            equ.insert(contentsOf: equ2.characters, at: self.equation.WorkingRange!.lowerBound)

            if let newWRange = equ.range(of: equ2, range: self.equation.WorkingRange!.lowerBound..<equ.endIndex) {
                self.equation.WorkingRange = newWRange
            }
        }
        return equ
    }

    
    private func removeWhitespace(equation: String) -> String {
        var equ = equation
        var done: Bool = false
        while !done {
            if let range = equ.range(of : "\\ ", options: .regularExpression) {
                equ.remove(at: range.lowerBound)
            }
            else {
                done = true
            }
        }
        return equ
    }
    private func findInnerBracket() -> Range<String.Index>? {
        if let index = self.equation.EquString.range(of: ")", range: self.equation.WorkingRange!)?.lowerBound {
            var done: Bool = false
            var offset: Int = -1
            while !done {
                let pIndex: String.Index = self.equation.EquString.index(index, offsetBy: offset)
                let test = self.equation.EquString[pIndex]
                if (test == "(") {
                    done = true
                    return pIndex ..< self.equation.EquString.index(index, offsetBy: 1)
                }
                if (pIndex == self.equation.EquString.startIndex) {
                    done = true
                }
                else {
                    offset -= 1
                }
            }
        }
        return nil
    }
    private func insertAllAsterisks(equation: String) -> String {
        var equ = equation
        let rightVar: String = "\\)([a-z]|[A-Z]|[0-9])"
        let leftVar: String = "([a-z]|[A-Z]|[0-9])\\("
        let brackets: String = "\\)\\("
        let variableLeft: String = "([a-z]|[A-Z])[0-9]"
        let variableRight: String = "[0-9]([a-z]|[A-Z])"
        let negativeBracket: String = "\\-\\("
        var done: Bool = false
        while !done {
            if let range = equ.range(of: rightVar, options: .regularExpression) {
                equ = insertAsterisk(equation: equ, range: range, fromLeft: true)
            }
            else if let range = equ.range(of: leftVar, options: .regularExpression) {
                equ = insertAsterisk(equation: equ, range: range, fromLeft: false)
            }
            else if let range = equ.range(of: brackets, options: .regularExpression) {
                equ = insertAsterisk(equation: equ, range: range, fromLeft: true)
            }
            else if let range = equ.range(of: variableLeft, options: .regularExpression) {
                equ = insertAsterisk(equation: equ, range: range, fromLeft: true)
            }
            else if let range = equ.range(of: variableRight, options: .regularExpression) {
                equ = insertAsterisk(equation: equ, range: range, fromLeft: true)
            }
            else if let range = equ.range(of: negativeBracket, options: .regularExpression) {
                equ.insert(contentsOf: "1*".characters, at: equ.index(range.lowerBound, offsetBy: 1))
            }
            else {
                done = true
            }
        }
        return equ
    }
    
    private func insertAsterisk(equation: String, range: Range<String.Index>, fromLeft: Bool) -> String {
        var equ = equation
        var i: String.Index?
        
        if (fromLeft) {
            i = equ.index(range.lowerBound, offsetBy: 1)
        }
        else {
            i = equ.index(range.upperBound, offsetBy: -1)
        }
        equ.insert("*", at: i!)
        return equ
    }
    
    public func processPolynomial() -> Equation {
        let regex = "([a-z]|[A-Z]|([0-9]+(\\.?[0-9]+)?)|\\*|(\\/([0-9]+(\\.?[0-9]+)?))|(\\^([0-9]+(\\.?[0-9]+)?))|(\\(.*\\)))*([a-z]|[A-Z])([a-z]|[A-Z]|([0-9]+(\\.?[0-9]+)?)|\\*|(\\/([0-9]+(\\.?[0-9]+)?))|(\\^([0-9]+(\\.?[0-9]+)?))|(\\(.*\\)))*"
        let letterRegex = "([a-z]|[A-Z])"
        var currentIndex = self.equation.EquString.startIndex
        let equ = self.equation.EquString
        while let range = equ.range(of: regex, options: .regularExpression, range: currentIndex..<equ.endIndex) {
            var polynomial = equ[range]
            var variable = "";
            for c in polynomial.characters {
                if String(c).range(of: letterRegex, options: .regularExpression) != nil {
                    variable += String(c)
                }
            }
            currentIndex = range.upperBound
            if let orgRange = self.equation.EquString.range(of: polynomial) {
                self.equation.polyReplacements.append(self.equation.EquString[orgRange])
                self.equation.EquString.removeSubrange(orgRange)
                self.equation.EquString.insert(contentsOf: variable.characters, at: orgRange.lowerBound)
            }
        }
        return self.equation;
    }
    
    public func processPolynomial2() -> Equation {
        let regex = "([a-z]|[A-Z]|[0-9]|\\.|\\*|\\^)"
        var indexes: [String.Index] = []
        for c in self.equation.Variables {
            var index = self.equation.EquString.range(of: String(c))?.lowerBound
            while indexes.contains(index!) {
                index = self.equation.EquString.range(of: String(c), range: self.equation.EquString.index(after: index!)..<self.equation.EquString.endIndex)?.lowerBound
            }
            var upperIndex: String.Index? = self.equation.EquString.index(after: index!)
            var lowerIndex: String.Index? = index!
            var foundUpper: Bool = false
            while !foundUpper {
                if (upperIndex! == equation.EquString.endIndex) {
                    foundUpper = true
                }
                else {
                    let test = String(equation.EquString[upperIndex!])
                    if test.range(of: regex, options: .regularExpression) != nil {
                        upperIndex = equation.EquString.index(after: upperIndex!)
                    }
                    else {
                        foundUpper = true
                    }
                }
            }
            var foundLower: Bool = false
            while !foundLower {
                if (lowerIndex! == equation.EquString.startIndex) {
                    foundLower = true
                }
                else {
                    let lIndex: String.Index = equation.EquString.index(before: lowerIndex!)
                    let test = String(equation.EquString[lIndex])
                    if test.range(of: regex, options: .regularExpression) != nil {
                        lowerIndex = lIndex
                    }
                    else {
                        foundLower = true
                    }
                }
            }
            if (foundLower && foundUpper) {
                let polyRange = lowerIndex!..<upperIndex!
                self.equation.polyReplacements.append(self.equation.EquString[polyRange])
                self.equation.EquString.removeSubrange(polyRange)
                self.equation.EquString.insert(contentsOf: String(c).characters, at: polyRange.lowerBound)
                indexes.append(polyRange.lowerBound)
            }
        }
        return self.equation
    }
    
    enum EquationErrors: Error {
        case invalidEquation
    }

}
