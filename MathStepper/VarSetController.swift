//
//  VarSetController.swift
//  MathStepper
//
//  Created by Curtis Hewlett on 2017-04-19.
//  Copyright © 2017 Curtis Hewlett. All rights reserved.
//

import UIKit

class VarSetController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var engine: EquationEngine?
    var pickerData: [String] = [String]()
    var views: [UIView] = []
    @IBOutlet var varPicker: UIPickerView!
    @IBOutlet var equationLabel: UILabel!
    @IBOutlet var setButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.applyGradient(colours: [UIColor(red: 0.18, green: 0.28, blue: 0.34, alpha: 1), UIColor.white], locations: [0.0, 0.7])
        setButton.backgroundColor = UIColor.white
        setButton.layer.cornerRadius = 5
        cancelButton.backgroundColor = UIColor.white
        cancelButton.layer.cornerRadius = 5
        varPicker.backgroundColor = UIColor.white
        pickerData = engine!.equation.Variables.map({ (char) -> String in
            return String(char)
        })
        varPicker.delegate = self
        varPicker.dataSource = self
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        setInputs(Skip: 0)
        equationLabel.text = engine!.equation.EquString
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfComponents(in: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        setInputs(Skip: row)
    }
    
    private func setInputs(Skip: Int) {
        for v in views {
            v.viewWithTag(v.tag)?.removeFromSuperview()
        }
        views = []
        var tag = 0
        var count = 1
        for index in 0..<pickerData.count {
            if (index != Skip) {
                let label = UILabel(frame: CGRect(x: 40, y: (400+25*count), width: 20, height: 20))
                label.text = pickerData[index]
                label.tag = tag
                tag += 1
                views.append(label)
                self.view.addSubview(label)
                
                let inputCG = CGRect(x: 60, y: (400+25*count), width: 40, height: 20)
                let input = UITextField(frame: inputCG)
                let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
                input.layer.borderWidth = 0.5
                input.layer.borderColor = borderColor.cgColor
                input.backgroundColor = UIColor.white
                input.tag = tag
                tag += 1
                views.append(input)
                self.view.addSubview(input)
                
                count += 1
            }
            else {
                engine?.equation.SolveFor = engine?.equation.Variables[index]
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        if (segue.identifier == "replaceVars") {
            let vc  = segue.destination as! ViewController
            for char in engine!.equation.Variables {
                if (char != engine!.equation.SolveFor) {
                    var value = ""
                    for v in views {
                        if v is UILabel {
                            let testView = v as! UILabel
                            let label = testView.text!
                            let currentVar = String(char)
                            if (label == currentVar) {
                                let input = self.view.viewWithTag(v.tag + 1)
                                if input is UITextField {
                                    let input2 = input as! UITextField
                                    if let t = input2.text {
                                        value = t
                                    }
                                }
                            }
                        }
                    }
                    engine!.equation.replaceVar(Variable: char, With: "(\(value))")
                }
            }
            vc.engine = engine!
        } else if (segue.identifier == "cancelVars") {
            let vc = segue.destination as! ViewController
            vc.engine = engine!
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
