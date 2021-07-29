//
//  File.swift
//  
//
//  Created by maginawin on 2021/7/26.
//

import Foundation

public protocol SinglePairingManagerDelegate: NSObjectProtocol {
    
    func singlePairingManager(_ manager: SinglePairingManager, didDiscoverNode node: MeshNode)
    
    /// Only `node.deviceType.isSupportSingleAdd == true` can be added.
    func singlePairingManager(_ manager: SinglePairingManager, terminalWithUnsupportNode node: MeshNode)
    
    func singlePairingManagerTerminalWithNoMoreNewAddresses(_ manager: SinglePairingManager)
    
    func singlePairingManagerDidFailToLoginNode(_ manager: SinglePairingManager)
    
    /// The adding process has been completed, but it may not be successful.
    func singlePairingManagerDidFinishPairing(_ manager: SinglePairingManager)
    
}

extension SinglePairingManagerDelegate {
    
    public func singlePairingManager(_ manager: SinglePairingManager, didDiscoverNode node: MeshNode) {}
    
    public func singlePairingManager(_ manager: SinglePairingManager, terminalWithUnsupportNode node: MeshNode) {}
    
    public func singlePairingManagerTerminalWithNoMoreNewAddresses(_ manager: SinglePairingManager) {}
    
    public func singlePairingManagerDidFailToLoginNode(_ manager: SinglePairingManager) {}
    
    public func singlePairingManagerDidFinishPairing(_ manager: SinglePairingManager) {}
    
}

public class SinglePairingManager: NSObject {
    
    public static let shared = SinglePairingManager()
    
    public weak var delegate: SinglePairingManagerDelegate?
    
    private var network: MeshNetwork = .factory
    
    private var timer: Timer?
    private let connectingInterval: TimeInterval = 8
    private let setNetworkInterval: TimeInterval = 4
    private let waitingChaningAddressesInterval: TimeInterval = 8
    private let deviceTypeGettingInterval: TimeInterval = 4
    
    /// (old address, new address)
    private var pendingAddress: (Int, Int) = (0, 0)
    private var availableAddressList: [Int] = []
    
    private var state = State.stopped
    
    private override init() {
        super.init()
    }
    
    private enum State {
        
        case stopped
        case scanning
        case startPairing
        case connecting
        case deviceTypeGetting
        case addressChanging
        case networkSetting
    }
    
    /// Start node scanning with factory network.
    public func startScanning() {
        
        MLog("SinglePairingManager startScanning")
        state = .scanning
        timer?.invalidate()
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.deviceDelegate = self
        
        MeshManager.shared.scanNode(.factory)
    }
    
    /// Stop pairing process.
    public func stop() {
        
        MLog("SinglePairingManager stop")
        state = .stopped
        timer?.invalidate()
        
        pendingAddress = (0, 0)
        availableAddressList.removeAll()
        
        MeshManager.shared.stopScanNode()
        MeshManager.shared.disconnect()
    }
    
    /// - Parameters:
    ///     - network: New MeshNetwork
    ///     - node: Adding node
    ///     - delegate: SinglePairingManagerDelegate
    public func startPairing(_ network: MeshNetwork, node: MeshNode) {
        
        MLog("SinglePairingManager startPairing")
        state = .startPairing
        timer?.invalidate()
        
        self.network = network
        MeshManager.shared.stopScanNode()
        
        pendingAddress = (0, 0)
        availableAddressList = MeshAddressManager.shared.availableAddressList(network)
        MLog("availableAddressList count: \(availableAddressList.count), values \(availableAddressList)")
        
        if availableAddressList.count < 1 {
            
            DispatchQueue.main.async {
                
                MLog("singlePairingManagerTerminalWithNoMoreNewAddresses")
                self.stop()
                self.delegate?.singlePairingManagerTerminalWithNoMoreNewAddresses(self)
            }
            return
        }
        
        guard node.deviceType.isSupportSingleAdd else {
            
            DispatchQueue.main.async {
            
                MLog("singlePairingManager terminalWithUnsupportNode \(node.deviceType)")
                self.delegate?.singlePairingManager(self, terminalWithUnsupportNode: node)
            }
            return 
        }
        
        state = .connecting
        timer = Timer.scheduledTimer(timeInterval: connectingInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
        
        if node == MeshManager.shared.connectNode {
            
            if node.peripheral.state == .connecting {
                
                MLog("singlePairingManager startPairing, node is connecting or connected.")
                return
            }
        }
        
        MeshManager.shared.connect(node)
    }
    
}

// MARK: - MeshManagerNodeDelegate

extension SinglePairingManager: MeshManagerNodeDelegate {
    
    public func meshManager(_ manager: MeshManager, didDiscoverNode node: MeshNode) {
        
        DispatchQueue.main.async {
            
            self.delegate?.singlePairingManager(self, didDiscoverNode: node)
        }
    }
    
    public func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode) {
        
        pendingAddress = (Int(node.shortAddress), 0)
        timer?.invalidate()
        state = .deviceTypeGetting
        
        MeshCommand.requestMacDeviceType(MeshCommand.Address.connectedNode).send()
        timer = Timer.scheduledTimer(timeInterval: deviceTypeGettingInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    public func meshManager(_ manager: MeshManager, didFailToLoginNodeIdentifier identifier: UUID) {
        
        stop()
        DispatchQueue.main.async {
            
            self.delegate?.singlePairingManagerDidFailToLoginNode(self)
        }
    }
    
}

// MARK: - MeshManagerDeviceDelegate

extension SinglePairingManager: MeshManagerDeviceDelegate {
    
    public func meshManager(_ manager: MeshManager, device address: Int, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data) {
        
        guard address == pendingAddress.0 else {
            return
        }
        
        timer?.invalidate()
        
        guard let newAddress = getNextAvailableAddress(address) else {
            
            stop()
            DispatchQueue.main.async {
                
                self.delegate?.singlePairingManagerTerminalWithNoMoreNewAddresses(self)
            }
            return
        }
        
        pendingAddress.1 = newAddress
        state = .addressChanging
        
        MeshCommand.changeAddress(MeshCommand.Address.connectedNode, withNewAddress: newAddress, macData: macData).send()
        
        timer = Timer.scheduledTimer(timeInterval: waitingChaningAddressesInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
    }
    
}

extension SinglePairingManager {
    
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
        
        case .connecting: fallthrough
        case .deviceTypeGetting:
            
            stop()
            delegate?.singlePairingManagerDidFailToLoginNode(self)
            
        case .addressChanging:
            
            timer?.invalidate()
            state = .networkSetting
            MeshManager.shared.setNewNetwork(self.network, isMesh: false)
            
            timer = Timer.scheduledTimer(timeInterval: setNetworkInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
            
        case .networkSetting:
            
            stop()
            MLog("singlePairingManagerDidFinishPairing")
            self.delegate?.singlePairingManagerDidFinishPairing(self)
            
        case .stopped: fallthrough
        case .scanning: fallthrough
        case .startPairing:
            break
        }
        
    }
    
}
