//
//  EquationRepo.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-04-15.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import Foundation
import SQLite

class EquationRepo {
    let dbService = DBService()
    var db: Connection?
    
    private var equations       = Table("equations")
    private var id              = Expression<Int64>("id")
    private var name            = Expression<String>("name")
    private var description     = Expression<String>("description")
    private var equationStr     = Expression<String>("equationStr")
    
    init(db: Connection) {
        self.db = db;
    }
    
    func createTable() {
        db = dbService.getConnection()
        do {
            try db!.run(equations.create(ifNotExists: true) {
                table in
                table.column(id, primaryKey: true)
                table.column(name)
                table.column(description)
                table.column(equationStr)
            })
        } catch {
            print("Unable to create table");
        }
    }
    
    func addEquation(cName: String, cDescription: String, cEquation: String) -> Int64? {
        do {
            let insert = equations.insert(name <- cName, description <- cDescription, equationStr <- cEquation)
            let id = try db!.run(insert)
            return id
        } catch {
            print("Insert failed")
            return -1
        }
    }
    
    func getEquations() -> [Equation] {
        var equations = [Equation]()
        do {
            for equation in try db!.prepare(self.equations) {
                equations.append(Equation(
                    id:             equation[id],
                    name:           equation[name],
                    description:    equation[description],
                    equationStr:    equation[equationStr]))
            }
        } catch {
            print("Select Failed")
        }
        return equations
    }
    
    func getEquation(cId: Int64) -> Equation {
        var equations = [Equation]()
        do {
            for equation in try db!.prepare(self.equations.filter(id == cId)) {
                equations.append(Equation(
                    id:             equation[id],
                    name:           equation[name],
                    description:    equation[description],
                    equationStr:    equation[equationStr]))
            }
        } catch {
            print("Select Failed")
        }
        return equations[0]
    }
    
    func deleteEquation(cId: Int64) -> Bool {
        do {
            let equation = equations.filter(id == cId)
            try db!.run(equation.delete())
            return true
        } catch {
            print("Delete Failed")
            return false
        }
    }
    
    func updateEquation(cId: Int64, newEquation: Equation) -> Bool {
        let equation = equations.filter(id == cId)
        do {
            let update = equation.update([
                name <- newEquation.name,
                description <- newEquation.description,
                equationStr <- newEquation.EquString])
            if try db!.run(update) > 0 {
                return true
            }
        } catch {
            print("Update failed: \(error)")
        }
        return false
    }
}
