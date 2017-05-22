//
//  Equation.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-04-04.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import Foundation

class Equation {
    let regex = "([a-z]|[A-Z])"
    let OrgEquation: String
    let id: Int64?
    var name: String
    var description: String
    var EquString: String
    var Steps: [String]
    var Variables: [Character]
    var SolveFor: Character?
    var VarIndex: String.Index?
    var Replacements: [String]
    var polyReplacements: [String]
    var polynomial: Bool
    var WorkingRange: Range<String.Index>?
    
    init(id: Int64, name: String, description: String, equationStr: String) {
        self.id = id
        self.name = name
        self.description = description
        self.OrgEquation = equationStr
        self.EquString = equationStr
        self.Steps = [equationStr]
        self.Variables = []
        self.Replacements = []
        self.polyReplacements = []
        self.polynomial = false
        self.setVariables()
        if (Variables.count > 0) {
            SolveFor = Variables[0]
            VarIndex = equationStr.range(of: String(SolveFor!))?.lowerBound
        }
    }
    
    private func setVariables() {
        for c in OrgEquation.characters {
            if String(c).range(of: regex, options: .regularExpression) != nil {
                Variables.append(c)
            }
        }
        if (Variables.count > 1) {
            polynomial = true
        }
    }
    
    public func getVarIndex() -> String.Index {
        VarIndex = EquString.range(of: String(SolveFor!))?.lowerBound
        return VarIndex!
    }
    
    public func getVariableRange() -> Range<String.Index>? {
        if let equals = EquString.range(of: "=")?.lowerBound {
            if (getVarIndex() < equals) {
                return EquString.startIndex..<equals
            }
            else {
                return EquString.index(equals, offsetBy: 1)..<EquString.endIndex
            }

        }
        return nil
    }
    
    public func getOtherSideRange() -> Range<String.Index>? {
        if let equals = EquString.range(of: "=")?.lowerBound {
            if (getVarIndex() > equals) {
                return EquString.startIndex..<equals
            }
            else {
                return EquString.index(equals, offsetBy: 1)..<EquString.endIndex
            }
            
        }
        return nil
    }
    public func getEqualsIndex() -> String.Index? {
        if let equals = EquString.range(of: "=")?.lowerBound {
            return equals
        }
        else {
            return nil
        }
    }
    public func addStep() {
        var step = EquString
        for j in 0..<Replacements.count {
            if (Replacements.reversed()[j] != "") {
                let varIndex = step.range(of: String(SolveFor!))?.lowerBound
                step.remove(at: varIndex!)
                step.insert(contentsOf: Replacements.reversed()[j].characters, at: varIndex!)
            }
        }
        Steps.append(step)
    }
    public func replaceVar(Variable: Character, With: String) {
        if let replace = EquString.range(of: String(Variable))?.lowerBound {
            EquString.remove(at: replace)
            EquString.insert(contentsOf: With.characters, at: replace)
        }
    }
    
}
