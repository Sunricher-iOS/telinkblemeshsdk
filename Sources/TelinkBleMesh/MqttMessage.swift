//
//  File.swift
//  
//
//  Created by maginawin on 2021/8/25.
//

import Foundation

public struct MqttMessage {
    
    public static func meshCommand(_ command: MeshCommand, userId: String) -> String {
        
        return MqttCommand.mqttMessage(method: .command, version: .v1_0, userId: userId, payloadType: .command, value: command.commandData.hexString)
    }
        
    public static func scanMeshDevices(_ userId: String) -> String {
        
        return MqttCommand.mqttMessage(method: .command, version: .v1_0, userId: userId, payloadType: .scanMeshDevices, value: "")
    }
    
}
