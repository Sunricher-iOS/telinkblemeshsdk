//
//  RemoteSettingsViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/11/30.
//

import UIKit
import TelinkBleMesh

class RemoteSettingsViewController: UITableViewController {
    
    weak var device: MyDevice!
    var network: MeshNetwork!
    
    private var sections: [SectionType] = [.groupsAction, .groupsItem]
    private var actionCells: [CellType] = [.getGroups, .setGroups]
    
    private var leadingGroups = [0, 0, 0, 0]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings".localization
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getRemoteGroups(Int(device.meshDevice.address)).send()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = sections[indexPath.section]
        switch section {
        case .groupsAction:
            
            let cellType = actionCells[indexPath.row]
            switch cellType {
                
            case .getGroups:
                MeshCommand.getRemoteGroups(Int(device.meshDevice.address)).send()
                
            case .setGroups:
                setGroupsHandler()
                
            case .groupItem:
                break
            }
            
        case .groupsItem:
            groupItemSelectHandler(index: indexPath.row + 1)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let section = sections[section]
        switch section {
        case .groupsAction: return actionCells.count
        case .groupsItem: return 4
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let section = sections[indexPath.section]
        switch section {
            
        case .groupsAction:
            
            let cellType = actionCells[indexPath.row]
            cell.textLabel?.text = cellType.title
            cell.detailTextLabel?.text = nil
            
        case .groupsItem:
            
            cell.textLabel?.text = "\(indexPath.row + 1)"
            let group = leadingGroups[indexPath.row]
            cell.detailTextLabel?.text = "\(group)"
        }
        
        return cell
    }

}

private enum SectionType {
    
    case groupsAction
    case groupsItem
    
}

private enum CellType {
    
    case setGroups
    case getGroups
    case groupItem
    
    var title: String {
        switch self {
        case .setGroups: return "set_groups".localization
        case .getGroups: return "get_groups".localization
        case .groupItem: return ""
        }
    }
}

extension RemoteSettingsViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetRemoteGroups groups: [Int], isLeading: Bool) {
        
        for (index, group) in groups.enumerated() {
            guard index < 4 else { break }
            leadingGroups[index] = group & 0xFF
        }
        tableView.reloadData()
    }
    
}

extension RemoteSettingsViewController {
    
    private func setGroupsHandler() {
        
        let address = Int(device.meshDevice.address)
        MeshCommand.setRemoteGroups(address, groups: leadingGroups).send()
    }
    
    private func groupItemSelectHandler(index: Int) {
        
        let alert = UIAlertController(title: "\(index)", message: "Enter a group ID, range [1, 254]", preferredStyle: .alert)
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alert.popoverPresentationController?.sourceView = view
        
        var textField: UITextField?
        alert.addTextField { tf in
            textField = tf
            textField?.keyboardType = .numberPad
            textField?.becomeFirstResponder()
        }
        
        let confirmAction = UIAlertAction(title: "confirm".localization, style: .default) { _ in
            
            guard let text = textField?.text, let value = Int(text), value >= 1 && value <= 254 else { return }
            
            self.leadingGroups[index - 1] = value
            self.tableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
}
