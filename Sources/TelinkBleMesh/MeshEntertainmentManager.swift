//
//  File.swift
//  
//
//  Created by maginawin on 2022/1/15.
//

import Foundation
import UIKit

public struct MeshEntertainmentAction {
    
    /// Action target address.
    public var target: Int
    
    /// Delay seconds, range [0, 60], default is 1
    public var delay: Int
    
    public var isOn: Bool?
    
    /// Range [0, 100]
    public var brightness: Int?
    
    /// Range [0, 255]
    public var white: Int?
    
    /// Range [0, 100]
    public var colorTemperature: Int?
    
    /// Range [0x000000, 0xFFFFFF],
    /// 0xFF0000 = red,
    /// 0x00FF00 = green,
    /// 0x0000FF = blue, ...
    public var rgb: Int?
    
    public init(target: Int, delay: Int = 1) {
        self.target = target
        self.delay = delay
    }
    
}

public class MeshEntertainmentManager {
    
    public static let shared = MeshEntertainmentManager()
    
    public var index: Int = 0
    
    private let sendQueue = DispatchQueue(label: "MeshEntertainmentSend")
    
    private var isStarted = false
    private var actions: [MeshEntertainmentAction]?
    
    private init() {
        
    }
    
    public func start(_ actions: [MeshEntertainmentAction], index: Int = 0) {
        
        self.actions = actions
        self.index = index
        
        if self.isStarted {
            return
        }
        
        self.isStarted = true
        
        sendQueue.async {            
            
            while (self.isStarted) {
                
                if let actions = self.actions, actions.count > 0 {
                    
                    actions.forEach {
                        
                        if (!self.isStarted) { return }
                        
                        Thread.sleep(forTimeInterval: TimeInterval($0.delay))
                        self.sendAction($0)
                    }
                    
                } else {
                    
                    self.isStarted = false
                }
            }
        }
    }
    
    public func stop() {
        
        self.actions = nil
        self.isStarted = false
    }
    
}

extension MeshEntertainmentManager {
    
    private func sendAction(_ action: MeshEntertainmentAction) {
        
        NSLog("entertainment send action \(action)", "")
        
        if let rgb = action.rgb {
            let red = (rgb >> 16) & 0xFF
            let green = (rgb >> 8) & 0xFF
            let blue = rgb & 0xFF
            MeshCommand.setRgb(action.target, red: red, green: green, blue: blue).send()
        }
        
        if let cct = action.colorTemperature {
            MeshCommand.setColorTemperature(action.target, value: cct).send()
        }
        
        if let white = action.white {
            MeshCommand.setWhite(action.target, value: white).send()
        }
        
        if let brightness = action.brightness {
            MeshCommand.setBrightness(action.target, value: brightness).send()
        }
        
        if let isOn = action.isOn {
            MeshCommand.turnOnOff(action.target, isOn: isOn).send()
        }
    }
    
}
