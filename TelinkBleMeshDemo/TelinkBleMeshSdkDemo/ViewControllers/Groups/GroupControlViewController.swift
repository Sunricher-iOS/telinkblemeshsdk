//
//  GroupControlViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/2/25.
//

import UIKit
import TelinkBleMesh

class GroupControlViewController: UITableViewController {
    
    var groupId: Int!
    
    private let capabilities: [MeshDeviceType.Capability] = [
        .onOff, .brightness, .white, .colorTemperature, .rgb
    ]
    private let colorSliderTypes: [ColorSliderType] = [.red, .green, .blue, .hue]
    private var extendValue = LightExtendValue()
    
    private var isBrightnessChanging = false
    private var chaningTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Group \(groupId.hex)"        
        
        let settingsItem = UIBarButtonItem(title: "settings".localization, style: .plain, target: self, action: #selector(self.settingsAction(_:)))
        navigationItem.rightBarButtonItem = settingsItem
    }
    
    @objc func settingsAction(_ sender: Any) {
        
        let controller = GroupSettingsViewController(style: .grouped)
        controller.groupId = groupId
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return capabilities.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if capabilities[section] == .rgb {
            
            return colorSliderTypes.count
        }
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 52
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return capabilities[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let capability = capabilities[indexPath.section]
        
        switch capability {
        
        case .onOff:
            return dequeueOnOffCell()
            
        case .brightness:
            return dequeueSliderCell("brightness", minValue: 0, maxValue: 100, value: 100, text: "100")
            
        case .colorTemperature:
            return dequeueSliderCell("colorTemperature", minValue: 0, maxValue: 100, value: 0, text: "0")
            
        case .white:
            return dequeueSliderCell("white", minValue: 0, maxValue: 255, value: 0, text: "0")
            
        case .rgb:
            return dequeueColorCell(type: colorSliderTypes[indexPath.row])
        }
    }
    

}

extension GroupControlViewController {
    
    private func dequeueOnOffCell() -> SwitchTableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "onOff") as? SwitchTableViewCell ??
            SwitchTableViewCell(style: .default, reuseIdentifier: "onOff")
        
        cell.rightSwitch.isOn = true
        cell.textLabel?.text = "OnOff"
        cell.delegate = self
        
        return cell
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
    
    private func dequeueColorCell(type: ColorSliderType) -> SliderTableViewCell {
        
        switch type {
        
        case .red:
            
            let cell = dequeueSliderCell("red", minValue: 0, maxValue: 255, value: extendValue.red, text: "\(Int(extendValue.red))")
            cell.slider.minimumTrackTintColor = .systemRed
            return cell
            
        case .green:
            
            let cell = dequeueSliderCell("green", minValue: 0, maxValue: 255, value: extendValue.green, text: "\(Int(extendValue.green))")
            cell.slider.minimumTrackTintColor = .systemGreen
            return cell
            
        case .blue:
            
            let cell = dequeueSliderCell("blue", minValue: 0, maxValue: 255, value: extendValue.blue, text: "\(Int(extendValue.blue))")
            cell.slider.minimumTrackTintColor = .blue
            return cell
            
        case .hue:
            return dequeueSliderCell("hue", minValue: 0, maxValue: 360, value: extendValue.hue, text: "\(Int(extendValue.hue))")
        }
    }
    
}

extension GroupControlViewController: SwitchTableViewCellDelegate {
    
    func switchCell(_ cell: SwitchTableViewCell, switchValueChanged isOn: Bool) {
        
        cell.textLabel?.text = isOn ? MeshDevice.State.on.title : MeshDevice.State.off.title
        
//        MeshCommand.turnOnOff(Int(device.meshDevice.address), isOn: isOn).send()
        let command = MeshCommand.turnOnOff(groupId, isOn: isOn)
        let mqttMessage = MqttMessage.meshCommand(command, userId: "maginawin")
        MeshManager.shared.sendMqttMessage(mqttMessage)
    }
    
}

extension GroupControlViewController: SliderTableViewCellDelegate {
    
    func sliderCell(_ cell: SliderTableViewCell, sliderValueChanging value: Float) {
        
        chaningTimer?.invalidate()
        chaningTimer = nil
        isBrightnessChanging = true
        
        handleSliderValueChange(cell, value: value)
    }
    
    func sliderCell(_ cell: SliderTableViewCell, sliderValueChanged value: Float) {
        
        chaningTimer?.invalidate()
        chaningTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] (timer) in
            
            self?.isBrightnessChanging = false
        })
        
        handleSliderValueChange(cell, value: value)
    }
    
    private func handleSliderValueChange(_ cell: SliderTableViewCell, value: Float) {
        
        let intValue = Int(round(value))
        cell.valueLabel.text = "\(intValue)"
        
        let address = groupId!
        
        switch cell.reuseIdentifier {
        
        case "brightness":
            
            MeshCommand.setBrightness(address, value: intValue).send(isSample: true)
            
        case "colorTemperature":
            
            extendValue.colorTemperature = value
            MeshCommand.setColorTemperature(address, value: intValue).send(isSample: true)
            
        case "white":
            
            extendValue.white = value
            MeshCommand.setWhite(address, value: intValue).send(isSample: true)
            
        case "red":
            
            extendValue.red = value
            MeshCommand.setRed(address, value: intValue).send(isSample: true)
            
        case "green":
            
            extendValue.green = value
            MeshCommand.setGreen(address, value: intValue).send(isSample: true)
            
        case "blue":
            
            extendValue.blue = value
            MeshCommand.setBlue(address, value: intValue).send(isSample: true)
            
        case "hue":
            
            extendValue.hue = value
            let hue = CGFloat(intValue) / 360.0
            let color = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: nil)
            MeshCommand.setRgb(address, red: Int(red * 255), green: Int(green * 255), blue: Int(blue * 255)).send(isSample: true)
        
        default:
            break
        }
    }
    
}

extension GroupControlViewController {
    
    private enum ColorSliderType {
        
        case red
        case green
        case blue
        case hue
    }
    
    private struct LightExtendValue {
        
        var white: Float = 0
        var colorTemperature: Float = 0
        var red: Float = 0
        var green: Float = 0
        var blue: Float = 0
        var hue: Float = 0
    }
    
}
