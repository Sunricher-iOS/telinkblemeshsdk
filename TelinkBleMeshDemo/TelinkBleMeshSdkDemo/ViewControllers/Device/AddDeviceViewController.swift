//
//  AddDeviceViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/3/29.
//

import UIKit
import TelinkBleMesh

class AddDeviceViewController: UITableViewController {
    
    var network: MeshNetwork!
    
    private var meshDevices: [MeshDevice] = []
    
    private var alertController: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "add_device".localization
        
        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshItemAction))
        navigationItem.rightBarButtonItem = refreshItem
        
        refreshItemAction()
    }
    
    @objc func refreshItemAction() {
        
        alertController = UIAlertController(title: "pairing...".localization, message: "0%", preferredStyle: .alert)
        alertController?.popoverPresentationController?.sourceView = view
        alertController?.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        
        let stopAction = UIAlertAction(title: "stop".localization, style: .default) { _ in
            
            MeshPairingManager.shared.stop()
        }
        alertController?.addAction(stopAction)
        
        present(alertController!, animated: true, completion: nil)
        
        meshDevices.removeAll()
        tableView.reloadData()
        
        MeshPairingManager.shared.delegate = self
        MeshPairingManager.shared.startPairing(network, delegate: self)
    }
    
    deinit {
        
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return meshDevices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        let device = meshDevices[indexPath.row]
        cell.textLabel?.text = device.description
        
        return cell
    }

}

extension AddDeviceViewController: MeshPairingManagerDelegate {
    
    func meshPairingManager(_ manager: MeshPairingManager, didAddNewDevice meshDevice: MeshDevice) {
        
        meshDevices.append(meshDevice)
        tableView.reloadData()
    }
    
    func meshPairingManager(_ manager: MeshPairingManager, didUpdateProgress progress: Float) {
        
        alertController?.message = "\(progress * 100)%"
    }
    
    func meshPairingManagerDidFinishPairing(_ manager: MeshPairingManager) {
        
        alertController?.dismiss(animated: true) { [weak self] in
            
            self?.view.makeToast("pairing_finished".localization, position: .center)
        }
    }
    
    func meshPairingManager(_ manager: MeshPairingManager, pairingFailed reason: MeshPairingManager.PairingFailedReason) {
        
        NSLog("meshPairingManagerPairingFailed \(reason)", "")

        alertController?.dismiss(animated: true) { [weak self] in
            
            self?.view.makeToast("pairing_failed".localization, position: .center)
        }
    }
}
