//
//  EquationAddController.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-04-15.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import UIKit
import SQLite

class EquationAddController: UIViewController {

    var id: Int64?
    var equation: Equation?
    var variables: [String]?
    
    @IBOutlet var eName: UITextField!
    @IBOutlet var eString: UITextField!
    @IBOutlet var eDescription: UITextView!
    @IBOutlet var saveButton: UIButton!
    
    @IBAction func buttonClick(_ sender: Any) {
        if (self.id != nil) {
            updateEquation()
        }
        else {
            addEquation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.applyGradient(colours: [UIColor(red: 0.18, green: 0.28, blue: 0.34, alpha: 1), UIColor.white], locations: [0.0, 0.7])
        if (self.id != nil) {
            let connection = DBService().getConnection()
            let db = EquationRepo(db: connection)
            equation = db.getEquation(cId: self.id!)
        }
        if (equation != nil) {
            eName.text = equation!.name
            eString.text = equation!.EquString
            eDescription.text = equation!.description
            saveButton.setTitle("UPDATE!", for: UIControlState.normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateEquation() {
        print("Update")
        let dbService = DBService()
        var db: Connection?
        db = dbService.getConnection()
        let eRepo = EquationRepo(db: db!)
        let result = eRepo.updateEquation(cId: equation!.id!, newEquation: Equation(id: equation!.id!, name: eName.text!, description: eDescription.text, equationStr: eString.text!))
        if (result) {
            resetForm()
            performSegue(withIdentifier: "backToList", sender: self)
        }
    }
    
    func addEquation() {
        print("Add")
        let dbService = DBService()
        var db: Connection?
        db = dbService.getConnection()
        let eRepo = EquationRepo(db: db!)
        let id = eRepo.addEquation(cName: eName.text!, cDescription: eDescription.text, cEquation: eString.text!)
        if (id != -1) {
            resetForm()
            performSegue(withIdentifier: "backToList", sender: self)
        }
    }
    
    func resetForm() {
        eName!.text = ""
        eString!.text = ""
        eDescription!.text = ""
    }

}

