//
//  PeripheralsViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/1/13.
//

import UIKit
import TelinkBleMesh
import Toast

class NodesViewController: UITableViewController {
    
    var network: MeshNetwork = .factory
    
    private var nodes: [MeshNode] = []
    private var stopTimer: Timer?
    private var alertController: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "factory_network".localization
        
        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshItemAction))
        navigationItem.rightBarButtonItem = refreshItem
        
        let otaItem = UIBarButtonItem(title: "OTA", style: .plain, target: self, action: #selector(self.otaAction))
        navigationItem.leftBarButtonItem = otaItem
        
        refreshItemAction()
    }
    
    deinit {
        
        stopScan()
    }
    
    @objc private func otaAction() {
        
        let controller = OtaListViewController(style: .grouped)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc func refreshItemAction() {
        
        nodes.removeAll()
        tableView.reloadData()
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.scanNode(network, ignoreName: true)
        
        stopTimer?.invalidate()
        stopTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false, block: { (timer) in
            
            timer.invalidate()
            MeshManager.shared.stopScanNode()
        })
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        stopScan()
        
        let node = nodes[indexPath.row]
        MeshManager.shared.nodeDelegate = self 
        MeshManager.shared.connect(node)
        
        alertController?.dismiss(animated: true, completion: nil)
        alertController = UIAlertController(title: "connecting".localization, message: nil, preferredStyle: .alert)
        alertController?.popoverPresentationController?.sourceView = view
        alertController?.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        
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
        
        let node = nodes[indexPath.row]
        cell.textLabel?.text = node.title
        cell.detailTextLabel?.text = node.detail
        
        return cell
    }
}

extension NodesViewController: MeshManagerNodeDelegate {
    
    func meshManagerNeedTurnOnBluetooth(_ manager: MeshManager) {
        
        view.makeToast("please_turn_on_bluetooth".localization, position: .center)
    }
    
    func meshManager(_ manager: MeshManager, didDiscoverNode node: MeshNode) {
        
        guard !nodes.contains(node) else { return }
        nodes.append(node)
        self.tableView.reloadData()
    }
    
    func meshManager(_ manager: MeshManager, didConnectNode node: MeshNode) {
        
        alertController?.title = "connected".localization
    }
    
    func meshManager(_ manager: MeshManager, didFailToConnectNodeIdentifier identifier: UUID) {
        
        alertController?.title = "fail_to_connect".localization
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            self.alertController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func meshManager(_ manager: MeshManager, didDisconnectNodeIdentifier identifier: UUID) {
        
        view.makeToast("disconnected".localization, position: .bottom)
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode) {
        
        alertController?.title = "login_successful".localization
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            
            self.alertController?.dismiss(animated: true) {
                
                let controller = NodeViewController(style: .grouped)
                controller.node = node
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func meshManager(_ manager: MeshManager, didFailToLoginNodeIdentifier identifier: UUID) {
        
        alertController?.title = "login_failed".localization
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.alertController?.dismiss(animated: true, completion: nil)
        }
    }
    
}

extension NodesViewController {
    
    private func stopScan() {
        
        stopTimer?.invalidate()
        MeshManager.shared.stopScanNode()
    }
    
}
