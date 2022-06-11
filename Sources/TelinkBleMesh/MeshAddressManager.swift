//
//  File.swift
//  
//
//  Created by maginawin on 2021/4/21.
//

import Foundation

public class MeshAddressManager {
    
    public static let shared = MeshAddressManager()
    
    private let totalAddresses: Set<Int> = {
       
        var result = Set<Int>()
        for index in 1...254 {
            result.insert(index)
        }
        return result
    }()
    
    public func existAddressList(_ network: MeshNetwork) -> [Int] {
        
        return UserDefaults.standard.array(forKey: network.addressListKey) as? [Int] ?? []
    }
    
    public func availableAddressList(_ network: MeshNetwork) -> [Int] {
        
        return Array(totalAddresses.subtracting(existAddressList(network)))
    }
    
    /// returns true if address is not contained.
    public func append(_ address: Int, network: MeshNetwork) -> Bool {
        
        var saved = Set(existAddressList(network))
        let result = saved.insert(address)
        
        UserDefaults.standard.setValue(Array(saved), forKey: network.addressListKey)
        UserDefaults.standard.synchronize()
        
        return result.inserted
    }
    
    /// returns new addresses that are not contained.
    public func append(_ addresses: [Int], network: MeshNetwork) -> [Int] {
        
        var newAddresses: [Int] = []
        
        var saved = Set(existAddressList(network))
        addresses.forEach {
            
            let result = saved.insert($0)
            
            if result.inserted {
                
                newAddresses.append($0)
            }
        }
        
        UserDefaults.standard.setValue(Array(saved), forKey: network.addressListKey)
        UserDefaults.standard.synchronize()
        
        return newAddresses
    }
    
    public func remove(_ address: Int, network: MeshNetwork) {
        
        var saved = Set(existAddressList(network))
        saved.remove(address)
        
        UserDefaults.standard.setValue(Array(saved), forKey: network.addressListKey)
        UserDefaults.standard.synchronize()
    }
    
    public func removeAll(_ network: MeshNetwork) {
        
        UserDefaults.standard.setValue([Int](), forKey: network.addressListKey)
        UserDefaults.standard.synchronize()
    }
    
    public func isExists(_ address: Int, network: MeshNetwork) -> Bool {
        
        return existAddressList(network).contains(address)
    }
    
}

fileprivate extension MeshNetwork {
    
    var addressListKey: String {
        
        return "address_list_key_\(self.name)_\(self.password)"
    }
    
}
