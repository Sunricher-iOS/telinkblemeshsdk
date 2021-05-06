//
//  File.swift
//  
//
//  Created by maginawin on 2021/3/26.
//

import Foundation

class SampleCommandCenter {
    
    static let shared = SampleCommandCenter()
    
    private let timer: RepeatingTimer
    private var commands: [MeshCommand] = []
    
    private let serialQueue = DispatchQueue(label: "SampleCommandCenter serial")
    
    private init() {
        
        timer = RepeatingTimer(timeInterval: 0.2)
        timer.eventHandler = consumeCommand
        
    }
    
    func append(_ command: MeshCommand) {
        
        serialQueue.async {
            
            self.commands.append(command)           
            self.timer.resume()
        }
    }
    
    func removeAll() {
        
        serialQueue.async {
            
            self.commands.removeAll()
        }
    }
    
}

extension SampleCommandCenter {
    
    @objc func consumeCommand() {
        
        serialQueue.async {
            
            guard self.commands.count > 0 else {
                
                MLog("consumeCommand end")
                
                self.timer.suspend()
                return
            }
            
            var index = Int(floor(Float(self.commands.count) / 2.0))
            index = max(index - 1, 0)
            
            MLog("consumeCommand \(index)/\(self.commands.count)")
            
            self.commands.remove(at: index).send()
            self.commands = self.commands.count > 0 ? [self.commands.last!] : []
        }
    }
    
}

