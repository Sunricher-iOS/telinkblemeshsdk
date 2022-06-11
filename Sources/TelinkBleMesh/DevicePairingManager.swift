//
//  File.swift
//
//
//  Created by maginawin on 2021/8/5.
//

import Foundation

public protocol DevicePairingManagerDelegate: NSObjectProtocol {
    
    func devicePairingManagerFailToConnect(_ manager: DevicePairingManager)
    
    func devicePairingManagerTerminalWithNoMoreNewAddresses(_ manager: DevicePairingManager)
    
    func devicePairingManager(_ manager: DevicePairingManager, terminalWithUnsupportedDevice address: Int, deviceType: MeshDeviceType, macData: Data)
    
    func devicePairingManagerDidFinish(_ manager: DevicePairingManager)
    
}

public class DevicePairingManager: NSObject {
    
    public static let shared = DevicePairingManager()
    
    public weak var delegate: DevicePairingManagerDelegate?
    
    private var network: MeshNetwork = .factory
    private var timer: Timer?
    private var availableAddressList: [Int] = []
    
    private var state: State = .stopped
    private var models: [PairingModel] = []
    
    private let scanningInterval: TimeInterval = 4
    private let connectingInterval: TimeInterval = 8
    private let devicesGettingInterval: TimeInterval = 2
    private let addressChangingInterval: TimeInterval = 8
    private let networkSettingInterval: TimeInterval = 4
    
    private var mainNode: MeshNode?
    
    private enum State {
        
        case stopped
        case scanning
        case connecting
        case devicesGetting
        case addressChanging
        case networkSetting
        case checking
    }
    
    private override init() {
        super.init()
    }
    
    public func startPairing(_ network: MeshNetwork) {
        
        MLog("startPairing \(network.name) \(network.password)")
        
        stop()
        
        availableAddressList = MeshAddressManager.shared.availableAddressList(network)
        MLog("availableAddressList count: \(availableAddressList.count), values \(availableAddressList)")
        if availableAddressList.count < 1 {
            
            delegate?.devicePairingManagerTerminalWithNoMoreNewAddresses(self)
            return
        }
        
        self.network = network
        
        timer?.invalidate()
        state = .scanning
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.deviceDelegate = self
        MeshManager.shared.scanNode(.factory)
        
        timer = Timer.scheduledTimer(timeInterval: scanningInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    public func stop() {
        
        MLog("stop Device pairing")
        
        mainNode = nil
        models.removeAll()
        state = .stopped
        timer?.invalidate()
        
        MeshManager.shared.nodeDelegate = nil
        MeshManager.shared.deviceDelegate = nil
        MeshManager.shared.stopScanNode()
        MeshManager.shared.disconnect()
    }
    
}

// MARK: - MeshManagerNodeDelegate

extension DevicePairingManager: MeshManagerNodeDelegate {
    
    public func meshManager(_ manager: MeshManager, didDiscoverNode node: MeshNode) {
        
        if state == .checking {
            
            if let mainNode = self.mainNode, mainNode.macValue == node.macValue {
                
                timer?.invalidate()
                state = .connecting
                
                MeshManager.shared.connect(node)
                timer = Timer.scheduledTimer(timeInterval: connectingInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
            }
            
            return
        }
        
        guard node.deviceType.isSafeConntion, state == .scanning else {
            return
        }
        
        timer?.invalidate()
        state = .connecting
        
        MeshManager.shared.connect(node)
        
        timer = Timer.scheduledTimer(timeInterval: connectingInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    public func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode) {
        
        if node.macValue == mainNode?.macValue {
            
            timer?.invalidate()
            state = .networkSetting
            
            MLog("checking setNewNework")
            
            MeshManager.shared.setNewNetwork(network, isMesh: false)
            
            timer = Timer.scheduledTimer(timeInterval: networkSettingInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
            
            return
        }
        
        mainNode = node
        
        guard state == .connecting else { return }
        
        timer?.invalidate()
        state = .devicesGetting
        
        MeshCommand.requestMacDeviceType(MeshCommand.Address.all).send()
        
        timer = Timer.scheduledTimer(timeInterval: devicesGettingInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    public func meshManager(_ manager: MeshManager, didGetDeviceAddress address: Int) {
        
    }
    
    public func meshManager(_ manager: MeshManager, didGetFirmware firmware: String, node: MeshNode) {
        
        guard state == .networkSetting else { return }
        
        MLog("Device pairing didGetFirmware")
    }
    
}

// MARK: - MeshManagerDeviceDelegate

extension DevicePairingManager: MeshManagerDeviceDelegate {
    
    public func meshManager(_ manager: MeshManager, device address: Int, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data) {
        
        guard state == .devicesGetting,
              !models.contains(where: { $0.macData == macData }) else { return }
        
        guard deviceType.isSupportMeshAdd else {
            
            stop()
            DispatchQueue.main.async {
                
                self.delegate?.devicePairingManager(self, terminalWithUnsupportedDevice: address, deviceType: deviceType, macData: macData)
            }
            return
        }
        
        guard let newAddress = getNextAvailableAddress(address) else {
            
            stop()
            DispatchQueue.main.async {
                
                self.delegate?.devicePairingManagerTerminalWithNoMoreNewAddresses(self)
            }
            return
        }
        
        timer?.invalidate()
        
        let model = PairingModel(oldAddress: address, newAddress: newAddress, deviceType: deviceType, macData: macData)
        models.append(model)
        
        timer = Timer.scheduledTimer(timeInterval: devicesGettingInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
    }
    
}

// MARK: -

extension DevicePairingManager {
    
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
        
        case .scanning: fallthrough
        case .connecting:
            
            stop()
            DispatchQueue.main.async {
                
                self.delegate?.devicePairingManagerFailToConnect(self)
            }
            
        case .devicesGetting:
            devicesGettingHandler()
            
        case .addressChanging:
            addressChangingHandler()
            
        case .networkSetting:
            networkSettingHandler()
        
        case .checking:
            
            stop()
            DispatchQueue.main.async {
                
                self.delegate?.devicePairingManagerDidFinish(self)
            }
            
        case .stopped:
            break
        }
    }
    
    private func devicesGettingHandler() {
        
        MLog("change models addresses")
        
        timer?.invalidate()
        state = .addressChanging
        
        for model in models {
            
            MeshCommand.changeAddress(model.oldAddress, withNewAddress: model.newAddress, macData: model.macData).send()
        }
        
        let consumeInterval = TimeInterval(models.count) * MeshManager.shared.sendingTimeInterval + addressChangingInterval
        timer = Timer.scheduledTimer(timeInterval: consumeInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    private func addressChangingHandler() {
        
        timer?.invalidate()
        state = .networkSetting
        
        let addresses = models.map{ $0.newAddress }
        _ = MeshAddressManager.shared.append(addresses, network: network)
        
        MLog("networkSetting")
        
        MeshManager.shared.setNewNetwork(network, isMesh: false)
        
        timer = Timer.scheduledTimer(timeInterval: networkSettingInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    private func networkSettingHandler() {
        
        MLog("networkSettingHandler \(network.name) \(network.password)")
        
        timer?.invalidate()
        state = .checking
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.deviceDelegate = self
        MeshManager.shared.scanNode(.factory)
        
        timer = Timer.scheduledTimer(timeInterval: scanningInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
}

// MARK: - PairingModel

fileprivate struct PairingModel: Equatable {
    
    var oldAddress: Int
    var newAddress: Int
    var deviceType: MeshDeviceType
    var macData: Data
}


fileprivate func == (lhs: PairingModel, rhs: PairingModel) -> Bool {
    
    return lhs.macData == rhs.macData
}
