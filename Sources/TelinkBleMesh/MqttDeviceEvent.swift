//
//  File.swift
//  
//
//  Created by maginawin on 2021/8/25.
//

import Foundation

public enum MqttDeviceEventType {
    
    case state
    
    case deviceType
    
    case dateTime
    
    case lightOnOffDuration
    
    case firmwareVersion
}

public protocol MqttDeviceEventProtocol {
    
    var eventType: MqttDeviceEventType { get }
    
    var payloadValue: Any { get }
    
    var payloadType: String { get }
}

extension MqttDeviceEventProtocol {
    
    public var payloadType: String {
     
        switch eventType {
        
        case .state:
            return "STATE"
            
        case .deviceType:
            return "DEVICE_TYPE"
            
        case .dateTime:
            return "DATE_TIME"
            
        case .lightOnOffDuration:
            return "LIGHT_ON_OFF_DURATION"
            
        case .firmwareVersion:
            return "FIRMWARE_VERSION"
        }
    }
    
}

public struct MqttDeviceStateEvent: MqttDeviceEventProtocol {
    
    public let eventType: MqttDeviceEventType = .state
    
    public internal(set) var meshDevices: [MeshDevice]
    
    public var payloadValue: Any {
        
        return meshDevices.map { $0.itemValue }
    }
    
}

fileprivate extension MeshDevice {
    
    var itemValue: [String: Any] {
        
        return [
            "short_address": address,
            "state": state.stateString,
            "brightness": brightness
        ]
    }
    
}

fileprivate extension MeshDevice.State {
    
    var stateString: String {
        
        switch self {
        
        case .on:
            return "ON"
            
        case .off:
            return "OFF"
            
        case .offline:
            return "OFFLINE"
        }
    }
    
}

public struct MqttDeviceTypeEvent: MqttDeviceEventProtocol {
    
    public let eventType: MqttDeviceEventType = .deviceType
    
    public internal(set) var shortAddress: Int
    
    public internal(set) var deviceType: MeshDeviceType
    
    public internal(set) var macData: Data
    
    
    public var payloadValue: Any {
        
        return [
            "short_address": shortAddress,
            "main_type": Int(deviceType.rawValue1),
            "sub_type": Int(deviceType.rawValue2),
            "mac_data": macData.hexString
        ]
    }
}

public struct MqttDeviceDateEvent: MqttDeviceEventProtocol {
    
    public let eventType: MqttDeviceEventType = .dateTime
    
    public internal(set) var shortAddress: Int
    
    public internal(set) var date: Date
    
    public var payloadValue: Any {
        
        let dft = DateFormatter()
        dft.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return [
            "short_address": shortAddress,
            "date": dft.string(from: date)
        ]
    }
}

public struct MqttDeviceLightOnOffDurationEvent: MqttDeviceEventProtocol {
    
    public let eventType: MqttDeviceEventType = .lightOnOffDuration
    
    public internal(set) var shortAddress: Int
    
    public internal(set) var duration: Int
    
    public var payloadValue: Any {
        
        return [
            "short_address": shortAddress,
            "duration": duration
        ]
    }
}

public struct MqttDeviceFirmwareEvent: MqttDeviceEventProtocol {
    
    public let eventType: MqttDeviceEventType = .firmwareVersion
    
    public internal(set) var shortAddress: Int
    
    public internal(set) var firmwareVersion: String
    
    public var payloadValue: Any {
        
        return [
            "short_address": shortAddress,
            "firmware_version": firmwareVersion
        ]
    }
}
