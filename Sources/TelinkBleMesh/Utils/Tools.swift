//
//  File.swift
//  
//
//  Created by maginawin on 2021/1/13.
//

import Foundation

func MLog(_ format: String) {
    
    guard MeshManager.shared.isDebugEnabled else {
        return
    }
    
    let tag = "[TelinkBleMesh] \(format)"
    NSLog(tag, "")
}

/// If `error != nil`, return `true` and `MLog(error.localizedDescription)`.
func MErrorNotNil(_ error: Error?) -> Bool {
    
    if let error = error {
        MLog("error \(error.localizedDescription)")
        return true
    }
    return false
}

extension Data {
    
    var hexString: String {
        
        return count == 0 ? "" : self.reduce("") { $0 + String(format: "%02X", $1) }
    }
    
    func intValue(_ length: Int) -> Int {
        
        let data = Data(self)
        let count = data.count
        
        guard count > 0, length > 0 else { return 0 }
        let items = Swift.min(count, length)
        
        var value = 0
        for i in 0..<items {
        
            value |= Int(data[count - i - 1]) << (i * 8)
        }
        return value
    }
    
    var uint16Value: UInt16 {
        
        return UInt16(intValue(2))
    }
    
    var uint32Value: UInt32 {
        
        return UInt32(intValue(4))
    }
    
}
