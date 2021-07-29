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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "single_add".localization
        
        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
        navigationItem.rightBarButtonItem = refreshItem
        
        refreshAction()
    }
    
    @objc func refreshAction() {
        
        nodes.removeAll()
        tableView.reloadData()
        
        SinglePairingManager.shared.delegate = self
        SinglePairingManager.shared.startScanning()
    }
    
    deinit {
        
        SinglePairingManager.shared.delegate = nil
        SinglePairingManager.shared.stop()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let node = nodes[indexPath.row]
        
        SinglePairingManager.shared.startPairing(network, node: node)
        
        alertController = UIAlertController(title: "pairing...".localization, message: "adding".localization, preferredStyle: .alert)
        alertController?.popoverPresentationController?.sourceView = view
        alertController?.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        
        let stopAction = UIAlertAction(title: "stop".localization, style: .cancel) { _ in
            
            SinglePairingManager.shared.stop()
        }
        
        alertController?.addAction(stopAction)
        present(alertController!, animated: true, completion: nil)
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

extension SingleAddDeviceViewController: SinglePairingManagerDelegate {
    
    func singlePairingManager(_ manager: SinglePairingManager, didDiscoverNode node: MeshNode) {
        
        guard !nodes.contains(node) else { return }
        
        nodes.append(node)
        tableView.reloadData()
    }
    
    func singlePairingManager(_ manager: SinglePairingManager, terminalWithUnsupportNode node: MeshNode) {
        
        alertController?.message = "unsupport_device_type".localization
    }
    
    func singlePairingManagerTerminalWithNoMoreNewAddresses(_ manager: SinglePairingManager) {
        
        alertController?.message = "no_more_addresses".localization
    }
    
    func singlePairingManagerDidFailToLoginNode(_ manager: SinglePairingManager) {
        
        alertController?.message = "login_failed".localization
    }
    
    func singlePairingManagerDidFinishPairing(_ manager: SinglePairingManager) {
        
        alertController?.message = "single_add_finished_message".localization
    }
    
}
