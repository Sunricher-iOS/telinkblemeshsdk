//
//  File.swift
//  
//
//  Created by maginawin on 2021/3/23.
//

import Foundation

public struct MeshDeviceType {
    
    public enum Category {
        
        case light
        case remote
        case sensor
        case transmitter
        case peripheral
        case curtain
        case outlet
        case bridge
        
        case unsupported
    }
    
    public enum Capability {
        
        case onOff
        case brightness
        case colorTemperature
        case white
        case rgb
    }
    
    /// Raw value of the device type.
    public let rawValue1: UInt8
    
    /// Raw value of the sub device type.
    public let rawValue2: UInt8
    
    /// Category of the device.
    public let category: Category
    
    public private(set) var capabilities: [Capability] = []
    
    init(deviceType: UInt8, subDeviceType: UInt8) {
        
        self.rawValue1 = deviceType
        self.rawValue2 = subDeviceType
        
        switch deviceType {
        
        case 0x01:
            
            category = .light
            if let capabilities = Light(rawValue: subDeviceType)?.capabilities {
                self.capabilities = capabilities
            }            
            
        case 0x02: fallthrough
        case 0x03: fallthrough
        case 0x0A: fallthrough
        case 0x0B: fallthrough
        case 0x0C: fallthrough
        case 0x0D: fallthrough
        case 0x0E: fallthrough
        case 0x12: fallthrough
        case 0x13: fallthrough
        case 0x14:
            category = .remote
            
        case 0x04:
            category = .sensor
            
        case 0x05:
            category = .transmitter
            
        case 0x06:
            category = .peripheral
            
        case 0x07:
            category = .curtain
            
        case 0x08:
            category = .outlet
            
        case 0x09:
            category = .unsupported
            
        case 0x50:
            category = .bridge
        
        default:
            category = .unsupported
        }
    }
}

extension MeshDeviceType.Category {
    
    public var description: String {
        
        switch self {
        
        case .light:
            return "Light"
            
        case .remote:
            return "Remote"
            
        case .sensor:
            return "Sensor"
            
        case .transmitter:
            return "Transmission module"
            
        case .peripheral:
            return "Peripheral"
            
        case .curtain:
            return "Curtain"
            
        case .outlet:
            return "Outlet"
            
        case .bridge:
            return "Bridge"
            
        case .unsupported:
            return "Unsupported"
        }
    }
    
}

extension MeshDeviceType.Capability {
    
    public var description: String {
        
        switch self {
        
        case .onOff:
            return "OnOff"
            
        case .brightness:
            return "Brightness"
            
        case .colorTemperature:
            return "Color temperature"
            
        case .white:
            return "White"
            
        case .rgb:
            return "RGB"
        }
    }
    
}

extension MeshDeviceType {
    
    enum Light: UInt8 {
        
        case endpoint6Pwm = 0x08
        
        case singleDim = 0x11
        case singleOnOff = 0x12
        case singleDim2 = 0x13
        case singleOnOff2 = 0x14
        
        case onoff = 0x30
        case dim = 0x31
        case cct = 0x32
        case rgb = 0x33
        case rgbw = 0x34
        case rgbCct = 0x35
        case dtw = 0x36
        case channel6Pwm = 0x37
        case dim2 = 0x38
        case cct2 = 0x39
        
        case rfPa = 0x3A
        
        var capabilities: [Capability] {
            
            switch self {
            
            case .endpoint6Pwm: fallthrough
            case .singleOnOff: fallthrough
            case .singleOnOff2: fallthrough
            case .onoff: fallthrough
            case .dtw: fallthrough
            case .channel6Pwm:
                return [.onOff]
                
            case .singleDim: fallthrough
            case .singleDim2: fallthrough
            case .dim: fallthrough
            case .dim2:
                return [.onOff, .brightness]

            case .cct: fallthrough
            case .cct2:
                return [.onOff, .brightness, .colorTemperature]
                
            case .rgb:
                return [.onOff, .brightness, .rgb]
                
            case .rgbw:
                return [.onOff, .brightness, .white, .rgb]
                
            case .rgbCct:
                return [.onOff, .brightness, .colorTemperature, .rgb]
                
            case .rfPa:
                return []
            }
        }
    }
    
}
