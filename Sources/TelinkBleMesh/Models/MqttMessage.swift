//
//  File.swift
//  
//
//  Created by maginawin on 2021/8/25.
//

import Foundation

public struct MqttMessage {
    
    public static func meshCommand(_ command: MeshCommand, userId: String) -> String {
        
        return MqttMessage.makeMqttMessage(method: "Command", version: "1.0", userId: userId, payloadType: "COMMAND", value: command.commandData.hexString)
    }
        
    public static func scanMeshDevices(_ userId: String) -> String {
        
        return MqttMessage.makeMqttMessage(method: "Command", version: "1.0", userId: userId, payloadType: "SCAN_MESH_DEVICES", value: "")
    }
    
}

extension MqttMessage {
    
    public static func deviceEvent(_ event: MqttDeviceEventProtocol, userId: String) -> String {
        
        return MqttMessage.makeMqttMessage(method: "Event", version: "1.0", userId: userId, payloadType: event.payloadType, value: event.payloadValue)
    }
    
}

extension MqttMessage {
    
    static func makeMqttMessage(method: String, version: String, userId: String, payloadType: String, value: Any) -> String {
        
        let dict = [
            "header": [
                "method": method,
                "version": version,
                "user_id": userId
            ],
            "payload": [
                "type": payloadType,
                "value": value
            ]
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    
}
