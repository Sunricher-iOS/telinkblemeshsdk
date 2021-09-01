//
//  LightRunningSelectModeViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/8/31.
//

import UIKit

protocol LightRunningSelectModeViewControllerDelegate: NSObjectProtocol {
    
    func lightRunningSelectModeViewController(_ controller: LightRunningSelectModeViewController, didSelectIndex index: Int, isDefaultMode: Bool)
    
}

class LightRunningSelectModeViewController: UITableViewController {
    
    weak var delegate: LightRunningSelectModeViewControllerDelegate?
    
    var selectedIndex = 0
    var isDefaultMode = true
    var modes: [LightRunningModeTitle] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        delegate?.lightRunningSelectModeViewController(self, didSelectIndex: indexPath.row, isDefaultMode: isDefaultMode)
        navigationController?.popViewController(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return modes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        let mode = modes[indexPath.row]
        cell.textLabel?.text = mode.title
        cell.accessoryType = (selectedIndex == indexPath.row) ? .checkmark : .none
        
        return cell
    }

}
