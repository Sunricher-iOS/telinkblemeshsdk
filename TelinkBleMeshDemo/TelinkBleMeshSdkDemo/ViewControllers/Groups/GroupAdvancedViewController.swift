//
//  GroupAdvancedViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/2/25.
//

import UIKit

class GroupAdvancedViewController: UITableViewController {
    
    var groupId: Int!
    var innerDevices: [Int] = []
    
    private let cellTypes: [CellType] = [
        .control, .syncSettings, .smartSwitch
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = String(format: "0x%04X Advanced", groupId)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch cellTypes[indexPath.row] {
        case .control:
            
            let controller = GroupControlViewController(style: .grouped)
            controller.groupId = groupId
            navigationController?.pushViewController(controller, animated: true)
            
        case .syncSettings:
            
            let controller = GroupSyncViewController(style: .grouped)
            controller.groupId = groupId
            controller.innerDevices = innerDevices
            navigationController?.pushViewController(controller, animated: true)
            
        case .smartSwitch:
            
            let controller = SmartSwitchViewController(style: .grouped)
            controller.addresses = []
            controller.groupId = groupId
            controller.groupInnerDevices = innerDevices
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cellTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let cellType = cellTypes[indexPath.row]
        cell.textLabel?.text = cellType.title
        
        return cell
    }

}

extension GroupAdvancedViewController {
    
    enum CellType {
        case control
        case syncSettings
        case smartSwitch
        
        var title: String? {
            switch self {
            case .control: return "Control"
            case .syncSettings: return "Sycn Settings"
            case .smartSwitch: return "Smart Switch"
            }
        }
    }
    
}
