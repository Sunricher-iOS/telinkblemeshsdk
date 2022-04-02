//
//  MechanicalSwitchViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/3/1.
//

import UIKit
import TelinkBleMesh

class MechanicalSwitchViewController: UITableViewController {
    
    var addresses: [Int] = []
    var groupId: Int = 0
    var groupInnerDevices: [Int] = []
    
    private var state = State.getSecretKey {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var mode = SmartSwitchMode.default
    
    private var alert: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Mechanical Switch"
        
        if groupId == 0 {
            
            let linkItem = UIBarButtonItem(title: "Link", style: .plain, target: self, action: #selector(linkItemAction))
            navigationItem.rightBarButtonItem = linkItem
        }
        
        SmartSwitchManager.shared.delegate = self
        SmartSwitchManager.shared.dataSource = self
    }
    
    @objc private func linkItemAction() {
        
        startLinkHandler()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellType = cells[indexPath.row]
        switch cellType {
            
        case .model:
            
            let controller = MechanicalSwitchModesViewController(style: .grouped)
            controller.delegate = self
            navigationController?.pushViewController(controller, animated: true)
            
        case .get:
            getSecretKeyHandler()
            
        case .start:
            startConfigurationHandler()
            
        case .link:
            startLinkHandler()
            
        case .read:
            
            let message = "Touch the device with the back of the mobile device in order to take it into use in the network. Note that it may be necessary to move the mobile device around to find the NFC responsive area."
            SmartSwitchManager.shared.readConfiguration(alertMessage: message)
            
        case .updateSmartSwitch:
            startUpdateSmartSwitchHandler()
            
        case .unbindSmartSwitch:
            startUnbindSmartSwitchHandler()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cells.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let cellType = cells[indexPath.row]
        cell.textLabel?.text = cellType.title
        cell.detailTextLabel?.text = nil
        
        switch cellType {
        case .model:
            cell.detailTextLabel?.text = mode.title
            
        default:
            break
        }
        
        return cell
    }

}

extension MechanicalSwitchViewController {
    
    private enum State {
        
        case getSecretKey
        case start
        case link
        
        var title: String {
            switch self {
            case .getSecretKey: return "Get Secret Key"
            case .start: return "Start Configuration"
            case .link: return "Link to Devices"
            }
        }
    }
    
    private enum CellType {
        
        case model
        case get
        case start
        case link
        case read
        case updateSmartSwitch
        case unbindSmartSwitch
        
        var title: String {
            switch self {
            case .model: return "Model"
            case .get: return "Get Secret Key"
            case .start: return "Start Configuration"
            case .link: return "Link to Devices"
            case .read: return "Read Configuration"
            case .updateSmartSwitch: return "Update Smart Switch"
            case .unbindSmartSwitch: return "Unbind Smart Switch"
            }
        }
    }
    
    private var cells: [CellType] {
        
        switch state {
        case .getSecretKey: return [.model, .get, .read, .updateSmartSwitch, .unbindSmartSwitch]
        case .start: return [.start]
        case .link: return [.link]
        }
    }
    
}

extension MechanicalSwitchViewController: MechanicalSwitchModesSelection {

    func mechanicalSwitchModesViewController(_ controller: MechanicalSwitchModesViewController, didSelect mode: SmartSwitchMode) {
        
        self.mode = mode
        self.tableView.reloadData()
        controller.navigationController?.popViewController(animated: true)
    }

}

extension MechanicalSwitchViewController {
    
    private func getSecretKeyHandler() {
        
        SmartSwitchManager.shared.clear()
        
        if groupId != 0 {
            MeshCommand.getSmartSwitchSecretKey(mode.rawValue, groupId: groupId).send()
        } else {
            MeshCommand.getSmartSwitchSecretKey(mode.rawValue, groupId: 0x8001).send()
        }
        
        let alert = UIAlertController(title: "Get Secret Key", message: "Getting...", preferredStyle: .alert)
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alert.popoverPresentationController?.sourceView = view
        
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: { _ in
            
            if SmartSwitchManager.shared.isValid {
             
                self.state = .start
            }
            
            self.alert = nil
        })
        
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        self.alert = alert
    }
    
    private func startConfigurationHandler() {
        
        let message = "Touch the device with the back of the mobile device in order to take it into use in the network. Note that it may be necessary to move the mobile device around to find the NFC responsive area."
        SmartSwitchManager.shared.startConfiguration(mode: mode, alertMessage: message)
    }
    
    private func startLinkHandler() {
        
        let controller = MechanicalLinkViewController(style: .grouped)
        controller.addresses = addresses
        controller.groupId = groupId
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func startUpdateSmartSwitchHandler() {
        
        if groupId > 0 {
            
            groupInnerDevices.forEach {
                MeshCommand.addSmartSwitchIdWithGroupId($0, groupId: groupId).send()
            }
        }
    }
    
    private func startUnbindSmartSwitchHandler() {
        
        let message = "Touch the device with the back of the mobile device in order to take it into use in the network. Note that it may be necessary to move the mobile device around to find the NFC responsive area."
        SmartSwitchManager.shared.unbindConfiguration(alertMessage: message)
    }
    
}

extension MechanicalSwitchViewController: SmartSwitchManagerDelegate {
    
    func smartSwitchManager(_ manager: SmartSwitchManager, didReceiveData progress: Int) {
        
        alert?.message = "\(progress)%"
    }
    
    func smartSwitchManagerDidReceiveDataFailed(_ manager: SmartSwitchManager) {
        
        alert?.message = "Failed!"
    }
    
    func smartSwitchManagerDidReceiveDataEnd(_ manager: SmartSwitchManager) {
        
        alert?.message = "Successful!"
    }
    
    func smartSwitchManagerDidConfigureSuccessful(_ manager: SmartSwitchManager) {
        
        alert?.message = "Configure successful!"
        state = .getSecretKey
        
        if groupId != 0 {
            
            groupInnerDevices.forEach {
                MeshCommand.addSmartSwitchIdWithGroupId($0, groupId: groupId).send()
            }
        }
    }
    
    func smartSwitchManagerDidReadConfiguration(_ manager: SmartSwitchManager, isConfigured: Bool, mode: SmartSwitchMode?) {
        
        NSLog("didReadConfiguration \(isConfigured)", "")
    }
    
    func smartSwitchManagerDidUnbindConfigurationSuccessful(_ manager: SmartSwitchManager) {
        
        NSLog("didUnbindConfiguration", "")
    }
    
}

extension MechanicalSwitchViewController: SmartSwitchManagerDataSource {
    
    func smartSwitchManager(_ manager: SmartSwitchManager, nfcConnectFailed state: SmartSwitchManager.State) -> String {
        return "Connect device failed, please try again."
    }
    
    func smartSwitchManager(_ manager: SmartSwitchManager, nfcScanningMessage state: SmartSwitchManager.State) -> String {
        if state == .startConfig {
            return "Configuring, please do not remove your device."
        } else if state == .readConfig {
            return "Reading, please do not remove your device."
        } else {
            return "Unbinding, please do not remove your device."
        }
    }
    
    func smartSwitchManager(_ manager: SmartSwitchManager, nfcReadWriteFailedMessage state: SmartSwitchManager.State) -> String {
        if state == .startConfig {
            return "Configure failed, please try again."
        } else if state == .readConfig {
            return "Reading failed, please try again."
        } else {
            return "Unbind failed, please try again."
        }
    }
    
    func smartSwitchManager(_ manager: SmartSwitchManager, nfcReadWriteSuccessfulMessage state: SmartSwitchManager.State) -> String {
        if state == .startConfig {
            return "Configure successful!"
        } else if state == .readConfig {
            return "Reading successful!"
        } else {
            return "Unbind successful!"
        }
    }
    
}
