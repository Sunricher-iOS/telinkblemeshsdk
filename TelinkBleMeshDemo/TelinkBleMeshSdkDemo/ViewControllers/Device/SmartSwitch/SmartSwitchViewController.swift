//
//  SmartSwitchViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/2/26.
//

import UIKit

class SmartSwitchViewController: UITableViewController {
    
    var addresses: [Int] = []
    var groupId: Int = 0
    var groupInnerDevices: [Int] = []

    private let sections: [[CellType]] = [
        [.mechanicalSwitch]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Smart Switch"
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellType = sections[indexPath.section][indexPath.row]
        switch cellType {
            
        case .mechanicalSwitch:
            
            let controller = MechanicalSwitchViewController(style: .grouped)
            controller.addresses = addresses
            controller.groupId = groupId
            controller.groupInnerDevices = groupInnerDevices
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let cellType = sections[indexPath.section][indexPath.row]
        cell.textLabel?.text = cellType.title
        
        switch cellType {
            
        case .mechanicalSwitch:
            break
        }
        
        return cell
    }
    
}

extension SmartSwitchViewController {
    
    enum CellType {
        
        case mechanicalSwitch
        
        var title: String? {
            switch self {
            case .mechanicalSwitch: return "Mechanical Switch"
            }
        }
    }
    
}
