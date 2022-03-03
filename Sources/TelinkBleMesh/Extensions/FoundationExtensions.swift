//
//  File.swift
//  
//
//  Created by maginawin on 2022/2/25.
//

import Foundation

extension Int {
    
    public var hex: String {
        
        return String(self, radix: 16, uppercase: true)
    }
    
}

extension Data {
    
    public var hex: String {
        
        return self.reduce("", { $0 + String(format: "%02X ", $1) })
    }
    
}
