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
        case rfPa
        
        // Citron 8 keys pannel, 4 buttons IO module
        case customPanel
        
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
            
        case 0x16:
            category = .customPanel
            
        case 0x04:
            category = .sensor
            
        case 0x05:
            category = .transmitter
            
        case 0x06:
            category = .peripheral
            
        case 0x07:
            category = .curtain
            capabilities = [.onOff, .brightness]
            
        case 0x08:
            category = .outlet
            
        case 0x09:
            category = .unsupported
            
        case 0x50:
            
            if rawValue2 == 0x02 {
                
                category = .rfPa
                
            } else {
                
                category = .bridge
            }
        
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
            
        case .rfPa:
            return "RF PA"
            
        case .unsupported:
            return "Unsupported"
            
        case .customPanel:
            return "Custom panel"
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
        case onoff2 = 0x60
        
        case dim = 0x31
        case dim3 = 0x61
        
        case cct = 0x32
        case cct3 = 0x62
        
        case rgb = 0x33
        case rgb2 = 0x63
        
        case rgbw = 0x34
        case rgbw2 = 0x64
        
        case rgbCct = 0x35
        case rgbCct2 = 0x65
        
        case dtw = 0x36
        case dtw2 = 0x66
        
        case channel6Pwm = 0x37
        case dim2 = 0x38
        case cct2 = 0x39
        
        case rfPa = 0x3A
        
        case microwaveMotionSensor = 0x3C
        
        var capabilities: [Capability] {
            
            switch self {
            
            case .singleOnOff: fallthrough
            case .singleOnOff2: fallthrough
            case .onoff: fallthrough
            case .onoff2:
                return [.onOff]
                
            case .singleDim: fallthrough
            case .singleDim2: fallthrough
            case .dim: fallthrough
            case .dim2: fallthrough
            case .dim3: fallthrough
            case .dtw: fallthrough
            case .dtw2:
                return [.onOff, .brightness]

            case .cct: fallthrough
            case .cct2: fallthrough
            case .cct3: fallthrough
            case .endpoint6Pwm: fallthrough
            case .channel6Pwm:
                return [.onOff, .brightness, .colorTemperature]
                
            case .rgb: fallthrough
            case .rgb2:
                return [.onOff, .brightness, .rgb]
                
            case .rgbw: fallthrough
            case .rgbw2:
                return [.onOff, .brightness, .white, .rgb]
                
            case .rgbCct: fallthrough
            case .rgbCct2:
                return [.onOff, .brightness, .colorTemperature, .rgb]
                
            case .rfPa:
                return []
                
            case .microwaveMotionSensor:
                return [.onOff, .brightness]
            }
        }
    }
    
}

extension MeshDeviceType: Equatable {}

public func == (lhs: MeshDeviceType, rhs: MeshDeviceType) -> Bool {
    
    return lhs.rawValue1 == rhs.rawValue1 && lhs.rawValue2 == rhs.rawValue2
}

extension MeshDeviceType {
    
    public var isSupportMeshAdd: Bool {
        
        switch category {
        
        case .light: fallthrough
        case .curtain: fallthrough
        case .bridge: fallthrough
        case .outlet:
            return true
            
        case .remote: fallthrough
        case .sensor: fallthrough
        case .transmitter: fallthrough
        case .peripheral: fallthrough
        case .rfPa: fallthrough
        case .unsupported: fallthrough
        case .customPanel:
            return false
        }
    }
    
    public var isSupportSingleAdd: Bool {
        
        switch category {
        
        case .light:
            return true
            
        case .curtain: fallthrough
        case .bridge: fallthrough
        case .outlet:
            return false
            
        // Unsupported
        case .transmitter: fallthrough
        case .peripheral: fallthrough
        case .unsupported:
            return false
            
        case .remote: fallthrough
        case .sensor: fallthrough
        case .rfPa: fallthrough
        case .customPanel:
            return true
        }
    }
    
    public var isSafeConntion: Bool {
        
        switch category {
        
        case .light: fallthrough
        case .curtain: fallthrough
        case .outlet:
            return true
            
        case .remote: fallthrough
        case .sensor: fallthrough
        case .transmitter: fallthrough
        case .peripheral: fallthrough
        case .rfPa: fallthrough
        case .unsupported: fallthrough
        case .customPanel: fallthrough
        case .bridge:
            return false
        }
    }
    
}
