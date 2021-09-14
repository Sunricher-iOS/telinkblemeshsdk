//
//  SingleAddDeviceViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/7/27.
//

import UIKit
import TelinkBleMesh

class SingleAddDeviceViewController: UITableViewController {
    
    var network: MeshNetwork!
    
    private var nodes: [MeshNode] = []
    private var alertController: UIAlertController?
    
    private var addedCount: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "single_add".localization
        
//        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
//        navigationItem.rightBarButtonItem = refreshItem
        
        refreshAction()
    }
    
    @objc func refreshAction() {
        
        addedCount = 0
        tableView.reloadData()
        
        AccessoryPairingManager.shared.delegate = self
        AccessoryPairingManager.shared.startPairing(network)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AccessoryPairingManager.shared.delegate = nil
        AccessoryPairingManager.shared.stop()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return nodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        cell.accessoryType = .disclosureIndicator
        
        let node = nodes[indexPath.row]
        cell.textLabel?.text = node.title
        cell.detailTextLabel?.text = node.detail
        
        return cell
    }
    
}

extension SingleAddDeviceViewController: AccessoryPairingManagerDelegate {
    
    func accessoryPairingManagerTerminalWithNoMoreNewAddresses(_ manager: AccessoryPairingManager) {
        
        NSLog("autoPairingManagerTerminalWithNoMoreNewAddresses", "")
    }
    
    func accessoryPairingManager(_ manager: AccessoryPairingManager, didAddNode node: MeshNode, newAddress: Int) {
        
        NSLog("didFoundNode \(node.name) \(node.macAddress) \(node.shortAddress)", "")
        
        guard !nodes.contains(node) else { return }
        
        nodes.append(node)
        tableView.reloadData()
    }
    
}
