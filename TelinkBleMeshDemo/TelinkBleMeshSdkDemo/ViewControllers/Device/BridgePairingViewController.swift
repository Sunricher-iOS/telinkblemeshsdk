//
//  BridgePairingViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/8/5.
//

import UIKit
import TelinkBleMesh

class BridgePairingViewController: UIViewController {
    
    var network: MeshNetwork!
    private var stateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Bridge Pairing"
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        loadViews()
        
        stateLabel.text = "Pairing"
        BridgePairingManager.shared.delegate = self
        BridgePairingManager.shared.startPairing(network)
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
        
        BridgePairingManager.shared.delegate = nil
        BridgePairingManager.shared.stop()
    }

}

extension BridgePairingViewController: BridgePairingManagerDelegate {
    
    func bridgePairingManagerFailToConnect(_ manager: BridgePairingManager) {
        
        stateLabel.text = "Fail to connect"
    }
    
    func bridgePairingManagerTerminalWithNoMoreNewAddresses(_ manager: BridgePairingManager) {
        
        stateLabel.text = "No more new addresses"
    }
    
    func bridgePairingManager(_ manager: BridgePairingManager, terminalWithUnsupportedDevice address: Int, deviceType: MeshDeviceType, macData: Data) {
        
        stateLabel.text = "Unsupported device \(deviceType)"
    }
    
    func bridgePairingManagerTerminalWithNoBridgeFound(_ manager: BridgePairingManager) {
        
        stateLabel.text = "No bridge found"
    }
    
    func bridgePairingManagerDidFinish(_ manager: BridgePairingManager) {
        
        stateLabel.text = "Finish"
    }
    
}
