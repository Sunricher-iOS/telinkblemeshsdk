//
//  GroupViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/9/6.
//

import UIKit
import TelinkBleMesh

class GroupViewController: UITableViewController {
    
    var groupId: Int!
    
    private var innerDevices: [Int] = []
    var outerDevices: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(format: "0x%04X", groupId)
        
        let advanceItem = UIBarButtonItem(title: "Advanced", style: .plain, target: self, action: #selector(advancedAction))
        navigationItem.rightBarButtonItem = advanceItem
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getGroupDevices(groupId).send()
    }

    @objc private func advancedAction() {
        
        let controller = GroupAdvancedViewController(style: .grouped)
        controller.groupId = groupId
        controller.innerDevices = innerDevices
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            
            let device = outerDevices[indexPath.row]
            MeshCommand.addGroup(groupId, address: device).send()
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.section == 0 {
            
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] action, view, completion in
                
                guard let self = self else { return }
                
                let device = self.innerDevices.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                self.outerDevices.append(device)
                tableView.insertRows(at: [IndexPath(row: self.outerDevices.count - 1, section: 1)], with: .automatic)
                
                MeshCommand.deleteGroup(self.groupId, address: device).send()
                completion(true)
            }
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
            
        } else {
            
            return nil
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return section == 0 ? innerDevices.count : outerDevices.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return section == 0 ? "Inner devices" : "Outer devices"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.selectionStyle = .none
        
        let address = indexPath.section == 0 ? innerDevices[indexPath.row] : outerDevices[indexPath.row]
        cell.textLabel?.text = String(format: "Device 0x%02X", address)
        
        return cell
    }

}

extension GroupViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetGroups groups: [Int]) {
        
        if outerDevices.contains(address) {
            
            if groups.contains(groupId) {
                
                innerDevices.append(address)
                outerDevices.removeAll(where: { $0 == address })
                tableView.reloadData()
            }
        }
    }
    
    func meshManager(_ manager: MeshManager, didGetDeviceAddress address: Int) {
        
        guard !innerDevices.contains(address) else { return }
        innerDevices.append(address)
        outerDevices.removeAll(where: { $0 == address })
        tableView.reloadData()
    }
    
}
