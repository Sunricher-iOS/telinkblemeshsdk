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
    
    @available(*, deprecated, message: "use `meshManagerDidUpdateState` instand of it")
    @objc optional func meshManagerNeedTurnOnBluetooth(_ manager: MeshManager)
    
    @available(iOS 10.0, *)
    @objc optional func meshManagerDidUpdateState(_ manager: MeshManager, state: CBManagerState)
    
    @objc optional func meshManager(_ manager: MeshManager, didGetMac macData: Data, address: Int)
    
    @objc optional func meshManager(_ manager: MeshManager, didConfirmNewNetwork isSuccess: Bool)
    
//    @objc optional func meshManager(_ manager: MeshManager, didGet)
    
}

public protocol MeshManagerDeviceDelegate: NSObjectProtocol {
    
    func meshManager(_ manager: MeshManager, didUpdateMeshDevices meshDevices: [MeshDevice])
    
    func meshManager(_ manager: MeshManager, device address:Int, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data)
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetDate date: Date)
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetLightOnOffDuration duration: Int)
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetFirmwareVersion version: String)
    
}

extension MeshManagerDeviceDelegate {
    
    public func meshManager(_ manager: MeshManager, didUpdateMeshDevices meshDevices: [MeshDevice]) {}
    
    public func meshManager(_ manager: MeshManager, device address:Int, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data) {}
    
    public func meshManager(_ manager: MeshManager, device address: Int, didGetDate date: Date) {}
    
    public func meshManager(_ manager: MeshManager, device address: Int, didGetLightOnOffDuration duration: Int) {}
    
    public func meshManager(_ manager: MeshManager, device address: Int, didGetFirmwareVersion version: String) {}
    
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
    internal private(set) var sendingTimeInterval: TimeInterval = 0.2
    private let sendingQueue = DispatchQueue(label: "MeshManager sending")
    private let sendingQueueKey = DispatchSpecificKey<Void>()
    
    private var setNetworkState: SetNetworkState = .none
    
    override private init() {
        super.init()
        
        serialQueue.setSpecific(key: serialQueueKey, value: ())
        concurrentQueue.setSpecific(key: concurrentQueueKey, value: ())
        
        executeSerialAsyncTask {
            
            let options: [String: Any] = [
                CBCentralManagerOptionShowPowerAlertKey: false
            ]
            self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "centralManager"), options: options)
            
            MLog("init centralManager")
            Thread.sleep(forTimeInterval: 1)
        }
        
    }
    
}

// MARK: - Public

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
            
            self.network = network
            
            self.isAutoLogin = autoLogin
            self.isScanIgnoreName = ignoreName
            
            self.stopScanNode()
            self.disconnect(autoLogin: self.isAutoLogin)
            
            MLog("scanNodeTask network \(network.name), password \(network.password), autoLogin " + (autoLogin ? "true" : "false"))
            guard self.isBluetoothPowerOn() else { return }
            
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
            
            self.updateSendingTimeInterval(node)
            SampleCommandCenter.shared.removeAll()
            
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
            
            SampleCommandCenter.shared.removeAll()
            
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
            Thread.sleep(forTimeInterval: self.sendingTimeInterval)
        }
    }
    
    private enum SetNetworkState {
        
        case none
        case processing
    }
    
    public var centralManagerState: CBManagerState? {
        
        if centralManager == nil { return nil }
        return centralManager.state
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

// MARK: - Interval

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
            
            MLog("datas " + nameData.hexString + ", " + passwordData.hexString + ", " + ltkData.hexString);
            
            peripheral.writeValue(nameData, for: pairingCharacteristic, type: .withResponse)
            Thread.sleep(forTimeInterval: self.sendingTimeInterval)
            
            peripheral.writeValue(passwordData, for: pairingCharacteristic, type: .withResponse)
            Thread.sleep(forTimeInterval: self.sendingTimeInterval)
            
            peripheral.writeValue(ltkData, for: pairingCharacteristic, type: .withResponse)
            Thread.sleep(forTimeInterval: self.sendingTimeInterval)
            
            peripheral.readValue(for: pairingCharacteristic)
            Thread.sleep(forTimeInterval: self.sendingTimeInterval)
        }
    }
    
    func readFirmwareWithConnectNode() {
        
        guard self.isLogin else {
            return
        }
        
        executeSendingAsyncTask {
            
            Thread.sleep(forTimeInterval: 3)
            
            guard let firmwareCharacteristic = self.firmwareCharacteristic else { return }
            
            self.connectNode?.peripheral.readValue(for: firmwareCharacteristic)
        }
    }
    
    func writeOtaData(_ data: Data) -> Bool {
        
        guard isLogin, let otaCharacteristic = self.otaCharacteristic else {
            return false
        }
        
        self.connectNode?.peripheral.writeValue(data, for: otaCharacteristic, type: .withoutResponse)
        return true
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
        
        MLog("centralManager didDisconnectPeripheral " + (error?.localizedDescription ?? "error nil"))
        
        self.connectNode = nil
        self.isLogin = false
        
        DispatchQueue.main.async {
            
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
        
        MLog("peripheral didDiscoverServices " + "\(peripheral.services?.count ?? 0)")
        if MErrorNotNil(error) {
            return
        }
        
        executeSerialAsyncTask {
            
            peripheral.services?.forEach {
                
                peripheral.discoverCharacteristics(nil, for: $0)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        MLog("peripheral didDiscoverCharacteristicsFor \(MeshUUID.uuidDescription(service.uuid)) \(service.characteristics?.count ?? 0)")
        if MErrorNotNil(error) {
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        executeSerialAsyncTask {
            
            characteristics.forEach {
                
                MLog("characteristic \($0.uuid.uuidString)")
                
                switch $0.uuid.uuidString {
                
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
            MLog("peripheral didWriteValueFor \(MeshUUID.uuidDescription(characteristic.uuid)) error " + (error?.localizedDescription ?? ""))
            return
        }
        
        executeSerialAsyncTask {
                        
            if (MeshUUID.pairingCharacteristic == characteristic.uuid.uuidString) {
                
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
                
                self.handleOtaValue(value)
                
            case MeshUUID.firmwareCharacteristic:
                
                self.handleFirmwareValue(value)
                
            default:
                break
            }
        }
        
    }
    
}

// MARK: - Private

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
    
    func executeSerialAsyncTask(_ task: @escaping () -> Void) {
        
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
            
        case .syncDatetime:
            
            MLog("syncDatetime tag")
            
        case .getDatetime:
            
            MLog("getDatetime tag")
            
        case .datetimeResponse:
            
            MLog("datetimeResponse tag")
            self.handleDatetimeResponseData(data)
            
        case .getFirmware:
            
            MLog("getFirmware tag")
            
        case .firmwareResponse:
            
            MLog("firmwareResponse tag")
            self.handleFirmwareResponseValue(data)
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
            let address = command.src
            
            MLog("DeviceType \(address), \(deviceType.category.description), MAC \(macData.hexString)")
            
            DispatchQueue.main.async {
                
                self.deviceDelegate?.meshManager(self, device: address, didUpdateDeviceType: deviceType, macData: macData)
            }
            
        case .lightControlMode:
            
            MLog("lightControlMode ")
            handleLightCongtrolModeCommand(command)
        }
    }
    
    private func handleGetMacNotifyData(_ data: Data) {
        
        guard let command = MeshCommand(notifyData: data) else {
            
            MLog("handleGetMacNotifyData failed, cannot covert to a MeshCommand")
            return
        }
        
        let newAddress = command.param
        let macData = Data(command.userData[1...6].reversed())
        MLog("handleGetMacNotifyData newAddress " + String(format: "%02X", newAddress) + ", mac \(macData.hexString)")
        
        DispatchQueue.main.async {
            
            self.nodeDelegate?.meshManager?(self, didGetMac: macData, address: newAddress)
        }
        
    }
    
    private func handleDatetimeResponseData(_ data: Data) {
        
        guard let command = MeshCommand(notifyData: data) else {
            
            MLog("handleDatetimeResponseData failed, cannot covert to a MeshCommand")
            return
        }
        
        let year = command.param | (Int(command.userData[0]) << 8)
        let month = Int(command.userData[1])
        let day = Int(command.userData[2])
        let hour = Int(command.userData[3])
        let minute = Int(command.userData[4])
        let second = Int(command.userData[5])
        
        MLog("handleDatetimeResponseData \(year)/\(month)/\(day) \(hour):\(minute):\(second)")
        
        let calendar = Calendar.current
        let dateComponent = DateComponents(calendar: calendar,year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        
        guard let date = dateComponent.date else {
            
            MLog("handleDatetimeResponseData failed, dateComponent.date is nil")
            return
        }
        
        DispatchQueue.main.async {
            
            self.deviceDelegate?.meshManager(self, device: command.src, didGetDate: date)
        }
    }
    
    private func handleLightCongtrolModeCommand(_ command: MeshCommand) {
        
        guard let mode = MeshCommand.SrLightControlMode(rawValue: command.userData[1]) else {
            
            MLog("handleLightCongtrolModeCommand failed, unsupported mode \(command.userData[1])")
            return
        }
        
        switch mode {
        
        case .lightOnOffDuration:
            
            guard command.userData[2] == 0x00 else {
                
                MLog("lightOnOffDuration userData[2] != 0x00, is not get/response data")
                return
            }
            
            let duration = Int(command.userData[3]) | Int((command.userData[4] << 8))
            DispatchQueue.main.async {
                
                self.deviceDelegate?.meshManager(self, device: command.src, didGetLightOnOffDuration: duration)
            }
        }
    }
        
    private func handleFirmwareValue(_ value: Data) {
        
        guard let firmware = String(data: value, encoding: .utf8) else {
            return
        }
        MLog("handleFirmwareValue firmware \(firmware)")
    }
    
    private func handleOtaValue(_ value: Data) {
        
    }
    
    private func handleFirmwareResponseValue(_ value: Data) {
        
        guard let command = MeshCommand(notifyData: value) else {
            return
        }
        
        let versionData = command.userData[0...3]
        guard let version = String(data: versionData, encoding: .utf8) else {
            return
        }
        
        let isStandard = version.contains("V")
        MLog("handleFirmwareResponseValue version \(version), src \(command.src)")
        
        DispatchQueue.main.async {
            
            let currentVersion = isStandard ? version : "V0.1"
            self.deviceDelegate?.meshManager(self, device: command.src, didGetFirmwareVersion: currentVersion)
        }
    }
    
}

// MARK: - Fileprivate

extension MeshManager {
        
    fileprivate func updateSendingTimeInterval(_ node: MeshNode) {
        
        self.sendingTimeInterval = (node.deviceType.category == .rfPa) ? 0.5 : 0.2
    }
    
}
