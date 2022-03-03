//
//  GroupSyncViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/2/25.
//

import UIKit
import TelinkBleMesh

class GroupSyncViewController: UITableViewController {
    
    var groupId: Int!
    var innerDevices: [Int] = []
    var syncDevices: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Sync Settings"
        
        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshItemAction))
        navigationItem.rightBarButtonItem = refreshItem
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getGroupSyncInfo(groupId).send()
    }
    
    @objc private func refreshItemAction() {
        
        syncDevices.removeAll()
        tableView.reloadData()
        
        MeshCommand.getGroupSyncInfo(groupId).send()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let device = innerDevices[indexPath.row]
        let isSync = syncDevices.contains(device)
        
        if isSync {
            
            MeshCommand.deleteGroupSync(groupId, address: device).send()
            MeshCommand.getGroupSyncInfo(device).send()
            
        } else {
            
            MeshCommand.addGroupSync(groupId, address: device).send()
            MeshCommand.getGroupSyncInfo(device).send()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return innerDevices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let device = innerDevices[indexPath.row]
        cell.textLabel?.text = device.hex
        cell.accessoryType = syncDevices.contains(device) ? .checkmark : .none
        
        return cell
    }
    
}

extension GroupSyncViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetGroupSyncTag tag: MeshCommand.GroupSyncTag, group: Int) {
        
        guard group == groupId else { return }
        
        switch tag {
            
        case .bytes16:
            syncDevices.append(address)
            
        default:
            syncDevices.removeAll(where: { $0 == address })
        }
        
        tableView.reloadData()
    }
    
}
