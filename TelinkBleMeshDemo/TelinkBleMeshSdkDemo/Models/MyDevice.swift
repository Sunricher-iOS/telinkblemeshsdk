//
//  MyDevice.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/3/23.
//

import Foundation
import TelinkBleMesh

protocol MyDeviceDelegate: NSObjectProtocol {
    
    func deviceDidUpdateState(_ device: MyDevice)
    
}

class MyDevice {
    
    var meshDevice: MeshDevice
    
    var macData: Data?
    
    var deviceType: MeshDeviceType?
    
    init(meshDevice: MeshDevice) {
        
        self.meshDevice = meshDevice
    }
    
    var title: String {
        
        return meshDevice.description
    }
    
    var detail: String {
        
        if !isValid {
            
            return "Invalid"
        }
        
        let mac = macData!.reduce("", { $0 + String(format: "%02X", $1) })
        let deviceTypeRawValueString = String(format: "0x%02X%02X", deviceType!.rawValue1, deviceType!.rawValue2)
        return mac + ", \(deviceType!.category.description) [\(deviceTypeRawValueString)]"
    }
    
    var isValid: Bool {
        
        return macData != nil && deviceType != nil
    }
}

extension MyDevice: Equatable { }

func == (lhs: MyDevice, rhs: MyDevice) -> Bool {
    
    return lhs.meshDevice.address == rhs.meshDevice.address
}
