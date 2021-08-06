//
//  PeripheralViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/1/14.
//

import UIKit
import TelinkBleMesh

class NodeViewController: UITableViewController {
    
    var node: MeshNode!
    
    private weak var deviceDelegate: MyDeviceDelegate?    
    private var devices: [MyDevice] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = node.title
        
        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshItemAction))
        navigationItem.rightBarButtonItem = refreshItem
        
        MeshManager.shared.deviceDelegate = self
        MeshManager.shared.scanMeshDevices()
    }
    
    @objc func refreshItemAction() {
        
        devices.removeAll()
        tableView.reloadData()
        
        MeshManager.shared.scanMeshDevices()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let device = devices[indexPath.row]
        guard device.isValid else {
            
            MeshCommand.requestMacDeviceType(Int(device.meshDevice.address)).send()        
            return
        }
        guard let deviceType = device.deviceType else { return }
        
        let controller = DeviceViewController(style: .grouped)
        controller.device = device
        controller.network = .factory
        deviceDelegate = controller
        navigationController?.pushViewController(controller, animated: true)
        
//        switch deviceType.category {
//        
//        case .light: fallthrough
//        case .bridge: fallthrough
//        case .rfPa: fallthrough
//        case .curtain:
//            
//            let controller = DeviceViewController(style: .grouped)
//            controller.device = device
//            controller.network = .factory
//            deviceDelegate = controller
//            navigationController?.pushViewController(controller, animated: true)
//            
//        default:
//            break
//        }
        
        
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

extension NodeViewController: MeshManagerDeviceDelegate {    
    
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
    
    func meshManager(_ manager: MeshManager, device address: Int, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data) {
        
        if let device = devices.first(where: { $0.meshDevice.address == address }) {
            
            device.deviceType = deviceType
            device.macData = macData
            tableView.reloadData()
        }
    }
    
}
