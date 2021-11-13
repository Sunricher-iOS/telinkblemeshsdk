//
//  ScenesTableViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/11/12.
//

import UIKit
import TelinkBleMesh

class ScenesTableViewController: UITableViewController {
    
    var addresses: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "scenes".localization
        
        let clear = UIBarButtonItem(title: "clear".localization, style: .done, target: self, action: #selector(self.clearAction))
        navigationItem.rightBarButtonItem = clear
    }
    
    @objc private func clearAction() {
        
        MeshCommand.clearScenes(MeshCommand.Address.all).send()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sceneID = indexPath.row + 1
        MeshCommand.loadScene(MeshCommand.Address.all, sceneID: sceneID).send()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 16
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let edit = UIContextualAction(style: .normal, title: "edit".localization) { action, view, handler in
            
            let controller = SceneTableViewController(style: .grouped)
            controller.addresses = self.addresses
            controller.sceneID = indexPath.row + 1
            self.navigationController?.pushViewController(controller, animated: true)

            handler(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [edit])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = "scene".localization + "\(indexPath.row + 1)"
        
        return cell
    }

}
