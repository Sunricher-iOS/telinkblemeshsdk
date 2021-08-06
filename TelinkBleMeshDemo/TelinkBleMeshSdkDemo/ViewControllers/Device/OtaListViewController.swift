//
//  OtaListViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/8/6.
//

import UIKit
import TelinkBleMesh
import Toast

class OtaListViewController: UITableViewController {
    
    private var nodes: [MeshNode] = []
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
        navigationItem.rightBarButtonItem = refreshItem
        
        title = "OTA Devices"
        
        refreshAction()
    }
    
    @objc private func refreshAction() {
        
        nodes.removeAll()
        tableView.reloadData()
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.scanNode(.factory)
    }
    
    @objc private func timerAction() {
        
        MeshManager.shared.disconnect()
        
        view.hideToastActivity()
        view.makeToast("Connect failed", position: .center)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let node = nodes[indexPath.row]
        MeshManager.shared.connect(node)
        
        view.makeToastActivity(view.center)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: false)
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

extension OtaListViewController: MeshManagerNodeDelegate {
    
    func meshManager(_ manager: MeshManager, didDiscoverNode node: MeshNode) {
        
        if nodes.contains(node) {
            return
        }
        
        nodes.append(node)
        tableView.reloadData()
    }
    
    func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode) {
        
        timer?.invalidate()
        view.hideToastActivity()
        view.makeToast("Login success", position: .center)
        
        let controller = OtaTableViewController(style: .grouped)
        controller.netework = .factory
        controller.node = node
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
}
