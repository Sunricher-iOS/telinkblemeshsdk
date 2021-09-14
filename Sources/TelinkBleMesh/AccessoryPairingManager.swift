//
//  File.swift
//  
//
//  Created by maginawin on 2021/8/4.
//

import Foundation

public protocol AccessoryPairingManagerDelegate: NSObjectProtocol {
    
    func accessoryPairingManagerTerminalWithNoMoreNewAddresses(_ manager: AccessoryPairingManager)
    
    func accessoryPairingManager(_ manager: AccessoryPairingManager, didAddNode node: MeshNode, newAddress: Int)
}

public class AccessoryPairingManager: NSObject {
    
    public static let shared = AccessoryPairingManager()
    
    public weak var delegate: AccessoryPairingManagerDelegate?
    
    private var network: MeshNetwork = .factory
    
    private var timer: Timer?
    
    private var newAddress: Int = 0
    private var availableAddressList: [Int] = []
    
    private var state = State.stopped
    
    private let connectingInterval: TimeInterval  = 8
    private let addressSettingInterval: TimeInterval = 4
    private let networkSettingInterval: TimeInterval = 4
    
    private override init() {
        super.init()
    }
    
    private enum State {
        
        case stopped
        case scanning
        case connecting
        case addressSetting
        case networkSetting
    }
    
    /// Start pairing devices without Bridge.
    public func startPairing(_ network: MeshNetwork) {
        
        MLog("startPairing \(network.name), \(network.password)")
        
        stop()
        
        availableAddressList = MeshAddressManager.shared.availableAddressList(network)
        MLog("availableAddressList count: \(availableAddressList.count), values \(availableAddressList)")
        if availableAddressList.count < 1 {
            
            delegate?.accessoryPairingManagerTerminalWithNoMoreNewAddresses(self)
            return
        }
        
        self.network = network
        
        timer?.invalidate()
        state = .scanning
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.scanNode(.factory)
    }
    
    public func stop() {
        
        MLog("stop auto pairing")
        
        state = .stopped
        timer?.invalidate()
        MeshManager.shared.nodeDelegate = nil
        MeshManager.shared.stopScanNode()
        MeshManager.shared.disconnect()
    }
    
}

// MARK: - MeshManagerNodeDelegate

extension AccessoryPairingManager: MeshManagerNodeDelegate {
    
    public func meshManager(_ manager: MeshManager, didDiscoverNode node: MeshNode) {
        
        guard !node.deviceType.isSupportMeshAdd else { return }
        guard state == .scanning else { return }
        
        timer?.invalidate()
        state = .connecting
        
        MeshManager.shared.stopScanNode()
        MeshManager.shared.connect(node)
        
        timer = Timer.scheduledTimer(timeInterval: connectingInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    public func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode) {
        
        guard state == .connecting else { return }
        
        timer?.invalidate()
        state = .addressSetting
        
        guard let newAddress = getNextAvailableAddress(Int(node.shortAddress)) else {
            
            stop()
            
            DispatchQueue.main.async {
                
                self.delegate?.accessoryPairingManagerTerminalWithNoMoreNewAddresses(self)
            }
            
            return
        }
        
        self.newAddress = newAddress
        MeshCommand.changeAddress(MeshCommand.Address.connectedNode, withNewAddress: newAddress).send()
        
        timer = Timer.scheduledTimer(timeInterval: addressSettingInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    public func meshManager(_ manager: MeshManager, didGetDeviceAddress address: Int) {
        
        guard state == .addressSetting,
              newAddress == address else { return }
        
        _ = MeshAddressManager.shared.append(address, network: network)
        availableAddressList.removeAll { $0 == address }
        
        timer?.invalidate()
        state = .networkSetting
        
        MeshManager.shared.setNewNetwork(network, isMesh: false)
        
        timer = Timer.scheduledTimer(timeInterval: networkSettingInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    public func meshManager(_ manager: MeshManager, didGetFirmware firmware: String, node: MeshNode) {
        
        DispatchQueue.main.async {
            
            self.delegate?.accessoryPairingManager(self, didAddNode: node, newAddress: self.newAddress)
        }
        
        startPairing(network)
    }
    
}

// MARK: -

extension AccessoryPairingManager {
    
    private func getNextAvailableAddress(_ oldAddress: Int) -> Int? {
        
        MLog("getNextAvailableAddress")
        
        let addresses = availableAddressList
        
        for address in addresses {
            
            if address != oldAddress {
                
                availableAddressList.removeAll(where: { $0 == address })
                return address
            }
        }
        return nil
    }
    
    @objc private func timerAction(_ sender: Timer) {
     
        switch state {
            
        case .connecting:
            
            startPairing(network)
            MLog("timerAction connecting")
            
        case .addressSetting:
            
            startPairing(network)
            MLog("timerAction addressSetting")
            
        case .networkSetting:
            
            startPairing(network)
            MLog("timerAction networkSetting")
            
        case .scanning: fallthrough
        case .stopped:
            break
        }
    }
    
}
