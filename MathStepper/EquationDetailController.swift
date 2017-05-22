//
//  EquationDetailController.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-04-15.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import UIKit
import SQLite

class EquationDetailController: UIViewController {

    var id: Int64?
    private var equation: Equation?
    
    @IBOutlet var eName: UILabel!
    @IBOutlet var eLabel: UILabel!
    @IBOutlet var eDescription: UITextView!
    @IBOutlet var useButton: UIButton!
    @IBAction func clickDelete(_ sender: Any) {
        confirmDelete()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.applyGradient(colours: [UIColor(red: 0.18, green: 0.28, blue: 0.34, alpha: 1), UIColor.white], locations: [0.0, 0.7])
        useButton.backgroundColor = UIColor.white
        useButton.layer.cornerRadius = 5
        if (self.id != nil) {
            let connection = DBService().getConnection()
            let db = EquationRepo(db: connection)
            equation = db.getEquation(cId: self.id!)
        }
        if (equation != nil) {
            eName.text = equation!.name
            eLabel.text = equation!.EquString
            eDescription.text = equation!.description
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func confirmDelete() {
        let alert = UIAlertController(title: "Delete?",
                                      message: "Are you sure you want to delete this equation?",
                                      preferredStyle: .alert)
        let firstAction = UIAlertAction(title: "Delete", style: .default) {
            (alert: UIAlertAction!) -> Void in
            self.deleteEquation()
        }
        let secondAction = UIAlertAction(title: "Cancel", style: .default) {
            (alert: UIAlertAction!) -> Void in
            print("CANCELLED")
        }
        alert.addAction(firstAction)
        alert.addAction(secondAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func deleteEquation() {
        print("DELETE!")
        let dbService = DBService()
        var db: Connection?
        db = dbService.getConnection()
        let eRepo = EquationRepo(db: db!)
        let result = eRepo.deleteEquation(cId: equation!.id!)
        if (result) {
            performSegue(withIdentifier: "afterDelete", sender: self)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        if (segue.identifier == "toEdit") {
            let vc  = segue.destination as! EquationAddController
            vc.id = self.id
        }
        else if (segue.identifier == "useEquation") {
            let vs = segue.destination as! ViewController
            vs.equationString = self.eLabel.text!
        }
    }
    
}
