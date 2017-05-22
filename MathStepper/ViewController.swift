//
//  ViewController.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-03-14.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,UITextFieldDelegate {

    var equationString: String?
    var steps: [String] = []
    var stepsHolder: [String] = []
    var stepping: Bool = false
    var stepIndex: Int = 0
    var engine: EquationEngine?
    
    @IBOutlet var uiTableView: UITableView!
    @IBOutlet var equInput: UITextField!
    @IBOutlet var solveButton: UIButton!
    @IBOutlet var stepButton: UIButton!
    
    @IBAction func stepThrough(_ sender: Any) {
        if (!stepping) {
            steps = []
            stepIndex = 0
            stepping = true
            let equation: String = equInput.text!
            engine = EquationEngine(equation: equation)
            if (engine!.equation.polynomial) {
                if (engine!.validateEquation(equation: equation)) {
                    performSegue(withIdentifier: "setVariables", sender: self)
                }
                else {
                    displayError(error: "Invalid Equation")
                }
            }
            else {
                do {
                    stepsHolder = try engine!.processEquation().Steps
                    steps.append(stepsHolder[stepIndex])
                    stepIndex += 1
                } catch EquationEngine.EquationErrors.invalidEquation {
                    displayError(error: "Invalid Equation")
                } catch {
                    displayError(error: "Invalid Equation")
                }
            }
            uiTableView.reloadData()
        }
        else {
            if (stepsHolder.count != 0) {
                if (stepIndex < stepsHolder.count) {
                    steps.insert(stepsHolder[stepIndex], at: 0)
                    stepIndex += 1
                    uiTableView.reloadData()
                }
                else {
                    steps.insert("DONE!", at: 0)
                    uiTableView.reloadData()
                    stepping = false
                }
            }
        }
    }
    @IBAction func solve(_ sender: Any) {
        if (!stepping) {
            let equation: String = equInput.text!
            engine = EquationEngine(equation: equation)
            //steps.append(engine.processPolynomial().EquString)
            if (engine!.equation.polynomial) {
                if (engine!.validateEquation(equation: equation)) {
                    performSegue(withIdentifier: "setVariables", sender: self)
                }
                else {
                    displayError(error: "Invalid Equation")
                }
            }
            else {
                do {
                    steps = try engine!.processEquation().Steps.reversed()
                } catch EquationEngine.EquationErrors.invalidEquation {
                    displayError(error: "Invalid Equation")
                } catch {
                    displayError(error: "Invalid Equation")
                }
                
                uiTableView.reloadData()
            }
            
        }
        else {
            for i in stepIndex..<stepsHolder.count {
                steps.insert(stepsHolder[i], at: 0)
            }
            uiTableView.reloadData()
            stepping = false
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.applyGradient(colours: [UIColor(red: 0.18, green: 0.28, blue: 0.34, alpha: 1), UIColor.white], locations: [0.0, 0.7])
        solveButton.backgroundColor = UIColor.white
        solveButton.layer.cornerRadius = 5
        stepButton.backgroundColor = UIColor.white
        stepButton.layer.cornerRadius = 5
        // Do any additional setup after loading the view, typically from a nib.
        self.uiTableView.register(UITableViewCell.self, forCellReuseIdentifier: "groupcell")
        self.equInput.delegate = self
        self.uiTableView.delegate = self
        self.uiTableView.dataSource = self
//        steps = ["one", "two", "three"];
    }
    override func viewDidAppear(_ animated: Bool) {
        if equationString != nil {
            equInput.text = equationString!
        }
        else if engine != nil {
            equationString = engine!.equation.EquString
            equInput.text = engine!.equation.EquString
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "step");
        cell?.textLabel!.text = steps[indexPath.row]
        return cell!
    }
    
    func displayError(error: String) {
        let alert = UIAlertController(title: "ERROR",
                                      message: error,
                                      preferredStyle: .alert)
        let firstAction = UIAlertAction(title: "Okay", style: .default) {
            (alert: UIAlertAction!) -> Void in
        }
//        let secondAction = UIAlertAction(title: "Cancel", style: .default) {
//            (alert: UIAlertAction!) -> Void in
//            print("CANCELLED")
//        }
        alert.addAction(firstAction)
//        alert.addAction(secondAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        if (segue.identifier == "setVariables") {
            let vc  = segue.destination as! VarSetController
            vc.engine = self.engine!
//            vc.preferredContentSize = CGSize(width: 200, height: 500)
        }
    }
    
}
extension UIView {
    func applyGradient(colours: [UIColor]) -> Void {
        self.applyGradient(colours: colours, locations: nil)
    }
    
    func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
}

