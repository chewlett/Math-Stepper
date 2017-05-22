//
//  DBService.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-04-15.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import Foundation
import SQLite

class DBService {
    let DBNAME = "Stephencelis.sqlite3"
    
    func getConnection() -> Connection {
        var db: Connection?
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        print(path)
        do {
            db = try Connection("\(path)/" + DBNAME)
        } catch {
            db = nil
        }
        return db!
    }
}
