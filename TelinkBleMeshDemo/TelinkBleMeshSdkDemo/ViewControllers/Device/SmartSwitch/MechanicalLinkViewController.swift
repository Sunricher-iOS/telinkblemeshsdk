//
//  MechanicalLinkViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/3/2.
//

import UIKit
import TelinkBleMesh
import Toast

class MechanicalLinkViewController: UITableViewController {
    
    var addresses: [Int] = []
    var groupId: Int = 0
    
    private var groups: [Int] = []
    private var timer: Timer?
    
    private var sections: [SectionType] = [
        .all, .groups, .devices
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Link to Devices"
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getGroups(MeshCommand.Address.all).send()
        
        view.makeToastActivity(.center)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
    }
    
    @objc private func timerAction() {
        
        view.hideToastActivity()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch sections[indexPath.section] {
            
        case .all:
            enablePairing(at: MeshCommand.Address.all)
            
        case .groups:
            enablePairing(at: groups[indexPath.row])
            
        case .devices:
            enablePairing(at: addresses[indexPath.row])
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch sections[section] {
        case .all: return 1
        case .groups: return groups.count
        case .devices: return addresses.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let section = sections[indexPath.section]
        switch section {
            
        case .all:
            cell.textLabel?.text = "All Devices"
            
        case .groups:
            cell.textLabel?.text = "Gruop " + groups[indexPath.row].hex
            
        case .devices:
            cell.textLabel?.text = "Device " + addresses[indexPath.row].hex
        }
        
        return cell
    }

}

extension MechanicalLinkViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetGroups groups: [Int]) {
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
        
        let temp = Set(self.groups).union(groups)
        self.groups = Array(temp).sorted(by: <)
        
        tableView.reloadData()
    }
    
}

extension MechanicalLinkViewController {
    
    private enum SectionType {
        
        case all
        case groups
        case devices
        
        var title: String? {
            switch self {
            case .all: return nil
            case .groups: return "Groups"
            case .devices: return "Devices"
            }
        }
    }
    
}

extension MechanicalLinkViewController {
    
    private func enablePairing(at address: Int) {
        
        MeshCommand.enablePairing(address).send()
        
        let alert = UIAlertController(title: "Pairing...", message: "Please push the button of the switch in 5 seconds.", preferredStyle: .alert)
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alert.popoverPresentationController?.sourceView = view
        
        present(alert, animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
            alert.dismiss(animated: true, completion: nil)
        })
    }
    
}
