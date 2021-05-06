//
//  File.swift
//  
//
//  Created by maginawin on 2021/1/13.
//

import Foundation
import CoreBluetooth
import CryptoAction

@objc public protocol MeshManagerNodeDelegate: NSObjectProtocol {
    
    @objc optional func meshManager(_ manager: MeshManager, didDiscoverNode node: MeshNode)
    
    @objc optional func meshManager(_ manager: MeshManager, didConnectNode node: MeshNode)
    
    @objc optional func meshManager(_ manager: MeshManager, didDisconnectNodeIdentifier identifier: UUID)
    
    @objc optional func meshManager(_ manager: MeshManager, didFailToConnectNodeIdentifier identifier: UUID)
    
    @objc optional func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode)
    
    @objc optional func meshManager(_ manager: MeshManager, didFailToLoginNodeIdentifier identifier: UUID)
    
    @objc optional func meshManagerNeedTurnOnBluetooth(_ manager: MeshManager)
    
    @available(iOS 10.0, *)
    @objc optional func meshManagerDidUpdateState(_ manager: MeshManager, state: CBManagerState)
    
    @objc optional func meshManager(_ manager: MeshManager, didGetMac macData: Data, address: Int)
    
    @objc optional func meshManager(_ manager: MeshManager, didConfirmNewNetwork isSuccess: Bool)
    
}

public protocol MeshManagerDeviceDelegate: NSObjectProtocol {
    
    func meshManager(_ manager: MeshManager, didUpdateMeshDevices meshDevices: [MeshDevice])
    
    func meshManager(_ manager: MeshManager, device address:UInt8, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data)
    
}

public class MeshManager: NSObject {
    
    public static let shared = MeshManager()
    
    public weak var nodeDelegate: MeshManagerNodeDelegate?
    
    public weak var deviceDelegate: MeshManagerDeviceDelegate?
    
    /**
     The default is `true`.
     */
    public var isDebugEnabled: Bool = true
    
    /**
     Current network. The default is `MeshNetwork.factory`.
     */
    public internal(set) var network = MeshNetwork.factory
    
    public private(set) var isLogin = false
    
    
    private var centralManager: CBCentralManager!
    private let serialQueue = DispatchQueue(label: "MeshManager serial")
    private let serialQueueKey = DispatchSpecificKey<Void>()
    private let concurrentQueue = DispatchQueue(label: "MeshManager concurrent", qos: .default, attributes: .concurrent)
    private let concurrentQueueKey = DispatchSpecificKey<Void>()
    
    private var isAutoLogin: Bool = false
    private var isScanIgnoreName: Bool = false
    
    var connectNode: MeshNode?
    
    private var notifyCharacteristic: CBCharacteristic?
    private var commandCharacteristic: CBCharacteristic?
    private var pairingCharacteristic: CBCharacteristic?
    private var otaCharacteristic: CBCharacteristic?
    private var firmwareCharacteristic: CBCharacteristic?
    
    // Crypto
    private let loginRand = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
    private var sectionKey = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
    
    // 200ms every command
    private let sendingTimeInterval: TimeInterval = 0.2
    private let sendingQueue = DispatchQueue(label: "MeshManager sending")
    private let sendingQueueKey = DispatchSpecificKey<Void>()
    
    private var setNetworkState: SetNetworkState = .none
    
    override private init() {
        super.init()
        
        serialQueue.setSpecific(key: serialQueueKey, value: ())
        concurrentQueue.setSpecific(key: concurrentQueueKey, value: ())
        
        executeSerialAsyncTask {
            
            let options: [String: Any] = [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
            self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "centralManager"), options: options)
            
            MLog("init centralManager")
            Thread.sleep(forTimeInterval: 1)
        }
        
    }
    
}

extension MeshManager {
    
    /**
     Scan nodes.
     
     - Parameters:
        - network: Scanning `MeshNetwork`.
        - autoLogin: Auto connect and login the node with `network` if `autoLogin` equals `true`. The default is `false`.
        - ignoreName: Scan all nodes if `ignoreName` is equals `true`. The default is false.
     */
    public func scanNode(_ network: MeshNetwork, autoLogin: Bool = false, ignoreName: Bool = false) {
        
        executeSerialAsyncTask {
            
            self.isAutoLogin = autoLogin
            self.isScanIgnoreName = ignoreName
            
            self.stopScanNode()
            self.disconnect(autoLogin: self.isAutoLogin)
            
            MLog("scanNodeTask network \(network.name), password \(network.password), autoLogin " + (autoLogin ? "true" : "false"))
            guard self.isBluetoothPowerOn() else { return }
            
            self.network = network
            
            let options: [String: Any] = [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ]
            
            self.centralManager.scanForPeripherals(withServices: nil, options: options)
        }
    }
    
    /**
     Stop scan node.
     */
    public func stopScanNode() {
        
        executeSerialAsyncTask {
            
            MLog("stopScanNode")
            guard self.isBluetoothPowerOn() else { return }
            
            self.centralManager.stopScan()
        }
    }
    
    /**
     Stop scan node, disconnect, then connect the `node`. If the state of node is connected or connecting, trigger the `self.delegate.meshManager(_, didConnect:)` then `return`.
     
     - Parameter node: Connecting `MeshNode`.
     */
    public func connect(_ node: MeshNode) {
        
        executeSerialAsyncTask {
            
            self.setNetworkState = .none
            
            MLog("connect")
            guard self.isBluetoothPowerOn() else { return }
            
            self.stopScanNode()
            self.disconnect(autoLogin: self.isAutoLogin)
            
            self.connectNode = node
            let options: [String: Any] = [
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
            ]
            self.centralManager.connect(node.peripheral, options: options)
        }
    }
    
    /**
     Disconnect all nodes and set `isAutoLogin` to `false`.
     */
    public func disconnect() {

        disconnect(autoLogin: false)
    }
    
    private func disconnect(autoLogin: Bool) {
        
        executeSerialAsyncTask {
            
            self.isAutoLogin = autoLogin
            self.isLogin = false
            
            self.connectNode = nil
            self.pairingCharacteristic = nil
            self.notifyCharacteristic = nil
            self.commandCharacteristic = nil
            self.otaCharacteristic = nil
            
            MLog("disconnect autoLogin: \(autoLogin)")
            guard self.isBluetoothPowerOn() else { return }
            
            let accessServiceUUID = CBUUID(string: MeshUUID.accessService)
            let peripherals = self.centralManager.retrieveConnectedPeripherals(withServices: [accessServiceUUID])
            peripherals.forEach {
                
                if $0.state == .connected || $0.state == .connecting {
                    
                    self.centralManager.cancelPeripheralConnection($0)
                }
            }
            
            SampleCommandCenter.shared.removeAll()
            
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
    
    public var isConnected: Bool {
        
        return connectNode?.peripheral.state == .connected
    }
    
    /**
     Scan `MeshDevice` after login success.
     */
    public func scanMeshDevices() {
        
        executeSendingAsyncTask {
            
            MLog("scanMeshDevice")
            guard self.isBluetoothPowerOn() else { return }
            
            guard self.isConnected,
                  let notifyCharacteristic = self.notifyCharacteristic else {
                
                return
            }
            
            let data = Data([0x01])
            self.connectNode?.peripheral.writeValue(data, for: notifyCharacteristic, type: .withResponse)
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
    
    private enum SetNetworkState {
        
        case none
        case processing
    }
    
    /**
     Send command to the connected node.
     
     - Parameters:
        - command: Sending command.
        - isSample: The defualt is `false`.
     */
    public func send(_ command: MeshCommand, isSample: Bool = false) {
        
        if isSample {
            
            SampleCommandCenter.shared.append(command)
            return
        }
        
        executeSendingAsyncTask {
            
            MLog("send command isSample \(isSample)")
            guard self.isBluetoothPowerOn() else { return }
            
            guard self.isConnected,
                  let commandCharacteristic = self.commandCharacteristic,
                  let macValue = self.connectNode?.macValue else {
                
                return
            }
            
            let commandData = command.commandData
            guard let data = CryptoAction.exeCMD(commandData, mac: macValue, sectionKey: self.sectionKey) else {
                
                return
            }
            MLog("Data \(commandData.hexString)")
            self.connectNode?.peripheral.writeValue(data, for: commandCharacteristic, type: .withoutResponse)
        }        
    }
    
}

extension MeshManager {
    
    /**
     Set new network for the devices in the current network.
     
     - Parameters:
        - network: The new network.
     */
    func setNewNetwork(_ network: MeshNetwork) {
        
        executeSerialAsyncTask {
            
            self.setNetworkState = .processing
            
            MLog("setNewNetwork \(network.name), \(network.password)")
            guard self.isBluetoothPowerOn() else { return }
            
            guard self.isConnected,
                  let peripheral = self.connectNode?.peripheral,
                  let pairingCharacteristic = self.pairingCharacteristic,
                  let nameData = CryptoAction.getNetworkName(network.name, sectionKey: self.sectionKey),
                  let passwordData = CryptoAction.getNetworkPassword(network.password, sectionKey: self.sectionKey),
                  let ltkData = CryptoAction.getNetworkLtk(self.sectionKey) else {
                
                return
            }
            
            peripheral.writeValue(nameData, for: pairingCharacteristic, type: .withResponse)
            Thread.sleep(forTimeInterval: 0.2)
            
            peripheral.writeValue(passwordData, for: pairingCharacteristic, type: .withResponse)
            Thread.sleep(forTimeInterval: 0.2)
            
            peripheral.writeValue(ltkData, for: pairingCharacteristic, type: .withResponse)
            Thread.sleep(forTimeInterval: 0.2)
            
            peripheral.readValue(for: pairingCharacteristic)
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
    
}

// MARK: - CBCentralManagerDelegate

extension MeshManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        MLog("centralManagerDidUpdateState \(central.state)")
        
        self.isLogin = false 
        
        DispatchQueue.main.async {
            
            if #available(iOS 10.0, *) {
                
                self.nodeDelegate?.meshManagerDidUpdateState?(self, state: central.state)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard RSSI.intValue <= 0 else { return }
        
        executeSerialAsyncTask {
            
            guard let name = advertisementData["kCBAdvDataLocalName"] as? String else { return }
            
            guard self.network.name == name || self.isScanIgnoreName else { return }
            
            MLog("centralManager did discover peripheral \(name), data \(advertisementData), rssi \(RSSI.intValue)")
            
            guard let meshNode = MeshNode(peripheral, advertisementData: advertisementData, rssi: RSSI.intValue) else {
                
                return
            }
            
            if self.isAutoLogin && self.network.name == name && self.connectNode == nil {
                
                self.connect(meshNode)
            }
            
            DispatchQueue.main.async {
                
                self.nodeDelegate?.meshManager?(self, didDiscoverNode: meshNode)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        MLog("centralManager didConnect")
        
        DispatchQueue.main.async {
            
            guard let node = self.connectNode, node.peripheral.identifier == peripheral.identifier else {
                return
            }
            
            self.nodeDelegate?.meshManager?(self, didConnectNode: node)
        }
        
        executeSerialAsyncTask {
            
            self.stopScanNode()
            
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        MLog("centralManager didFailToConnect")
        _ = MErrorNotNil(error)
        
        self.connectNode = nil
        
        DispatchQueue.main.async {
            
            if self.isAutoLogin {
                
                self.scanNode(self.network, autoLogin: self.isAutoLogin, ignoreName: self.isScanIgnoreName)
            }
            
            self.nodeDelegate?.meshManager?(self, didFailToConnectNodeIdentifier: peripheral.identifier)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        MLog("centralManager didDisconnectPeripheral")
        
        self.connectNode = nil
        
        DispatchQueue.main.async {
            
            self.isLogin = false
            
            if self.isAutoLogin {
                
                self.scanNode(self.network, autoLogin: self.isAutoLogin, ignoreName: self.isScanIgnoreName)
            }
            
            self.nodeDelegate?.meshManager?(self, didDisconnectNodeIdentifier: peripheral.identifier)
        }
    }
    
}

// MARK: - CBPeripheralDelegate

extension MeshManager: CBPeripheralDelegate {
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        
        let name = peripheral.name ?? "nil"
        MLog("peripheralDidUpdateName \(name)")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        MLog("peripheral didDiscoverServices")
        if MErrorNotNil(error) {
            return
        }
        
        executeSerialAsyncTask {
            
            if let accessService = peripheral.services?.first(where: { $0.uuid.uuidString == MeshUUID.accessService }) {
                
                MLog("accessService found")
                peripheral.discoverCharacteristics(nil, for: accessService)
            }
            
            if let deviceInformationService = peripheral.services?.first(where: { $0.uuid.uuidString == MeshUUID.deviceInformationService }) {
                
                MLog("deviceInformationService found")
                peripheral.discoverCharacteristics(nil, for: deviceInformationService)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        MLog("peripheral didDiscoverCharacteristicsFor \(MeshUUID.uuidDescription(service.uuid))")
        if MErrorNotNil(error) {
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        executeSerialAsyncTask {
            
            characteristics.forEach {
                
                let uuidString = $0.uuid.uuidString
                
                switch uuidString {
                
                case MeshUUID.notifyCharacteristic:
                    
                    self.notifyCharacteristic = $0
                    peripheral.setNotifyValue(true, for: $0)
                    
                case MeshUUID.commandCharacteristic:
                    
                    self.commandCharacteristic = $0
                    
                case MeshUUID.pairingCharacteristic:
                    
                    self.pairingCharacteristic = $0
                    
                    CryptoAction.getRandPro(self.loginRand, len: 8)
                    
                    let pResult = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
                    CryptoAction.encryptPair(self.network.name, pas: self.network.password, prand: self.loginRand, pResult: pResult)
                    let raw = UnsafeRawPointer(pResult)
                    var data = Data(bytes: raw, count: 16)
                    data.insert(12, at: 0)
                    pResult.deallocate()
                    
                    peripheral.writeValue(data, for: $0, type: .withResponse)
                    
                case MeshUUID.otaCharacteristic:
                    
                    self.otaCharacteristic = $0
                    
                case MeshUUID.firmwareCharacteristic:
                    
                    self.firmwareCharacteristic = $0
                
                default:
                    break
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        MLog("peripheral didWriteValueFor \(MeshUUID.uuidDescription(characteristic.uuid))")
        if MErrorNotNil(error) {
            return
        }
        
        executeSerialAsyncTask {
            
            if (characteristic.uuid.uuidString == MeshUUID.pairingCharacteristic) {
                
                if self.setNetworkState == .processing {
                    
                    return
                }
                
                peripheral.readValue(for: characteristic)
            }
        }
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let value = characteristic.value, value.count > 0 else {
            MLog("peripheral didUpdateValue nil, return")
            return
        }
        
        MLog("peripheral didUpdateValue, \n=> \(value.hexString) \(MeshUUID.uuidDescription(characteristic.uuid))")
        if MErrorNotNil(error) {
            return
        }
        
        executeSerialAsyncTask {
            
            switch characteristic.uuid.uuidString {
            
            case MeshUUID.notifyCharacteristic:
                
                self.handleNotifyValue(peripheral, value: value)
                
            case MeshUUID.commandCharacteristic:
                
                MLog("commandCharacteristic didUpdateValue \(value.hexString)")
            
            case MeshUUID.pairingCharacteristic:
                
                self.handlePairingValue(peripheral, value: value)
                        
            case MeshUUID.otaCharacteristic:
                
                MLog("otaCharacteristic didUpdateValue \(value.hexString)")
                
            case MeshUUID.firmwareCharacteristic:
                
                MLog("firmwareCharacteristic didUpdateValue \(value.hexString)")
                
            default:
                break
            }
        }
        
    }
    
}

extension MeshManager {
    
    private func isBluetoothPowerOn() -> Bool {
        
        if centralManager.state != .poweredOn {
            
            DispatchQueue.main.async {
                
                self.nodeDelegate?.meshManagerNeedTurnOnBluetooth?(self)
            }
            
            return false
        }
        
        return true
    }
    
}

// MARK: - Queue tasks

extension MeshManager {
    
    private func executeSerialAsyncTask(_ task: @escaping () -> Void) {
        
        if DispatchQueue.getSpecific(key: serialQueueKey) != nil {
            
            task()
            
        } else {
            
            serialQueue.async { task() }
        }
    }
    
    private func executeConcurrentAsyncTask(_ task: @escaping () -> Void) {
        
        if DispatchQueue.getSpecific(key: concurrentQueueKey) != nil {
            
            task()
            
        } else {
            
            concurrentQueue.async { task() }
        }
    }
    
    private func executeSendingAsyncTask(_ task: @escaping () -> Void) {
        
        if DispatchQueue.getSpecific(key: sendingQueueKey) != nil {
            
            task()
            Thread.sleep(forTimeInterval: self.sendingTimeInterval)
            
        } else {
            
            sendingQueue.async {
                
                task()
                Thread.sleep(forTimeInterval: self.sendingTimeInterval)
            }
        }
    }
    
}

// MARK: - did update value handlers

extension MeshManager {
    
    private func handlePairingValue(_ peripheral: CBPeripheral, value: Data) {
        
        if setNetworkState == .processing {
            
            setNetworkState = .none
            let isSuccess = value.first == 0x07
            let log = "setNetworkState isSuccess " + (isSuccess ? "TRUE" : "FALSE")
            MLog(log)
            
            if let firmwareCharacteristic = self.firmwareCharacteristic {
                
                peripheral.readValue(for: firmwareCharacteristic)
            }
            
            DispatchQueue.main.async {
                
                self.nodeDelegate?.meshManager?(self, didConfirmNewNetwork: isSuccess)
            }
            
            return
        }
        
        guard value.count > 1, value.first == 0x0D else {
            
            MLog("pairingCharacteristic didUpdateValue value.first != 0x0D, return")
            
            if !self.isLogin {
                
                DispatchQueue.main.async {
                    
                    self.nodeDelegate?.meshManager?(self, didFailToLoginNodeIdentifier: peripheral.identifier)
                }
                
                self.disconnect(autoLogin: self.isAutoLogin)
            }
            
            return
        }
        
        let tempData = Data(value[1...])
        let prandCount = value.count - 1
        let prand = UnsafeMutablePointer<UInt8>.allocate(capacity: prandCount)
        defer { prand.deallocate() }
        for i in 0..<(prandCount) {
            let temp = tempData[i]
            prand[i] = temp
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        defer { buffer.deallocate() }
        memset(buffer, 0, 16)
        
        if CryptoAction.encryptPair(self.network.name, pas: self.network.password, prand: prand, pResult: buffer) {
            
            memset(buffer, 0, 16)
            
            CryptoAction.getSectionKey(self.network.name, pas: self.network.password, prandm: self.loginRand, prands: prand, pResult: buffer)
            
            memcpy(self.sectionKey, buffer, 16)
            
            self.isLogin = true
            MLog("login successful")
            
            DispatchQueue.main.async {
                
                guard let node = self.connectNode,
                      node.peripheral.identifier == peripheral.identifier else {
                    
                    return
                }
                
                self.nodeDelegate?.meshManager?(self, didLoginNode: node)
            }
            
        } else {
            
            MLog("pairingCharacteristic CryptoAction.encryptPair failed.")
            
            DispatchQueue.main.async {
                
                self.nodeDelegate?.meshManager?(self, didFailToLoginNodeIdentifier: peripheral.identifier)
            }
            
            self.disconnect(autoLogin: self.isAutoLogin)
        }
    }
    
    private func handleNotifyValue(_ peripheral: CBPeripheral, value: Data) {
        
        guard let macValue = self.connectNode?.macValue else {
            MLog("connectNode is nil, return")
            return
        }
        guard value.count == 20, !(value[0] == 0 && value[1] == 0 && value[2] == 0) else {
            MLog("value format error")
            return
        }
        guard let data = CryptoAction.pasterData(value, mac: macValue, sectionKey: self.sectionKey) else {
            
            return
        }
        
        MLog("handleNotifyValue \(data.hexString)")
        
        let tagValue = data[7]
        guard let tag = MeshCommand.Tag(rawValue: tagValue) else {
            
            MLog("Unsupported tag " + String(format: "0x%02X", tagValue))
            return
        }
        
        switch tag {
        
        case .lightStatus:
            
            MLog("lightStatus tag")
            self.handleLightStatusData(data)
            
        case .nodeToApp:
            
            MLog("nodeToApp tag")
            self.handleNodeToAppData(data)
            
        case .appToNode:
            
            MLog("appToNode tag")
            
        case .onOff:
            
            MLog("onOff tag")
            
        case .brightness:
            
            MLog("brightness tag")
            
        case .singleChannel:
            
            MLog("singleChannel tag")
            
        case .replaceAddress:
            
            MLog("replaceNodeAddress tag")
            
        case .getMacNotify:
            
            MLog("getMacNotify tag")
            self.handleGetMacNotifyData(data)
            
        case .resetNetwork:
            
            MLog("resetNetwork tag")
        }
    }
    
    private func handleLightStatusData(_ data: Data) {
        
        let devices = MeshDevice.makeMeshDevices(data)
        
        guard devices.count > 0 else {
            
            return
        }
        
        devices.forEach {
            
            MLog("Get MeshDevice \($0.description)")
        }
        
        DispatchQueue.main.async {
            
            self.deviceDelegate?.meshManager(self, didUpdateMeshDevices: devices)
        }
    }
    
    private func handleNodeToAppData(_ data: Data) {
        
        guard let command = MeshCommand(notifyData: data) else {
            
            MLog("handleNodeToAppData failed, cannot covert to a MeshCommand")
            return
        }
        
        guard let identifier = MeshCommand.SrIndentifier(rawValue: command.userData[0]) else {
            
            MLog("handleNodeToAppData failed, unsupported identifier " + String(format: "0x02X", command.userData[0]))
            return
        }
        
        switch identifier {
        
        case .mac:
            
            let deviceType = MeshDeviceType(deviceType: command.userData[1], subDeviceType: command.userData[2])
            let macData = Data(command.userData[3...8].reversed())
            let address = UInt8(command.src)
            
            MLog("DeviceType \(address), \(deviceType.category.description), MAC \(macData.hexString)")
            
            DispatchQueue.main.async {
                
                self.deviceDelegate?.meshManager(self, device: address, didUpdateDeviceType: deviceType, macData: macData)
            }
        }
    }
    
    private func handleGetMacNotifyData(_ data: Data) {
        
        guard let command = MeshCommand(notifyData: data) else {
            
            MLog("handleNewNodeAddressData failed, cannot covert to a MeshCommand")
            return
        }
        
        let newAddress = command.param
        let macData = Data(command.userData[1...6].reversed())
        MLog("handleNewNodeAddressData newAddress " + String(format: "%02X", newAddress) + ", mac \(macData.hexString)")
        
        DispatchQueue.main.async {
            
            self.nodeDelegate?.meshManager?(self, didGetMac: macData, address: newAddress)
        }
        
    }
    
}


