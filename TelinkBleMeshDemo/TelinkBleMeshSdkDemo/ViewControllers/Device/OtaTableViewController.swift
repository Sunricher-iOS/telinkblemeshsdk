//
//  OtaTableViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/5/26.
//

import UIKit
import TelinkBleMesh

class OtaTableViewController: UITableViewController {
    
//    weak var device: MyDevice!
    var netework: MeshNetwork!
    var node: MeshNode!
    
    private let sections: [SectionType] = [
        .currentFirmware, .latestFirmware, .update
    ]
    
    private var currentFirmware: String?
    private var otaFile: MeshOtaFile?
    
    private var alertController: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFirmwareVersion()
        DispatchQueue.global().async {
            
            self.otaFile = MeshOtaManager.shared.getLatestOtaFile(self.node.deviceType)
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = sections[indexPath.section]
        switch section {
        
        case .currentFirmware:
            getFirmwareVersion()
            
        case .latestFirmware:
            break
            
        case .update:
            updateAction()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let section = sections[indexPath.section]
        cell.textLabel?.text = section.title
        
        switch section {
        
        case .currentFirmware:
            cell.detailTextLabel?.text = currentFirmware
            
        case .latestFirmware:
            cell.detailTextLabel?.text = otaFile?.version ?? "no_updates".localization
            
        case .update:
            cell.detailTextLabel?.text = nil
        }
        
        return cell
    }

}

extension OtaTableViewController {
    
    private enum SectionType {
        
        case currentFirmware
        case latestFirmware
        case update
        
        var title: String {
            
            switch self {
            
            case .currentFirmware:
                return "current_firmware".localization
                
            case .latestFirmware:
                return "latest_firmware".localization
                
            case .update:
                return "update".localization
            }
            
        }
    }
    
}

extension OtaTableViewController {
    
    private func updateAction() {
        
        guard let otaFile = self.otaFile else {
            
            view.makeToast("no_updates".localization, position: .center)
            return
        }
        
        guard let current = self.currentFirmware else {

            view.makeToast("get_current_firmware_again".localization, position: .center)
            getFirmwareVersion()
            return
        }

        guard otaFile.isNeedUpdate(current) else {

            view.makeToast("already_the_latest_firmware".localization, position: .center)
            return
        }
        
        let alert = UIAlertController(title: "update_firmware_title".localization, message: nil, preferredStyle: .alert)
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alert.popoverPresentationController?.sourceView = view
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        let updateAction = UIAlertAction(title: "update".localization, style: .default) { [weak self] (_) in
            
            guard let self = self else { return }
            
            MeshOtaManager.shared.delegate = self
            MeshOtaManager.shared.startOta(Int(self.node.shortAddress), network: self.netework, otaFile: otaFile)
            
            self.alertController = UIAlertController(title: "updating".localization, message: "0%", preferredStyle: .alert)
            self.alertController?.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2, width: 1, height: 1)
            self.alertController?.popoverPresentationController?.sourceView = self.view
            
            let stopAction = UIAlertAction(title: "stop".localization, style: .cancel) { (_) in
                
                MeshOtaManager.shared.stopOta()
            }
            
            self.alertController?.addAction(stopAction)
            
            self.present(self.alertController!, animated: true, completion: nil)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(updateAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func getFirmwareVersion() {
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.readFirmwareWithConnectNode()
    }
    
}

extension OtaTableViewController: MeshManagerNodeDelegate {
    
    func meshManager(_ manager: MeshManager, didGetFirmware firmware: String, node: MeshNode) {
        
        currentFirmware = firmware
        tableView.reloadData()
    }
    
}

extension OtaTableViewController: MeshOtaManagerDelegate {
    
    func meshOtaManager(_ manager: MeshOtaManager, didUpdateFailed reason: MeshOtaManager.FailedReason) {
        
        alertController?.message = reason.title
    }
    
    func meshOtaManager(_ manager: MeshOtaManager, didUpdateProgress progress: Float) {
        
        alertController?.message = "\(Int(progress * 100))%"
    }
    
    func meshOtaManagerDidUpdateComplete(_ manager: MeshOtaManager) {
        
        alertController?.dismiss(animated: true, completion: {
            
            self.view.makeToast("the_update_is_complete".localization, position: .center)
        })
    }
    
}

extension MeshOtaManager.FailedReason {
    
    var title: String {
        
        switch self {
        
        case .connectOvertime:
            return "ota_connect_overtime".localization
            
        case .disconnected:
            return "ota_disconnected".localization
            
        case .invalidOtaFile:
            return "invalid_ota_file".localization
        }
    }
    
}
