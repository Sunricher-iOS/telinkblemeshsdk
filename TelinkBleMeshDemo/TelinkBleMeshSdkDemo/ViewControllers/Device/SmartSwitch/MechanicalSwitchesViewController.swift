//
//  MechanicalSwitchesViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/3/2.
//

import UIKit
import TelinkBleMesh

class MechanicalSwitchesViewController: UITableViewController {
    
    var address: Int!
    
    private var switches: [Int: Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Mechanical Switches \(address.hex)"
        
        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(loadSwitches))
        navigationItem.rightBarButtonItem = refreshItem
        
        loadSwitches()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 8
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "DELETE") { action, _, completion in
            
            guard let switchId = self.switches[indexPath.row] else {
                
                return
            }
            
            MeshCommand.deleteSmartSwitchId(self.address, switchId: switchId).send()
            completion(false)
            
            self.loadSwitches()
        }
        
        let conf = UISwipeActionsConfiguration(actions: [deleteAction])
        return conf
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let index = indexPath.row
        let switchId = switches[index]
        cell.textLabel?.text = "\(index + 1)"
        cell.detailTextLabel?.text = switchId?.hex
        
        return cell
    }

}

extension MechanicalSwitchesViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetSmartSwitchId switchId: Int?, index: Int, count: Int) {
        
        switches[index] = switchId
        tableView.reloadData()
        
        if index == 0 && count > 1 {
            
            for i in 1..<count {
                MeshCommand.getSmartSwitchId(address, index: i).send()
            }
        }
    }
    
}

extension MechanicalSwitchesViewController {
    
    @objc private func loadSwitches() {
        
        switches.removeAll()
        tableView.reloadData()
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getSmartSwitchId(address, index: 0).send()
    }
    
}
