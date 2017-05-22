//
//  EquationListController.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-04-15.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import UIKit
import SQLite

class EquationListController: UITableViewController {

    var equations = [Equation]()
    var alpha: Bool = true;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsets(top: 20,left: 0,bottom: 0,right: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let dbService = DBService()
        var db: Connection?
        db = dbService.getConnection()
        
        let eRepo = EquationRepo(db: db!)
        
        eRepo.createTable()
        if (eRepo.getEquations().count == 0) {
            //_ = eRepo.addEquation(
            //    cName: "Circle Circumference",
            //    cDescription: "Equation to find the circumference of a circle",
            //    cEquation: "C = 2πr")
            //_ = eRepo.addEquation(
            //    cName: "Pythagorean Theorem",
            //    cDescription: "Find the length of any one side of a Right Triangle where 'c' is the hypotenuse",
            //    cEquation: "a^2 + b^2 = c^2")
            _ = eRepo.addEquation(
                cName: "Test seed equation",
                cDescription: "Test equation",
                cEquation: "(2-(x^2-4)*9)=-12")
        }
        equations = eRepo.getEquations()
        let defaults = UserDefaults.standard
        if (defaults.bool(forKey: "sortingSet")) {
            alpha = defaults.bool(forKey: "alpha")
        }
        if (alpha) {
            equations.sort {
                return $0.name < $1.name
            }
        }
        else {
            equations.sort {
                return $0.name > $1.name
            }
            
        }
        self.tableView.reloadData()
        print("did appear");
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return equations.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "equationCell", for: indexPath)
        cell.textLabel?.text = equations[indexPath.row].name
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        if (segue.identifier == "toDetail") {
            if let indexPath = tableView.indexPathForSelectedRow {
                let vc  = segue.destination as! EquationDetailController
                vc.id = equations[indexPath.row].id
            }
        }
    }

}
