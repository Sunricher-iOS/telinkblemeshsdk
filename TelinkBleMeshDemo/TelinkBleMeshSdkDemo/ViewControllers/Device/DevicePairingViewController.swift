//
//  DevicePairingViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/8/5.
//

import UIKit
import TelinkBleMesh

class DevicePairingViewController: UIViewController {
    
    var network: MeshNetwork!
    private var stateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Device Pairing"
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        loadViews()
        
        stateLabel.text = "Pairing"
        DevicePairingManager.shared.delegate = self
        DevicePairingManager.shared.startPairing(network)
    }
    
    private func loadViews() {
        
        stateLabel = UILabel()
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stateLabel)
        
        NSLayoutConstraint.activate([
            stateLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),
            stateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30)
        ])
    }
    
    deinit {
        
        DevicePairingManager.shared.delegate = nil
        DevicePairingManager.shared.stop()
    }

}

extension DevicePairingViewController: DevicePairingManagerDelegate {
    
    func devicePairingManagerFailToConnect(_ manager: DevicePairingManager) {
        
        stateLabel.text = "Fail to connect"
    }
    
    func devicePairingManagerTerminalWithNoMoreNewAddresses(_ manager: DevicePairingManager) {
        
        stateLabel.text = "No more new addresses"
    }
    
    func devicePairingManager(_ manager: DevicePairingManager, terminalWithUnsupportedDevice address: Int, deviceType: MeshDeviceType, macData: Data) {
        
        stateLabel.text = "Unsupported device \(deviceType)"
    }
    
    func devicePairingManagerDidFinish(_ manager: DevicePairingManager) {
        
        stateLabel.text = "Finish"
    }
    
}
