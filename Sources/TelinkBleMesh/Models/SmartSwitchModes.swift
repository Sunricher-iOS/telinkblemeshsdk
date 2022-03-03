//
//  File.swift
//  
//
//  Created by maginawin on 2022/3/2.
//

import Foundation

public enum SmartSwitchMode: Int {
    
    case onOffDim = 0xF1
    case onOffS1S2 = 0xF2
    case onOffWwCw = 0xF3
    case onOffCwRgb = 0xF4
    case s1S2S3S4 = 0xF5
    case onOffG2 = 0xF6
    
    public static let `default` = SmartSwitchMode.onOffCwRgb
    
    public static let all: [SmartSwitchMode] = [
        .onOffDim, .onOffS1S2, .onOffWwCw, .onOffCwRgb, .s1S2S3S4, .onOffG2
    ]
    
    public var title: String {
        switch self {
        case .onOffDim: return "On/Off & DIM"
        case .onOffS1S2: return "On/Off & S1/S2"
        case .onOffWwCw: return "On/Off & WW/CW"
        case .onOffCwRgb: return "On/Off & CW/RGB"
        case .s1S2S3S4: return "S1/S2/S3/S4"
        case .onOffG2: return "On/Off & On/Off"
        }
    }
}
