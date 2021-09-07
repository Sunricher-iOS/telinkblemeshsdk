//
//  NodeAdvancedViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/9/6.
//

import UIKit

class NodeAdvancedViewController: UITableViewController {
    
    var addresses: [Int] = []
    
    private let sections: [[RowType]] = [
        [.groups]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "advanced".localization
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let rowType = sections[indexPath.section][indexPath.row]
        switch rowType {
        
        case .groups:
            
            let controller = GroupsTableViewController(style: .grouped)
            controller.addresses = addresses
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
        
        let rowType = sections[indexPath.section][indexPath.row]
        cell.textLabel?.text = rowType.title
        
        return cell
    }

}

extension NodeAdvancedViewController {
    
    private enum RowType {
        
        case groups
        
        var title: String {
            
            switch self {
            
            case .groups:
                return "groups".localization
            }
        }
    }
    
}
