//
//  NetworkViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/1/14.
//

import UIKit
import TelinkBleMesh
import CoreBluetooth

class NetworkViewController: UITableViewController {
    
    var network: MeshNetwork!
    
    private weak var deviceDelegate: MyDeviceDelegate?
    private var devices: [MyDevice] = []
    
    private var isNeedReload = true

    override func viewDidLoad() {
        super.viewDidLoad()

        title = network.name
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItemAction))
        navigationItem.rightBarButtonItem = addItem
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "pull_refresh".localization)
        refreshControl.addTarget(self, action: #selector(self.refreshControlValueChangedAction(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc func refreshControlValueChangedAction(_ sender: UIRefreshControl) {
        
        if sender.isRefreshing {
            
            sender.endRefreshing()
            
            MeshManager.shared.nodeDelegate = self
            MeshManager.shared.scanNode(network, autoLogin: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isNeedReload {
            
            isNeedReload = false
            MeshManager.shared.nodeDelegate = self
            MeshManager.shared.scanNode(network, autoLogin: true)
        }
    }

    deinit {
        
        MeshManager.shared.stopScanNode()
        MeshManager.shared.disconnect()
    }
    
    @objc func addItemAction() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alertController.popoverPresentationController?.sourceView = view
        
        let cancel = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        
        let addDeviceAction = UIAlertAction(title: "Add Device", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            
            self.isNeedReload = true
            let controller = DevicePairingViewController()
            controller.network = self.network
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        let addAccessoryAction = UIAlertAction(title: "Add Accessory", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            
            self.isNeedReload = true
            
            let controller = SingleAddDeviceViewController(style: .grouped)
            controller.network = self.network
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        let manageDeviceAddresses = UIAlertAction(title: "manage_device_addresses".localization, style: .default) { [weak self] (_) in
            
            guard let self = self else { return }
            
            self.isNeedReload = false
            let controller = DeviceAddressesViewController(style: .grouped)
            controller.network = self.network
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        alertController.addAction(addDeviceAction)
        alertController.addAction(addAccessoryAction)
        alertController.addAction(manageDeviceAddresses)
        alertController.addAction(cancel)
        
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        isNeedReload = false
        
        let device = devices[indexPath.row]
        
        guard device.isValid else { return }
        guard let deviceType = device.deviceType else { return }
        
        switch deviceType.category {
        
        case .light: fallthrough
        case .bridge: fallthrough
        case .rfPa: fallthrough
        case .curtain:
            
            let controller = DeviceViewController(style: .grouped)
            controller.device = device
            controller.network = network
            deviceDelegate = controller
            navigationController?.pushViewController(controller, animated: true)
            
        default:
            break
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.title
        cell.detailTextLabel?.text = device.detail
        
        return cell
    }

}

extension NetworkViewController: MeshManagerNodeDelegate {
    
    func meshManagerDidUpdateState(_ manager: MeshManager, state: CBManagerState) {
        
        if state == .poweredOn {
            
            MeshManager.shared.scanNode(network, autoLogin: true, ignoreName: false)
        }
    }
    
    func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode) {
        
        view.makeToast("login_successful".localization, position: .center)
        
        MeshManager.shared.deviceDelegate = self
        MeshManager.shared.scanMeshDevices()
    }
    
    func meshManager(_ manager: MeshManager, didDisconnectNodeIdentifier identifier: UUID) {
        
        devices.removeAll()
        self.tableView.reloadData()
    }
    
    func meshManagerNeedTurnOnBluetooth(_ manager: MeshManager) {
        
        view.makeToast("please_turn_on_bluetooth".localization, position: .center)
    }
    
    func meshManager(_ manager: MeshManager, didGetDeviceAddress address: Int) {
        
    }
    
}

extension NetworkViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, didUpdateMeshDevices meshDevices: [MeshDevice]) {
        
        meshDevices.forEach { [weak self] meshDevice in
            
            guard let self = self else { return }
            
            let device = MyDevice(meshDevice: meshDevice)
            
            // Update old device info.
            if let oldDevice = self.devices.first(where: { $0 == device }) {
                
                oldDevice.meshDevice = meshDevice
                deviceDelegate?.deviceDidUpdateState(oldDevice)
                return
            }
            
            self.devices.append(device)
            
            let command = MeshCommand.requestMacDeviceType(Int(meshDevice.address))
            MeshManager.shared.send(command)
        }
        
        tableView.reloadData()        
    }
    
    func meshManager(_ manager: MeshManager, device address:Int, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data) {
        
        if let device = devices.first(where: { $0.meshDevice.address == address }) {
            
            device.deviceType = deviceType
            device.macData = macData
            tableView.reloadData()
        }
    }
    
}
