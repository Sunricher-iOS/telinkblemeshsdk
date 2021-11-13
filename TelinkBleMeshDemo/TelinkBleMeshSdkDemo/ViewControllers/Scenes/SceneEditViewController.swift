//
//  SceneEditViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/11/13.
//

import UIKit
import TelinkBleMesh

class SceneEditViewController: UITableViewController {
    
    var address: Int = 0
    var scene: MeshCommand.Scene!
    
    private let cellTypes: [CellType] = [
        .brightness, .red, .green, .blue,
        .ctOrW, .duration
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "edit".localization + String(format: " 0x%02X", address)
        
        let done = UIBarButtonItem(title: "done".localization, style: .done, target: self, action: #selector(self.doneAction))
        let delete = UIBarButtonItem(title: "delete".localization, style: .plain, target: self, action: #selector(self.deleteAction))
        
        navigationItem.rightBarButtonItems = [done, delete]
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellType = cellTypes[indexPath.row]
        showTextFieldAlert(cellType)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cellTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let cellType = cellTypes[indexPath.row]
        cell.textLabel?.text = cellType.title
        
        switch cellType {
            
        case .brightness: cell.detailTextLabel?.text = "\(scene.brightness)"
        case .red: cell.detailTextLabel?.text = "\(scene.red)"
        case .green: cell.detailTextLabel?.text = "\(scene.green)"
        case .blue: cell.detailTextLabel?.text = "\(scene.blue)"
        case .ctOrW: cell.detailTextLabel?.text = "\(scene.ctOrW)"
        case .duration: cell.detailTextLabel?.text = "\(scene.duration)"
        }
        
        return cell
    }

    private func showTextFieldAlert(_ cellType: CellType) {
        
        let alert = UIAlertController(title: "Input Value", message: nil, preferredStyle: .alert)
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alert.popoverPresentationController?.sourceView = view
        
        var textField: UITextField!
        alert.addTextField { tf in
            textField = tf
            textField.keyboardType = .numberPad
            textField.autocorrectionType = .no
        }
        
        let done = UIAlertAction(title: "done".localization, style: .default) { _ in
            
            guard let valueString = textField.text, let value = Int(valueString) else { return }
            
            switch cellType {
                
            case .brightness: self.scene.brightness = value
            case .red: self.scene.red = value
            case .green: self.scene.green = value
            case .blue: self.scene.blue = value
            case .ctOrW: self.scene.ctOrW = value
            case .duration: self.scene.duration = value
            }
            
            self.tableView.reloadData()
        }
        
        let cancel = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        
        alert.addAction(done)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func doneAction() {
        
        MeshCommand.addOrUpdateScene(address, scene: scene).send()
    }
    
    @objc private func deleteAction() {
        
        MeshCommand.deleteScene(address, sceneID: scene.sceneID).send()
    }

}

extension SceneEditViewController {
    
    private enum CellType {
        
        case brightness
        case red
        case green
        case blue
        case ctOrW
        case duration
        
        var title: String {
            
            switch self {
                
            case .brightness: return "Brightness"
            case .red: return "Red"
            case .green: return "Green"
            case .blue: return "Blue"
            case .ctOrW: return "CT or White"
            case .duration: return "Duration"
            }
        }
    }
    
}
