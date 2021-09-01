//
//  LightRunningViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/8/30.
//

import UIKit
import TelinkBleMesh
import Toast

class LightRunningViewController: UITableViewController {
    
    weak var device: MyDevice!
    
    private let sections: [[RowType]] = [
        [.startDefault, .selectDefaultMode],
        [.startCustom, .selectCustomMode, .selectCustomColors],
        [.speed],
        [.brightness]
    ]
    
    private var runningMode: MeshCommand.LightRunningMode!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "light_running".localization
        
        let stopItem = UIBarButtonItem(title: "Stop", style: .plain, target: self, action: #selector(self.stopAction))
        navigationItem.rightBarButtonItem = stopItem
        
        runningMode = MeshCommand.LightRunningMode(address: Int(device.meshDevice.address), state: .stopped)
        
        view.makeToastActivity(.center)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
            
            self?.view.hideToastActivity()
        }
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getLightRunningMode(runningMode.address).send()
    }
    
    @objc private func stopAction() {
        
        runningMode.state = .stopped
        MeshCommand.updateLightRunningMode(runningMode).send()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let rowType = sections[indexPath.section][indexPath.row]
        switch rowType {
        
        case .startDefault:
            startDefaultAction()
            
        case .selectDefaultMode:
            selectDefaultModeAction()
            
        case .startCustom:
            startCustomAction()
            
        case .selectCustomMode:
            selectCustomModeAction()
            
        case .selectCustomColors:
            selectCustomColorsAction()
            
        default:
            break
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return sections[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let first = sections[section].first
        
        switch first {
        
        case .speed:
            return "Speed"
            
        case .brightness:
            return "Brightness"
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let rowType = sections[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = rowType.title
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .disclosureIndicator
        
        switch rowType {
            
        case .selectDefaultMode:
            cell.detailTextLabel?.text = runningMode.defaultMode.title
            
        case .selectCustomMode:
            cell.detailTextLabel?.text = runningMode.customMode.title
            
        case .selectCustomColors:
            cell.detailTextLabel?.text = "\(runningMode.customModeId)"
            
        case .speed:
            return deqeueuSpeedCell()
            
        case .brightness:
            return deqeueuBrightnessCell()
        
        default:
            break
        }
        
        return cell
    }

}

extension LightRunningViewController {
    
    private enum RowType {
        
        case startDefault
        case selectDefaultMode
        
        case startCustom
        case selectCustomMode
        case selectCustomColors
        
        case speed
        case brightness
        
        var title: String {
            
            switch self {
            
            case .startDefault:
                return "start_default".localization
                
            case .selectDefaultMode:
                return "default_mode".localization
                
            case .startCustom:
                return "start_custom".localization
                
            case .selectCustomMode:
                return "custom_mode".localization
                
            case .selectCustomColors:
                return "custom_colors".localization
                
            case .speed:
                return "speed".localization
                
            case .brightness:
                return "brightness".localization
            }
        }
    }
    
    private func startDefaultAction() {
        
        runningMode.state = .defaultMode
        MeshCommand.updateLightRunningMode(runningMode).send()
    }
    
    private func selectDefaultModeAction() {
        
        let controller = LightRunningSelectModeViewController(style: .grouped)
        controller.selectedIndex = MeshCommand.LightRunningMode.DefaultMode.all.firstIndex(where: { $0 == self.runningMode.defaultMode }) ?? 0
        controller.isDefaultMode = true
        controller.modes = MeshCommand.LightRunningMode.DefaultMode.all
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func startCustomAction() {
        
        runningMode.state = .customMode
        MeshCommand.updateLightRunningMode(runningMode).send()
    }
    
    private func selectCustomModeAction() {
        
        let controller = LightRunningSelectModeViewController(style: .grouped)
        controller.selectedIndex = MeshCommand.LightRunningMode.CustomMode.all.firstIndex(where: { $0 == self.runningMode.customMode }) ?? 0
        controller.isDefaultMode = false
        controller.modes = MeshCommand.LightRunningMode.CustomMode.all
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func selectCustomColorsAction() {
        
        let controller = LightRunningColorsViewController(style: .grouped)
        controller.address = Int(device.meshDevice.address)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension LightRunningViewController {
    
    private func deqeueuSpeedCell() -> SliderTableViewCell {
        
        return dequeueSliderCell("speed", minValue: 0.0, maxValue: 15.0, value: Float(runningMode.speed), text: "\(runningMode.speed)")
    }
    
    private func deqeueuBrightnessCell() -> SliderTableViewCell {
        
        return dequeueSliderCell("brightness", minValue: 0.0, maxValue: 100.0, value: 100.0, text: "100")
    }
    
    private func dequeueSliderCell(_ identifier: String, minValue: Float, maxValue: Float, value: Float, text: String?) -> SliderTableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? SliderTableViewCell ??
            SliderTableViewCell(style: .default, reuseIdentifier: identifier)
        
        cell.slider.minimumValue = minValue
        cell.slider.maximumValue = maxValue
        cell.slider.value = value
        cell.valueLabel.text = text
        cell.delegate = self
        
        return cell
    }
    
}

protocol LightRunningModeTitle {
    
    var title: String { get }
}

extension MeshCommand.LightRunningMode.DefaultMode: LightRunningModeTitle {
    
    var title: String {
        
        switch self {
        
        case .colorfulMixed: return "Colorful mixed"
        case .redShade: return "Red shade"
        case .greenShade: return "Green shade"
        case .blueShade: return "Blue shade"
        case .yellowShade: return "Yellow shade"
        case .cyanShade: return "Cyan shade"
        case .purpleShade: return "Purple shade"
        case .whiteShade: return "White shade"
        case .redGreenShade: return "Red green shade"
        case .redBlueShade: return "Red blue shade"
        case .greenBlueShade: return "Green blue shade"
        case .colorfulStrobe: return "Colorful strobe"
        case .redStrobe: return "Red strobe"
        case .greenStrobe: return "Green strobe"
        case .blueStrobe: return "Blue strobe"
        case .yellowStrobe: return "Yellow strobe"
        case .cyanStrobe: return "Cyan strobe"
        case .purpleStrobe: return "Purple strobe"
        case .whiteStrobe: return "White strobe"
        case .colorfulJump: return "Coloful jump"
        }
    }
    
}

extension MeshCommand.LightRunningMode.CustomMode: LightRunningModeTitle {
    
    var title: String {
        
        switch self {
        
        case .ascendShade: return "Ascend shade"
        case .descendShade: return "Descend shade"
        case .ascendDescendShade: return "Ascend descend shade"
        case .mixedShade: return "Mixed shade"
        case .jump: return "Jump"
        case .strobe: return "Strobe"
        }
    }
    
}

extension LightRunningViewController: LightRunningSelectModeViewControllerDelegate {
    
    func lightRunningSelectModeViewController(_ controller: LightRunningSelectModeViewController, didSelectIndex index: Int, isDefaultMode: Bool) {
        
        if isDefaultMode {
            
            runningMode.state = .defaultMode
            runningMode.defaultMode = MeshCommand.LightRunningMode.DefaultMode.all[index]
            startDefaultAction()
            
        } else {
            
            runningMode.state = .customMode
            runningMode.customMode = MeshCommand.LightRunningMode.CustomMode.all[index]
            startCustomAction()
        }
        
        tableView.reloadData()
    }
    
}

extension LightRunningViewController: SliderTableViewCellDelegate {
    
    func sliderCell(_ cell: SliderTableViewCell, sliderValueChanged value: Float) {
     
        cell.valueLabel.text = "\(Int(value))"
        
        switch cell.reuseIdentifier {
        
        case "brightness":
            MeshCommand.setBrightness(runningMode.address, value: Int(value)).send()
            
        case "speed":
            
            runningMode.speed = Int(value)
            MeshCommand.updateLightRunningSpeed(runningMode.address, speed: runningMode.speed).send()
            
        default:
            break
        }
    }
    
    func sliderCell(_ cell: SliderTableViewCell, sliderValueChanging value: Float) {
        
        cell.valueLabel.text = "\(Int(value))"
    }
    
}

extension LightRunningViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetLightRunningMode mode: MeshCommand.LightRunningMode) {
        
        guard runningMode.address == address else { return }
        
        view.hideToastActivity()
        runningMode = mode
        tableView.reloadData()
    }
    
}

extension LightRunningViewController: LightRunningColorsViewControllerDelegate {
    
    func lightRunningColorsViewController(_ controller: LightRunningColorsViewController, didSelectModeId modeId: Int) {
    
        runningMode.customModeId = modeId
        tableView.reloadData()
        
        startCustomAction()
    }
    
}
