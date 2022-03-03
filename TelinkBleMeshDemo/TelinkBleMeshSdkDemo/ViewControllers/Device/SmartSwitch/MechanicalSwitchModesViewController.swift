//
//  MechanicalSwitchModesViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/3/2.
//

import UIKit
import TelinkBleMesh

protocol MechanicalSwitchModesSelection: NSObjectProtocol {
    
    func mechanicalSwitchModesViewController(_ controller: MechanicalSwitchModesViewController, didSelect mode: SmartSwitchMode)
    
}

class MechanicalSwitchModesViewController: UITableViewController {
    
    weak var delegate: MechanicalSwitchModesSelection?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Modes"
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        delegate?.mechanicalSwitchModesViewController(self, didSelect: SmartSwitchMode.all[indexPath.row])
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return SmartSwitchMode.all.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.textLabel?.text = SmartSwitchMode.all[indexPath.row].title
        
        return cell
    }
}
