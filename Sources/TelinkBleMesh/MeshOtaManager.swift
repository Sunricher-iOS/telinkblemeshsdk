//
//  File.swift
//  
//
//  Created by maginawin on 2021/5/25.
//

import Foundation
import CryptoAction

// MARK: - MeshOtaFile

public struct MeshOtaFile {
    
    public let name: String
    
    public let path: String
    
    public let deviceType: MeshDeviceType
    
    public let version: String
    
    public let versionCode: Float
    
    public var data: Data? {
        
        // Don't read data at first init.
        return FileHandle(forReadingAtPath: path)?.readDataToEndOfFile()
    }
    
    init?(atPath path: String) {
        
        self.path = path
        self.name = FileManager.default.displayName(atPath: path)
        
        let tempName = name.replacingOccurrences(of: "0X", with: "").replacingOccurrences(of: ".bin", with: "")
        let nameComponents = tempName.split(separator: "#")
        guard nameComponents.count == 3 else {
            return nil
        }
        guard let rawValue1 = Int(nameComponents[0], radix: 16),
              let rawValue2 = Int(nameComponents[1], radix: 16) else {
            return nil
        }
        self.deviceType = MeshDeviceType(deviceType: UInt8(rawValue1), subDeviceType: UInt8(rawValue2))
                
        self.version = String(nameComponents[2])
        self.versionCode = MeshOtaFile.getVersionCode(version)
    }
    
    public func isNeedUpdate(_ version: String) -> Bool {
        
        let value = MeshOtaFile.getVersionCode(version)
        return value < self.versionCode
    }
    
    private static func getVersionCode(_ version: String) -> Float {
        
        guard version.contains("V") else { return 0 }
        
        return Float(version.replacingOccurrences(of: "V", with: "")) ?? 0
    }
    
}

extension MeshOtaFile: Equatable {}

public func == (lhs: MeshOtaFile, rhs: MeshOtaFile) -> Bool {
    
    return lhs.path == rhs.path
}

// MARK: - MeshOtaManagerDelegate

public protocol MeshOtaManagerDelegate: NSObjectProtocol {
    
    func meshOtaManager(_ manager: MeshOtaManager, didUpdateFailed reason: MeshOtaManager.FailedReason)
    
    func meshOtaManager(_ manager: MeshOtaManager, didUpdateProgress progress: Float)
    
    func meshOtaManagerDidUpdateComplete(_ manager: MeshOtaManager)
    
}

extension MeshOtaManagerDelegate {
    
    public func meshOtaManager(_ manager: MeshOtaManager, didUpdateFailed reason: MeshOtaManager.FailedReason) {}
    
    public func meshOtaManager(_ manager: MeshOtaManager, didUpdateProgress progress: Float) {}
    
    public func meshOtaManagerDidUpdateComplete(_ manager: MeshOtaManager) {}
    
}

// MARK: - MeshOtaManager

public class MeshOtaManager: NSObject {
    
    public static let shared = MeshOtaManager()
    
    public weak var delegate: MeshOtaManagerDelegate?
    
    private var address: Int = 0
    private var network: MeshNetwork = .factory
    private var otaFile: MeshOtaFile?
    
    private var data: Data?
    private var state: State = .stopped
    private var timer: Timer?
    private let connectInterval: TimeInterval = 8
    
    public override init() {
        super.init()
    }
    
}

extension MeshOtaManager {
    
    
    public enum FailedReason {
        
        case invalidOtaFile
        case disconnected
        case connectOvertime
    }
    
}

extension MeshOtaManager {
    
    public func getLatestOtaFile(_ deviceType: MeshDeviceType) -> MeshOtaFile? {
        
        // 0x0130 ~ 0x0136 use the same firmware
        // 0x0160 ~ 0x0166 use the same firmware
        
        var realDeviceType = deviceType
        
        switch deviceType.category {
        
        case .light:
            
            if deviceType.rawValue2 >= 0x30 && deviceType.rawValue2 <= 0x36 {
                
                realDeviceType = MeshDeviceType(deviceType: deviceType.rawValue1, subDeviceType: 0x30)
                
            } else if (deviceType.rawValue2 >= 0x60 && deviceType.rawValue2 <= 0x66) {
                
                realDeviceType = MeshDeviceType(deviceType: deviceType.rawValue1, subDeviceType: 0x60)
            }
            
        default:
            break
        }        
        
        return getAllOtaFiles().first {
            
            $0.deviceType == realDeviceType
        }
    }
    
    func getAllOtaFiles() -> [MeshOtaFile] {
        
        var otaFiles: [MeshOtaFile] = []
        
        let paths = Bundle.module.paths(forResourcesOfType: "bin", inDirectory: "bin")
        
        paths.forEach {
            
            if let otaFile = MeshOtaFile(atPath: $0) {
                
                otaFiles.append(otaFile)
                MLog("getAllOtaFiles append \(otaFile.name), \(otaFile.deviceType), \(otaFile.version), \(otaFile.versionCode), \(otaFile.path)")
            }
        }
        
        return otaFiles
    }
    
}

extension MeshOtaManager {
    
    public func startOta(_ address: Int, network: MeshNetwork, otaFile: MeshOtaFile) {
        
        self.address = address
        self.network = network
        self.otaFile = otaFile
        self.state = .connecting
        
        guard let data = otaFile.data else {
            
            state = .stopped
            delegate?.meshOtaManager(self, didUpdateFailed: .invalidOtaFile)
            return
        }
        
        self.data = data
        
        connectNode()
    }
    
    public func stopOta() {
     
        state = .stopped
        timer?.invalidate()
    }
    
}

// MARK: - MeshManagerNodeDelegate

extension MeshOtaManager: MeshManagerNodeDelegate {
    
    public func meshManager(_ manager: MeshManager, didDiscoverNode node: MeshNode) {
        
        guard state == .connecting else {
            return
        }
        
        guard address == node.shortAddress else {
            return
        }
        
        if let connectNode = manager.connectNode {
            
            if connectNode.peripheral.state == .connected || connectNode.peripheral.state == .connecting {
                return
            }
        }
        
        manager.connect(node)
        
        delegate?.meshOtaManager(self, didUpdateProgress: 0.2)
    }
    
    public func meshManager(_ manager: MeshManager, didLoginNode node: MeshNode) {
        
        guard state == .connecting else {
            return
        }        
            
        timer?.invalidate()
        
        startSendData()
        delegate?.meshOtaManager(self, didUpdateProgress: 0.3)
    }
    
}

extension MeshOtaManager {
    
    private func connectNode() {
        
        state = .connecting
        timer?.invalidate()
        
        MeshManager.shared.nodeDelegate = self
        MeshManager.shared.scanNode(network, autoLogin: false)
        
        delegate?.meshOtaManager(self, didUpdateProgress: 0.1)
        
        timer = Timer.scheduledTimer(timeInterval: connectInterval, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: false)
    }
    
    private func startSendData() {
        
        guard state != .dataSending else {
            return
        }
        
        state = .dataSending
        MLog("startSendData")
        
        sendData()
    }
    
    private func sendData() {
        
        MeshManager.shared.executeSerialAsyncTask {
                        
            guard let data = self.data, data.count > 0 else {
                
                self.state = .stopped
                MLog("data is nil, return")
                
                DispatchQueue.main.async {
                    
                    self.delegate?.meshOtaManager(self, didUpdateFailed: .invalidOtaFile)
                }
                
                return
            }
            
            var dataItem: Data!
            var interval = 0.3
            var dataIndex = 0
            var sendingIndex = 0
            
            var progress = 0
            
            while dataIndex < data.count {
                
                // dataIndex / data.count * 0.6 * 100, range from [0, 1] to [0, 60]
                let newProgress = Int(round(Float(dataIndex) * 60 / Float(data.count))) + 30
                if (newProgress != progress) {
                    
                    progress = newProgress
                    DispatchQueue.main.async {
                        
                        self.delegate?.meshOtaManager(self, didUpdateProgress: Float(progress) * 0.01)
                    }
                }
                
                if self.state == .stopped {
                    
                    MLog("send stopped")
                    return
                }
                
                if data.count - dataIndex >= 16 {
                    
                    dataItem = Data(data[dataIndex..<(dataIndex + 16)])
                    dataIndex += 16
                    
                } else {
                    
                    dataItem = Data(data[dataIndex...])
                    dataIndex = data.count
                }
                
                let exeData = CryptoAction.getOtaData(dataItem, index: Int32(sendingIndex))!
                
                guard MeshManager.shared.writeOtaData(exeData) else {
                    
                    self.state = .stopped
                    
                    DispatchQueue.main.async {
                        
                        self.delegate?.meshOtaManager(self, didUpdateFailed: .disconnected)
                    }
                    
                    return
                }
                MLog("send ota data index \(sendingIndex)")
                
                Thread.sleep(forTimeInterval: interval)
                sendingIndex += 1
                interval = 0.01
            }
            
            let endData = CryptoAction.getOtaEndData(Int32(sendingIndex))!
            guard MeshManager.shared.writeOtaData(endData) else {
                
                self.state = .stopped
                
                DispatchQueue.main.async {
                    
                    self.delegate?.meshOtaManager(self, didUpdateFailed: .disconnected)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                
                self.delegate?.meshOtaManager(self, didUpdateProgress: 0.95)
            }
            
            Thread.sleep(forTimeInterval: 6.0)
            
            MLog("send completed")
            self.state = .stopped
            
            DispatchQueue.main.async {
                
                self.delegate?.meshOtaManagerDidUpdateComplete(self)
            }
        }
    }
    
    @objc private func timerAction() {
        
        switch state {
        
        case .stopped:
            break
            
        case .connecting:
            
            MeshManager.shared.stopScanNode()
            stopOta()
            delegate?.meshOtaManager(self, didUpdateFailed: .connectOvertime)
            
        case .dataSending:
            break
        }
        
    }
    
}

extension MeshOtaManager {
    
    private enum State {
        
        case stopped
        case connecting
        case dataSending
    }
    
}
