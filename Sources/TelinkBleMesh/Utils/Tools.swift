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

extension String {
    
    var hexData: Data {
        
        var temp = self
        if temp.count % 2 != 0 {
            temp = "0" + temp
        }
        
        let value = NSString(string: temp)
        let size = value.length / 2
        if size == 0 { return Data() }
        
        var result = Data()
        for i in 0..<size {
            
            let item = value.substring(with: NSRange(location: i * 2, length: 2))
            let itemInt = UInt8(item, radix: 16) ?? 0
            
            result.append(itemInt)
        }
        
        return result
    }
}

// MARK: - Utils

extension Float {
    
    var bytes: [UInt8] {
        
        return withUnsafeBytes(of: self, Array.init)
    }
    
    var data: Data {
        
        return Data(bytes)
    }
    
}

extension Data {
    
    var floatValue: Float {
        
        self.withUnsafeBytes {
            
            $0.load(fromByteOffset: 0, as: Float.self)
        }
    }
}
