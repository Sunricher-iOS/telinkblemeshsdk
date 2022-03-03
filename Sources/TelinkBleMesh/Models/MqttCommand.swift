//
//  File.swift
//  
//
//  Created by maginawin on 2021/8/25.
//

import Foundation

struct MqttCommand {
    
    private(set) var data = Data()
    private(set) var commandType = PayloadType.command
    
    private init() {
        
    }
    
    static func makeCommandWithMqttMessage(_ jsonMessage: String) -> MqttCommand? {
        
        guard let jsonData = jsonMessage.data(using: .utf8) else { return nil }
        
        guard let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any] else {
            
            return nil
        }
        
        guard let header = dict["header"] as? [String: Any] else { return nil }
        guard let payload = dict["payload"] as? [String: Any] else { return nil }
        
        guard let methodString = header["method"] as? String else { return nil }
        guard let version = header["version"] as? String else { return nil }
        // guard let userId = header["user_id"] as? String else { return nil }
        
        guard let typeString = payload["type"] as? String else { return nil }
        
        guard let _ = Version(rawValue: version) else { return nil }
        
        guard let method = Method(rawValue: methodString) else { return nil }
        
        var mqttCommand = MqttCommand()
        
        switch method {
        
        case .command:
            
            guard let type = PayloadType(rawValue: typeString) else { return nil }
                
            switch type {
            
            case .command:
                
                guard let value = payload["value"] else { return nil }
                guard let valueString = value as? String else { return nil }
                mqttCommand.commandType = .command
                mqttCommand.data = valueString.hexData
                
            case .scanMeshDevices:
                mqttCommand.commandType = .scanMeshDevices
            }
        }
        
        return mqttCommand
    }
    
}

extension MqttCommand {
    
    fileprivate struct Header {
        
        private(set) var method: String
        private(set) var version: String
        private(set) var userId: String
    }



    fileprivate struct Payload {
        
        private(set) var type: String
        private(set) var value: String
        
    }

    enum Method: String {
        
        case command = "Command"
    }
    
    enum Version: String {
        
        case v1_0 = "1.0"
    }

    enum PayloadType: String {
        
        case command = "COMMAND"
        
        case scanMeshDevices = "SCAN_MESH_DEVICES"
    }
    
}
