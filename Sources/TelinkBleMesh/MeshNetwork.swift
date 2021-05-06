//
//  File.swift
//  
//
//  Created by maginawin on 2021/1/13.
//

import Foundation

public struct MeshNetwork {
    
    public var name: String
    
    public var password: String
    
    /**
     - Parameters:
        - name: At most 16 ASCII characters.
        - password: At most 16 ASCII characters.
     */
    public init?(name: String, password: String) {
        
        guard name.count > 0, name.count <= 16,
              password.count > 0, password.count <= 16 else {
            return nil 
        }
        
        self.name = name
        self.password = password
    }
    
}

extension MeshNetwork {
    
    /// The default network.
    public static let factory = MeshNetwork(name: "Srm@7478@a", password: "475869")!
    
}

extension MeshNetwork: Equatable { }

public func == (lhs: MeshNetwork, rhs: MeshNetwork) -> Bool {
    
    return lhs.name == rhs.name && lhs.password == rhs.password
}
