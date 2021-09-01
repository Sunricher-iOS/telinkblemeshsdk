//
//  LightRunningAddColorViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/9/1.
//

import UIKit
import TelinkBleMesh
import Toast

class LightRunningAddColorViewController: UITableViewController {
    
    var address: Int!
    var modeId: Int!
    
    private var colors: [Int: MeshCommand.LightRunningMode.Color?] = [
        0: nil, 1: nil, 2: nil, 3: nil, 4: nil
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Color"
        
        let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.saveAction))
        navigationItem.rightBarButtonItem = saveItem
    }
    
    @objc private func saveAction() {
        
        var values: [MeshCommand.LightRunningMode.Color] = []
        colors.values.forEach {
            
            if let value = $0 {
                
                values.append(value)
            }
        }
        
        guard values.count > 0 else { return }
        
        view.makeToast("Saving \(values.count)...", duration: 0.5 * Double(values.count), position: .center)
        
        let commands = MeshCommand.updateLightRunningCustomModeColors(address, modeId: modeId, colors: values)
        commands.forEach {
            
            $0.send()
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let alert = UIAlertController(title: "Select color", message: nil, preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        
        var redTextField: UITextField!
        var greenTextField: UITextField!
        var blueTextField: UITextField!
        
        alert.addTextField { textField in
            
            redTextField = textField
            textField.keyboardType = .numberPad
            textField.placeholder = "Red [0, 255]"
        }
        
        alert.addTextField { textField in
            
            greenTextField = textField
            textField.keyboardType = .numberPad
            textField.placeholder = "Green [0, 255]"
        }
        
        alert.addTextField { textField in
            
            blueTextField = textField
            textField.keyboardType = .numberPad
            textField.placeholder = "Blue [0, 255]"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            
            let red = Int(redTextField.text ?? "0") ?? 0
            let green = Int(greenTextField.text ?? "0") ?? 0
            let blue = Int(blueTextField.text ?? "0") ?? 0
            
            let color = MeshCommand.LightRunningMode.Color(red: UInt8(red), green: UInt8(green), blue: UInt8(blue))
            self?.colors[indexPath.row] = color
            self?.tableView.reloadData()
        }
        
        let clearAction = UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            
            self?.colors[indexPath.row] = nil
            self?.tableView.reloadData()
        }
        
        alert.addAction(okAction)
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 5
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.textLabel?.text = "Color \(indexPath.row)"
        cell.contentView.backgroundColor = colors[indexPath.row]??.uiColor ?? .clear
        
        return cell
    }

}
