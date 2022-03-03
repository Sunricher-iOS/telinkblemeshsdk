//
//  GroupSettingsViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/2/25.
//

import UIKit

class GroupSettingsViewController: UITableViewController {
    
    var groupId: Int!
    
    private let cells: [CellType] = [.lightRunning]

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Group Settings"
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch cells[indexPath.row] {
        case .lightRunning:
            let controller = GroupLightRunningViewController(style: .grouped)
            controller.groupId = groupId
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cells.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let cellType = cells[indexPath.row]
        switch cellType {
        case .lightRunning:
            cell.textLabel?.text = cellType.title
        }
        
        return cell
    }

}

extension GroupSettingsViewController {
    
    enum CellType {
        case lightRunning
        
        var title: String {
            switch self {
            case .lightRunning: return "Light Running"
            }
        }
    }
    
}
