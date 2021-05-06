//
//  TelinkBleMeshExtensions.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/1/14.
//

import Foundation
import TelinkBleMesh


extension MeshNode {
    
    var title: String {
        
        let shortAddress = String(format: "%02X", self.shortAddress)
        let productIdString = String(format: "%04X", productId)
        return "\(name) [0x\(shortAddress)] [0x\(productIdString)]"
    }
    
    var detail: String {
        
        return "\(macAddress)"
    }
    
}

extension MeshDeviceType.Capability {
    
    var title: String {
        
        switch self {
        
        case .onOff:
            return "OnOff"
            
        case .brightness:
            return "Brightness"
            
        case .colorTemperature:
            return "Color temperature"
            
        case .rgb:
            return "RGB"
            
        case .white:
            return "White"
        }
    }
    
}
