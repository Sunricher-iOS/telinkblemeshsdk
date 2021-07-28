//
//  File.swift
//  
//
//  Created by maginawin on 2021/3/30.
//

import Foundation

public protocol MeshPairingManagerDelegate: NSObjectProtocol {
    
    ///
    /// - Parameters:
    ///     - manager: MeshPairingManager
    ///     - reason: MeshPairingManager.PairingFailedReason
    func meshPairingManager(_ manager: MeshPairingManager, pairingFailed reason: MeshPairingManager.PairingFailedReason)
    
    func meshPairingManager(_ manager: MeshPairingManager, terminalWithUnsupportedDevice address: Int, deviceType: MeshDeviceType, macData: Data)
    
    ///
    /// - Parameters:
    ///     - manager: MeshPairingManager
    ///     - progress: Range [0.0, 1.0]
    func meshPairingManager(_ manager: MeshPairingManager, didUpdateProgress progress: Float)
    
    func meshPairingManager(_ manager: MeshPairingManager, didAddNewDevice meshDevice: MeshDevice)
    
    func meshPairingManagerDidFinishPairing(_ manager: MeshPairingManager)
    
}

extension MeshPairingManagerDelegate {
    
    public func meshPairingManager(_ manager: MeshPairingManager, pairingFailed reason: MeshPairingManager.PairingFailedReason) {}
    
    public func meshPairingManager(_ manager: MeshPairingManager, didUpdateProgress progress: Float) {}
    
    public func meshPairingManager(_ manager: MeshPairingManager, didAddNewDevice meshDevice: MeshDevice) {}
    
    public func meshPairingManagerDidFinishPairing(_ manager: MeshPairingManager) {}
    
}

public class MeshPairingManager: NSObject {
    
    public static let shared = MeshPairingManager()
    
    public weak var delegate: MeshPairingManagerDelegate?
    
    public enum PairingFailedReason {
        
        /// No more new addresses in current network.
        case noMoreNewAddresses
        
        /// No new devices were found, please reset them and try pairing again.
        case noNewDevices
    }
    
    enum Status {
        
        case stopped
        case existDeviceScanning
        case factoryConnecting
        case allMacScanning
        case addressChanging
        case networkSetting
        case networkConnecting
        case newDeviceScanning
    }
    
    private var network: MeshNetwork = .factory
    
    private var status: Status = .stopped
    private var timer: Timer?
    private let connectingInterval: TimeInterval = 8
    private let scanningInterval: TimeInterval = 2
    private let setNetworkInterval: TimeInterval = 4
    private let waitingChaningAddressesInterval: TimeInterval = 8
    
    /// [macData: (old address, new address)]
    private var pendingDevices: [Data: (Int, Int)] = [:]
    private var availableAddressList: [Int] = []
    
    private override init() {
        super.init()        
    }
    
    public func startPairing(_ network: MeshNetwork, delegate: MeshPairingManagerDelegate) {
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.deviceDelegate = self
        
        self.network = network
        self.delegate = delegate
        
        pendingDevices.removeAll()
        availableAddressList = MeshAddressManager.shared.availableAddressList(network)
        MLog("availableAddressList count: \(availableAddressList.count), values \(availableAddressList)")
        
        if availableAddressList.count < 1 {
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, pairingFailed: .noMoreNewAddresses)
            }
            
            return
        }
        
        scanExistDevices()
    }
    
    public func stop() {
        
        status = .stopped
        timer?.invalidate()
        pendingDevices.removeAll()
        availableAddressList.removeAll()
                
        MeshManager.shared.stopScanNode()
        MeshManager.shared.disconnect()
    }
}

extension MeshPairingManager {
    
    private func scanExistDevices() {
        
        MLog("scanExistDevices")
        
        timer?.invalidate()
        status = .existDeviceScanning
        MeshManager.shared.scanNode(network)
        
        timer = Timer.scheduledTimer(timeInterval: connectingInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    private func connectFactoryNetwork() {
        
        MLog("connectFactoryNetwork")
        
        timer?.invalidate()
        status = .factoryConnecting
        MeshManager.shared.scanNode(.factory)
        
        timer = Timer.scheduledTimer(timeInterval: connectingInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    private func scanAllMac() {
        
        MLog("scanAllMac")
        
        timer?.invalidate()
        status = .allMacScanning
        // Need filter the device type which support mesh add, user another method to scan mac data
        // MeshCommand.requestAddressMac().send()
        MeshCommand.requestMacDeviceType(MeshCommand.Address.all).send()
        
        timer = Timer.scheduledTimer(timeInterval: scanningInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    private func changePendingDevices() {
        
        MLog("changePendingDevices")
        
        guard pendingDevices.count > 0 else {
            
            MLog("pendingDevices.count <= 0, next. setNewNetwork")
            setNewNetwork()
            return
        }
        
        timer?.invalidate()
        status = .addressChanging
        
        let consumeInterval = Double(pendingDevices.count) * MeshManager.shared.sendingTimeInterval
        
        for device in pendingDevices {
            
            let macData = device.key
            let oldAddress = device.value.0
            let newAddress = device.value.1
            
            MeshCommand.changeAddress(oldAddress, withNewAddress: newAddress, macData: macData).send()
        }
        
        timer = Timer.scheduledTimer(timeInterval: waitingChaningAddressesInterval + consumeInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    private func setNewNetwork() {
        
        MLog("setNewNetwork")
        
        timer?.invalidate()
        status = .networkSetting        
        MeshManager.shared.setNewNetwork(network, isMesh: true)
        
        timer = Timer.scheduledTimer(timeInterval: setNetworkInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
    private func scanNetworkDevices() {
        
        MLog("scanNetworkDevices")
        
        timer?.invalidate()
        status = .newDeviceScanning
        MeshManager.shared.scanMeshDevices()
        
        timer = Timer.scheduledTimer(timeInterval: scanningInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
    }
    
}

extension MeshPairingManager {
    
    @objc func timerAction(_ sender: Timer) {
        
        MLog("timerAction status \(status)")
        
        switch status {
        
        case .stopped:
            break
            
        case .existDeviceScanning:
            
            MLog("existDeviceScanning overtime, next.")
            connectFactoryNetwork()
            
        case .factoryConnecting:
            
            status = .stopped
            MLog("factoryConnecting failed, cancel.")
            MeshManager.shared.stopScanNode()
            MeshManager.shared.disconnect()
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, pairingFailed: .noNewDevices)
            }
            
        case .allMacScanning:
            
            MLog("allMacScanning no more devices, next. Change pending devices \(pendingDevices)")
            changePendingDevices()
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, didUpdateProgress: 0.42)
            }
            
        case .addressChanging:
            
            MLog("addressChanging no more devices, next. setNetworkConnecting")
            setNewNetwork()
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, didUpdateProgress: 0.56)
            }
            
        case .networkSetting:
            
            status = .networkConnecting
            MLog("networkSetting OK, next, networkConnecting")
            MeshManager.shared.scanNode(network)
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: connectingInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, didUpdateProgress: 0.70)
            }
            
        case .networkConnecting:
            
            status = .stopped
            MLog("networkConnecting failed, cancel.")
            MeshManager.shared.stopScanNode()
            MeshManager.shared.disconnect()
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, pairingFailed: .noNewDevices)
            }
            
        case .newDeviceScanning:
            
            // No more new devices
            status = .stopped
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, didUpdateProgress: 1.0)
                self.delegate?.meshPairingManagerDidFinishPairing(self)
            }
        }
    }
    
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
    
}

// MARK: - MeshManagerNodeDelegate

extension MeshPairingManager: MeshManagerNodeDelegate {
    
    public func meshManager(_ manager: MeshManager, didDiscoverNode node: MeshNode) {
        
        if let connectNode = manager.connectNode {
            
            if connectNode.peripheral.state == .connecting || connectNode.peripheral.state == .connected {
                
                return
            }
        }
        
        manager.connect(node)
    }
    
    public func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode) {
        
        switch status {
        
        case .existDeviceScanning:
            
            MLog("existDeviceScanning login, scanAllDevices")
            
            timer?.invalidate()
            MeshManager.shared.scanMeshDevices()
            
            timer = Timer.scheduledTimer(timeInterval: scanningInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, didUpdateProgress: 0.14)
            }
        
        case .factoryConnecting:
            
            MLog("factoryConnecting login, scanAllMac")
            scanAllMac()
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, didUpdateProgress: 0.28)
            }
            
        case .networkConnecting:
            
            MLog("networkConnecting OK, scanNetworkDevices")
            scanNetworkDevices()
            
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, didUpdateProgress: 0.84)
            }
            
        default:
            break
        }
    }
    
    public func meshManager(_ manager: MeshManager, didGetMac macData: Data, address: Int) {
        
        // handleMacData(address: address, macData: macData)
    }
    
}

// MARK: - MeshManagerDeviceDelegate

extension MeshPairingManager: MeshManagerDeviceDelegate {
    
    public func meshManager(_ manager: MeshManager, didUpdateMeshDevices meshDevices: [MeshDevice]) {
        
        MLog("didUpdateMeshDevices pairing... \(status)")
        
        switch status {
        
        case .existDeviceScanning:
            
            timer?.invalidate()
            
            let existAddresses = meshDevices.map { Int($0.address) }
            _ = MeshAddressManager.shared.append(existAddresses, network: network)
            
            timer = Timer.scheduledTimer(timeInterval: scanningInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
            
        case .newDeviceScanning:
            
            timer?.invalidate()
            
            let existAddresses = meshDevices.map { Int($0.address) }
            let newAddresses = MeshAddressManager.shared.append(existAddresses, network: network)
            
            timer = Timer.scheduledTimer(timeInterval: scanningInterval, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: false)
            
            DispatchQueue.main.async {
                
                meshDevices.forEach {
                    
                    if newAddresses.contains(Int($0.address)) {
                        
                        self.delegate?.meshPairingManager(self, didAddNewDevice: $0)
                    }
                }
            }
            
        default:
            MLog("Only for existDeviceScanning, newDeviceScanning")
            return
        }
    }
    
    public func meshManager(_ manager: MeshManager, device address: Int, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data) {
        
        guard deviceType.isSupportMeshAdd else {
            
            stop()
            DispatchQueue.main.async {
                
                self.delegate?.meshPairingManager(self, terminalWithUnsupportedDevice: address, deviceType: deviceType, macData: macData)
            }
            return
        }
        
        handleMacData(address: address, macData: macData)
    }
    
}

extension MeshPairingManager {
    
    private func handleMacData(address: Int, macData: Data) {
        
        guard status == .allMacScanning else {
            
            MLog("Only for allMacScanning")
            return
        }
        
        guard let newAddress = getNextAvailableAddress(address) else {
            
            if pendingDevices.count == 0 {
                
                status = .stopped
                timer?.invalidate()
                MLog("getNextAvailableAddress failed & pendingDevices.count == 0, stopped.")
                MeshManager.shared.stopScanNode()
                MeshManager.shared.disconnect()
                
                DispatchQueue.main.async {
                    
                    self.delegate?.meshPairingManager(self, pairingFailed: .noMoreNewAddresses)
                }
            }
            
            return
        }
        
        timer?.invalidate()
        pendingDevices[macData] = (address, newAddress)
        
        timer = Timer.scheduledTimer(timeInterval: scanningInterval, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: false)
    }
    
}
