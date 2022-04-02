//
//  File.swift
//  
//
//  Created by maginawin on 2022/2/26.
//

import Foundation
import CoreNFC

// MARK: - SmartSwitchManagerDelegate

public protocol SmartSwitchManagerDelegate {
    
    /// progress range [0, 100]
    func smartSwitchManager(_ manager: SmartSwitchManager, didReceiveData progress: Int)
    
    func smartSwitchManagerDidReceiveDataEnd(_ manager: SmartSwitchManager)
    
    func smartSwitchManagerDidReceiveDataFailed(_ manager: SmartSwitchManager)
    
    func smartSwitchManagerDidConfigureSuccessful(_ manager: SmartSwitchManager)
    
    func smartSwitchManagerDidReadConfiguration(_ manager: SmartSwitchManager, isConfigured: Bool, mode: SmartSwitchMode?)
    
    func smartSwitchManagerDidUnbindConfigurationSuccessful(_ manager: SmartSwitchManager)
    
}

public protocol SmartSwitchManagerDataSource {
    
    func smartSwitchManager(_ manager: SmartSwitchManager, nfcConnectFailed state: SmartSwitchManager.State) -> String
    
    func smartSwitchManager(_ manager: SmartSwitchManager, nfcScanningMessage state: SmartSwitchManager.State) -> String
    
    func smartSwitchManager(_ manager: SmartSwitchManager, nfcReadWriteFailedMessage state: SmartSwitchManager.State) -> String
    
    func smartSwitchManager(_ manager: SmartSwitchManager, nfcReadWriteSuccessfulMessage state: SmartSwitchManager.State) -> String
    
}

// MARK: - 

public class SmartSwitchManager: NSObject {
    
    public static let shared = SmartSwitchManager()
    
    public var delegate: SmartSwitchManagerDelegate?
    public var dataSource: SmartSwitchManagerDataSource?
    
    private var dataList: [MeshCommand] = []
    
    private let maxIndex = 92
    private let maxCount = 93
    
    private var state: State = .startConfig
    
    private override init() {
        
    }
    
    public var secretKey: Data? {
        
        guard dataList.count == maxCount else {
            return nil
        }
        
        var data = Data()
        
        for i in 0..<92 {
            
            let itemData = dataList[i].userData[1...8]
            data.append(contentsOf: itemData)
        }
        
        return data 
    }
    
    public var checkSum: Int {
        
        guard dataList.count == maxCount,
              let command = dataList.last else {
                  
                  return 0
              }
        
        let s1 = Int(command.userData[1]) 
        let s2 = Int(command.userData[2]) << 8
        let s3 = Int(command.userData[3]) << 16
        let s4 = Int(command.userData[4]) << 24
        
        return s1 | s2 | s3 | s4 
    }
    
    public var isValid: Bool {
        
        return checkSum != 0
    }
    
    private var mode: SmartSwitchMode = .default
    
}

extension SmartSwitchManager {
    
    /// You must clear data before get secret key!
    public func clear() {
        
        dataList.removeAll()
    }
    
    @available(iOS 13.0, *)
    public func startConfiguration(mode: SmartSwitchMode, alertMessage: String) {
        
        state = .startConfig
        
        guard isValid else { return }
        
        self.mode = mode
        
        let session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
        session?.alertMessage = alertMessage
        session?.begin()
    }
    
    @available(iOS 13.0, *)
    public func readConfiguration(alertMessage: String) {
        
        state = .readConfig
        
        let session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
        session?.alertMessage = alertMessage
        session?.begin()
    }
    
    @available(iOS 13.0, *)
    public func unbindConfiguration(alertMessage: String) {
        
        state = .unbindConfig
        
        let session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
        session?.alertMessage = alertMessage
        session?.begin()
    }
    
}

// MARK: - ---

extension SmartSwitchManager {
    
    func append(_ command: MeshCommand) {
        
        guard command.tag == MeshCommand.Tag.appToNode,
              command.param == 0x11 else {
                  
                  return
              }
        
        let index = command.userData[0]
        guard index == dataList.count else {
            
            // Error data 
            dataList.removeAll()
            NSLog("smart switch failed, index != datalist.count \(index) \(dataList.count)", "")
            
            DispatchQueue.main.async {
                self.delegate?.smartSwitchManagerDidReceiveDataFailed(self)
            }
            
            return
        }
        
        dataList.append(command)
        
        NSLog("smart switch getting index \(index), count \(dataList.count)", "")
        
        DispatchQueue.main.async {
            self.delegate?.smartSwitchManager(self, didReceiveData: Int(round(Float(index) * 100.0 / Float(self.maxIndex))))
        }
        
        if index == maxIndex && dataList.count == maxCount {
            
            NSLog("smart switch data end", "")
            DispatchQueue.main.async {
                self.delegate?.smartSwitchManagerDidReceiveDataEnd(self)
            }
        }
    }
    
}

// MARK: - NFC

@available(iOS 13.0, *)
extension SmartSwitchManager: NFCTagReaderSessionDelegate {
    
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
        NSLog("tagReaderSessionDidBecomeActive", "")
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        
        NSLog("tagReaderSession didInvalidateWithError \(error.localizedDescription)", "")
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        
        NSLog("tagReaderSession didDetect tags \(tags.count)", "")
        
        guard tags.count > 0 else {
            
            if let message = dataSource?.smartSwitchManager(self, nfcConnectFailed: self.state) {
                
                session.invalidate(errorMessage: message)
            }
            return
        }
        
        for item in tags {
            
            switch item {
            
            case .miFare(let miFareTag):
                
                NSLog("connect to miFareTag \(miFareTag)", "")
                
                session.connect(to: item) { connectError in
                    
                    guard connectError == nil else {
                        
                        NSLog("connectError \(connectError!.localizedDescription)", "")
                        
                        if let message = self.dataSource?.smartSwitchManager(self, nfcConnectFailed: self.state) {
                            
                            session.invalidate(errorMessage: message)
                        }
                        return
                    }
                    
                    NSLog("state \(self.state)", "")
                    self.sendAuth(session: session, tag: miFareTag) {
                        
                        switch self.state {
                            
                        case .startConfig:
                            self.writeConfiguration(session: session, tag: miFareTag)
                            
                        case .readConfig:
                            self.readConfigurationHandler(session: session, tag: miFareTag)
                            
                        case .unbindConfig:
                            self.writeUnbindConfiguration(session: session, tag: miFareTag)
                        }
                    }
                }
                
            default:
                
                if let message = dataSource?.smartSwitchManager(self, nfcConnectFailed: self.state) {
                    
                    session.invalidate(errorMessage: message)
                }
            }
        }
    }
    
    private func writeConfiguration(session: NFCTagReaderSession, tag: NFCMiFareTag) {
        
        guard let secretKey = self.secretKey, secretKey.count == 736 else {
            NSLog("Write secret key failed, no valid secret key.", "")
            return
        }
        
        if let configuringMessage = dataSource?.smartSwitchManager(self, nfcScanningMessage: self.state) {
            
            session.alertMessage = configuringMessage
        }
        
        var index = 0
        var callback: ((Data, Error?) -> Void)!
        
        callback = { receive, error in
            
            guard error == nil else {
                
                NSLog("Write configuration error \(error!.localizedDescription), index \(index)", "")
                
                if let failedMessage = self.dataSource?.smartSwitchManager(self, nfcReadWriteFailedMessage: self.state) {
                    
                    session.invalidate(errorMessage: failedMessage)
                }
                return
            }
            
            switch index {
                
            case 183:
                
                NSLog("Write secret key successful, write sum next.", "")
                
                let page = UInt8(196)
                let sum = self.checkSum
                let sum1 = UInt8(sum & 0xFF)
                let sum2 = UInt8((sum >> 8) & 0xFF)
                let sum3 = UInt8((sum >> 16) & 0xFF)
                let sum4 = UInt8((sum >> 24) & 0xFF)
                let data = Data([0xA2, page, sum1, sum2, sum3, sum4])
                
                index += 1
                tag.sendMiFareCommand(commandPacket: data, completionHandler: callback)
                
            case 184:
                
                NSLog("Write check sum successful, write check tag next.", "")
                
                let data = Data([0xA2, 0x07, 0x5A, 0x38, 0x00, UInt8(self.mode.rawValue)])
                
                index += 1
                tag.sendMiFareCommand(commandPacket: data, completionHandler: callback)
                
            case 185:
                
                NSLog("Configure successful.", "")
                if let message = self.dataSource?.smartSwitchManager(self, nfcReadWriteSuccessfulMessage: self.state) {
                    session.alertMessage = message
                }
                session.invalidate()
                
                DispatchQueue.main.async {
                    
                    self.delegate?.smartSwitchManagerDidConfigureSuccessful(self)
                }
                
            default:
                
                NSLog("Wrote secret key \(index)", "")
                
                index += 1
                
                let page = UInt8(index + 8)
                let dataIndex = index * 4
                let pageData = secretKey[dataIndex..<(dataIndex + 4)]
                var data = Data([0xA2, page])
                data.append(contentsOf: pageData)
                
                tag.sendMiFareCommand(commandPacket: data, completionHandler: callback)
            }
        }
        
        // Send first frame data.
        let page = UInt8(index + 8)
        let dataIndex = index * 4
        let pageData = secretKey[dataIndex..<(dataIndex + 4)]
        var data = Data([0xA2, page])
        data.append(contentsOf: pageData)
        tag.sendMiFareCommand(commandPacket: data, completionHandler: callback)
    }
    
    private func readConfigurationHandler(session: NFCTagReaderSession, tag: NFCMiFareTag) {
        
        if let configuringMessage = dataSource?.smartSwitchManager(self, nfcScanningMessage: self.state) {
            
            session.alertMessage = configuringMessage
        }
        
        let data = Data([0x30, 0x07])
        tag.sendMiFareCommand(commandPacket: data) { receive, error in
            
            guard error == nil, receive.count >= 4 else {
                
                NSLog("Read configuration error \(error!.localizedDescription)", "")
                
                if let failedMessage = self.dataSource?.smartSwitchManager(self, nfcReadWriteFailedMessage: self.state) {
                    
                    session.invalidate(errorMessage: failedMessage)
                }
                return
            }
            
            if let message = self.dataSource?.smartSwitchManager(self, nfcReadWriteSuccessfulMessage: self.state) {
                
                session.alertMessage = message
            }
            
            // 0x5A, 0x38, other, mode
            if receive[0] == 0x5A, receive[1] == 0x38 {
                
                let mode = SmartSwitchMode(rawValue: Int(receive[3]))
                DispatchQueue.main.async {
                    
                    self.delegate?.smartSwitchManagerDidReadConfiguration(self, isConfigured: true, mode: mode)
                }
                
            } else {
                
                DispatchQueue.main.async {
                    
                    self.delegate?.smartSwitchManagerDidReadConfiguration(self, isConfigured: false, mode: nil)
                }
            }
            
            session.invalidate()
        }
    }
    
    private func writeUnbindConfiguration(session: NFCTagReaderSession, tag: NFCMiFareTag) {
        
        if let configuringMessage = dataSource?.smartSwitchManager(self, nfcScanningMessage: self.state) {
            
            session.alertMessage = configuringMessage
        }
        
        // Clear tag.
        let data = Data([0xA2, 0x07, 0x00, 0x00, 0x00, 0x00])
        tag.sendMiFareCommand(commandPacket: data) { receive, error in
            
            guard error == nil else {
                
                NSLog("Unbind configuration error \(error!.localizedDescription)", "")
                
                if let failedMessage = self.dataSource?.smartSwitchManager(self, nfcReadWriteFailedMessage: self.state) {
                    
                    session.invalidate(errorMessage: failedMessage)
                }
                return
            }
            
            if let message = self.dataSource?.smartSwitchManager(self, nfcReadWriteSuccessfulMessage: self.state) {
                
                session.alertMessage = message
            }
            
            DispatchQueue.main.async {
                
                self.delegate?.smartSwitchManagerDidUnbindConfigurationSuccessful(self)
            }
            
            session.invalidate()
        }
    }
    
    private func sendAuth(session: NFCTagReaderSession, tag: NFCMiFareTag, success: @escaping () -> Void) {
        
        let authData = Data([0xA2, 0xE5, 0x00, 0x00, 0xE2, 0x15])
        tag.sendMiFareCommand(commandPacket: authData) { _, error in
            
            guard error == nil else {
                
                NSLog("Write auth error \(error!.localizedDescription)", "")
                
                if let failedMessage = self.dataSource?.smartSwitchManager(self, nfcReadWriteFailedMessage: self.state) {
                    
                    session.invalidate(errorMessage: failedMessage)
                }
                return
            }
            
            success()
        }
    }
    
}

extension SmartSwitchManager {
    
    public enum State {
        
        case startConfig
        case readConfig
        case unbindConfig
    }
    
}
