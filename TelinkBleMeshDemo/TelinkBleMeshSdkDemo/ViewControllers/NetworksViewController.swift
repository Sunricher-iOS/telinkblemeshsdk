//
//  NetworksViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/1/14.
//

import UIKit
import TelinkBleMesh

class NetworksViewController: UITableViewController {
    
    private var networks: [MeshNetwork]!
    
    var nameTextField: UITextField?
    var passwordTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "networks".localization
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItemAction))
        navigationItem.rightBarButtonItem = addItem
        
        networks = NetworkManager.shared.networks
    }
    
    @objc func addItemAction() {
        
        let alertController = UIAlertController(title: "add_network".localization, message: nil, preferredStyle: .alert)
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        
        alertController.addTextField { (textField) in
            
            textField.keyboardType = .asciiCapable
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "network_name".localization
            textField.returnKeyType = .next
            textField.addTarget(self, action: #selector(self.nameTextFieldDidEndOnExitAction), for: .editingDidEndOnExit)
            
            self.nameTextField = textField
        }
        
        alertController.addTextField { (textField) in
            
            textField.keyboardType = .asciiCapableNumberPad
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "network_password".localization
            textField.returnKeyType = .done
            
            self.passwordTextField = textField
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        let addAction = UIAlertAction(title: "add".localization, style: .default) { (action) in
            
            guard let name = self.nameTextField?.text,
                  let password = self.passwordTextField?.text else {
                return
            }
            
            guard let network = MeshNetwork(name: name, password: password) else { return }
                        
            self.networks = NetworkManager.shared.addNetwork(network)
            self.tableView.reloadData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(addAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func nameTextFieldDidEndOnExitAction() {
        
        passwordTextField?.becomeFirstResponder()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let controller = NetworkViewController(style: .grouped)
        controller.network = networks[indexPath.row]
        controller.hidesBottomBarWhenPushed = true 
        navigationController?.pushViewController(controller, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return networks.count
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard editingStyle == .delete else { return }
        
        _ = NetworkManager.shared.removeNetwork(networks[indexPath.row])
        networks.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let network = networks[indexPath.row]
        cell.textLabel?.text = network.name
        cell.detailTextLabel?.text = network.password
        
        return cell
    }

}
