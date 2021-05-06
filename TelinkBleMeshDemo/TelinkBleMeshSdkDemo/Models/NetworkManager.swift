//
//  NetworkManager.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/1/14.
//

import Foundation
import TelinkBleMesh

class NetworkManager {
    
    static let shared = NetworkManager()
    
    var networks: [MeshNetwork]!
    
    private init() {

        networks = getNetworks()
    }
    
    func addNetwork(_ network: MeshNetwork) -> [MeshNetwork] {
        
        if networks.count >= 100 { return networks }
        
        guard !networks.contains(where: { $0.name == network.name }) else { return networks }
        
        networks.append(network)
        saveNetworks()
        return networks
    }
    
    func removeNetwork(_ network: MeshNetwork) -> [MeshNetwork] {
        
        networks.removeAll(where: { $0.name == network.name })
        saveNetworks()
        return networks
    }
    
    private func getNetworks() -> [MeshNetwork] {
        
        let data: [[String: String]] = UserDefaults.standard.array(forKey: "telink_ble_mesh_networks") as? [[String: String]] ?? []
        let networks = data.reduce([]) { (result, element) -> [MeshNetwork] in
            guard let network = MeshNetwork(element: element) else { return result }
            return result + [network]
        }
        return networks
    }
    
    private func saveNetworks() {
        
        let data = networks.reduce([], { $0 + [$1.element] })
        UserDefaults.standard.setValue(data, forKey: "telink_ble_mesh_networks")
        UserDefaults.standard.synchronize()
    }
    
}

extension MeshNetwork {
    
    var element: [String: String] {
        return [
            "name": name,
            "password": password
        ]
    }
    
    init?(element: [String: String]) {
        
        guard let name = element["name"], name.count > 0, name.count <= 16,
              let password = element["password"], password.count > 0, password.count <= 16 else {
            return nil
        }
        self.init(name: name, password: password)
    }
    
}
