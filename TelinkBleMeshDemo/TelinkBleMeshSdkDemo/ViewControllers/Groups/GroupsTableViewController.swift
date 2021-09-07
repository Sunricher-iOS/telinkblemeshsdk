//
//  GroupsTableViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/9/6.
//

import UIKit
import TelinkBleMesh
import Toast

class GroupsTableViewController: UITableViewController {
    
    var addresses: [Int] = []
    
    private var groups: [Int] = []
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "groups".localization
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getGroups(MeshCommand.Address.all).send()
        
        view.makeToastActivity(.center)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction))
        navigationItem.rightBarButtonItem = addItem
    }
    
    @objc private func timerAction() {
        
        view.hideToastActivity()
    }
    
    @objc private func addAction() {
        
        let alert = UIAlertController(title: "Add Group", message: nil, preferredStyle: .alert)
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alert.popoverPresentationController?.sourceView = view
        
        var groupIdTextField: UITextField!
        
        alert.addTextField { textField in
            
            groupIdTextField = textField
            textField.keyboardType = .numberPad
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            guard let groupValue = groupIdTextField.text, groupValue.count > 0,
                  let groupId = Int(groupValue) else { return }
            
            MeshManager.shared.deviceDelegate = self
            MeshCommand.addGroup(groupId, address: MeshCommand.Address.connectedNode).send()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let groupId = groups[indexPath.row]
        let controller = GroupViewController(style: .grouped)
        controller.groupId = groupId
        controller.outerDevices = addresses
        navigationController?.pushViewController(controller, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let group = groups[indexPath.row]
        cell.textLabel?.text = String(format: "Group 0x%04X", group)
        
        return cell
    }
}

extension GroupsTableViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetGroups groups: [Int]) {
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
        
        let temp = Set(self.groups).union(groups)
        self.groups = Array(temp).sorted(by: <)
        
        tableView.reloadData()
    }
    
}
