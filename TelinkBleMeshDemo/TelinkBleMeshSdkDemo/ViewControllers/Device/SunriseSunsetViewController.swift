//
//  SunriseSunsetViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/11/11.
//

import UIKit
import TelinkBleMesh

class SunriseSunsetViewController: UITableViewController {
    
    var address: Int!
    
    private let cellTypes: [CellType] = [
        .onOff, .sceneId, .brightness, .red, .green, .blue, .ctOrW,
        .sunriseSunset, .enableState, .get, .setOnOff, .setScene, .setCustom,
        .clear, .enable, .disable
    ]
    
    private var type: SunriseSunsetType = .sunrise
    private var isEnabled = true
    
    private var onOffAction = SunriseSunsetOnOffAction(type: .sunrise)
    private var sceneAction = SunriseSunsetSceneAction(type: .sunrise)
    private var customAction = SunriseSunsetCustomAction(type: .sunrise)

    override func viewDidLoad() {
        super.viewDidLoad()
     
        title = "sunrise_sunset".localization
        
        MeshManager.shared.deviceDelegate = self
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellType = cellTypes[indexPath.row]
        switch cellType {
            
        case .onOff:
            
            onOffAction.isOn = !onOffAction.isOn
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
        case .sceneId: fallthrough
        case .brightness: fallthrough
        case .red: fallthrough
        case .green: fallthrough
        case .blue: fallthrough
        case .ctOrW:
            showTextFiled(cellType, indexPath: indexPath)
            
        case .sunriseSunset:
            
            type = (type == .sunrise) ? .sunset : .sunrise
            onOffAction.type = type
            sceneAction.type = type
            customAction.type = type
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
        case .enableState:
            
            isEnabled = !isEnabled
            onOffAction.isEnabled = isEnabled
            sceneAction.isEnabled = isEnabled
            customAction.isEnabled = isEnabled
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
        case .get:
            MeshCommand.getSunriseSunset(address, type: type).send()
            
        case .setOnOff:
            onOffAction.duration = 0x7FF
            MeshCommand.setSunriseSunsetAction(address, action: onOffAction).send()
            
        case .setScene:
            MeshCommand.setSunriseSunsetAction(address, action: sceneAction).send()
            
        case .setCustom:
            MeshCommand.setSunriseSunsetAction(address, action: customAction).send()
            
        case .clear:
            MeshCommand.clearSunriseSunsetContent(address, type: type).send()
            
        case .enable:
            MeshCommand.enableSunriseSunset(address, type: type, isEnabled: true).send()
            
        case .disable:
            MeshCommand.enableSunriseSunset(address, type: type, isEnabled: false).send()
        }
        
        
    }
    
    private func showTextFiled(_ cellType: CellType, indexPath: IndexPath) {
        
        let alert = UIAlertController(title: "input_value".localization, message: nil, preferredStyle: .alert)
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alert.popoverPresentationController?.sourceView = view
        
        var textField: UITextField?
        alert.addTextField { tf in
            
            textField = tf
            tf.keyboardType = .numberPad
            tf.autocorrectionType = .no
        }
        
        let doneAction = UIAlertAction(title: "done".localization, style: .default) { _ in
            
            guard let text = textField?.text, let value = Int(text) else { return }
            
            switch cellType {
                
            case .sceneId:
                
                guard value >= 1 && value <= 16 else { return }
                self.sceneAction.sceneID = value
                
            case .brightness:
                
                guard value >= 0 && value <= 100 else { return }
                self.customAction.brightness = value
                
            case .red:
                
                guard value >= 0 && value <= 255 else { return }
                self.customAction.red = value
                
            case .green:
                
                guard value >= 0 && value <= 255 else { return }
                self.customAction.green = value
                
            case .blue:
                
                guard value >= 0 && value <= 255 else { return }
                self.customAction.blue = value
                
            case .ctOrW:
                
                guard value >= 0 && value <= 255 else { return }
                self.customAction.ctOrW = value
                
            default:
                break
            }
            
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        alert.addAction(doneAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cellTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellType = cellTypes[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.textLabel?.text = cellType.title
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .disclosureIndicator
        
        switch cellType {
            
        case .onOff:
            cell.detailTextLabel?.text = onOffAction.isOn ? "On" : "Off"
            
        case .sceneId:
            cell.detailTextLabel?.text = "\(sceneAction.sceneID)"
            
        case .brightness:
            cell.detailTextLabel?.text = "\(customAction.brightness)"
            
        case .red:
            cell.detailTextLabel?.text = "\(customAction.red)"
            
        case .green:
            cell.detailTextLabel?.text = "\(customAction.green)"
            
        case .blue:
            cell.detailTextLabel?.text = "\(customAction.blue)"
            
        case .ctOrW:
            cell.detailTextLabel?.text = "\(customAction.ctOrW)"
            
        case .sunriseSunset:
            cell.detailTextLabel?.text = type == .sunrise ? "Sunrise" : "Sunset"
            
        case .enableState:
            cell.detailTextLabel?.text = isEnabled ? "Enabled" : "Disabled"
            
        case .get: fallthrough
        case .setOnOff: fallthrough
        case .setScene: fallthrough
        case .setCustom: fallthrough
        case .clear: fallthrough
        case .enable: fallthrough
        case .disable:
            cell.detailTextLabel?.text = nil
        }
        
        return cell 
    }

}

fileprivate enum CellType {
    
    case onOff
    case sceneId
    case brightness
    case red
    case green
    case blue
    case ctOrW
    
    case sunriseSunset
    case enableState
    case get
    case setOnOff
    case setScene
    case setCustom
    case clear
    case enable
    case disable
    
    var title: String {
        
        switch self {
            
        case .onOff: return "OnOff"
        case .sceneId: return "Scene ID"
        case .brightness: return "Brightness"
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .ctOrW: return "CT or White"
        case .sunriseSunset: return "SunriseSunset"
        case .enableState: return "Enable State"
        case .get: return "Get"
        case .setOnOff: return "Set OnOff"
        case .setScene: return "Set Scene"
        case .setCustom: return "Set Custom"
        case .clear: return "Clear"
        case .enable: return "Enable"
        case .disable: return "Disable"
        }
    }
}

extension SunriseSunsetViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetSunriseSunsetAction action: SunriseSunsetAction) {
        
        type = action.type
        isEnabled = action.isEnabled
        
        switch action.actionType {
            
        case .onOff:
            onOffAction = action as! SunriseSunsetOnOffAction
            
        case .scene:
            sceneAction = action as! SunriseSunsetSceneAction
            
        case .custom:
            customAction = action as! SunriseSunsetCustomAction
        }
        
        tableView.reloadData()
    }
    
}
