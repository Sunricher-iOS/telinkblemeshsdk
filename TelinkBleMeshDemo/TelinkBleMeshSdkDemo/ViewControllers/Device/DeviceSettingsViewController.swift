//
//  DeviceSettingsViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/4/30.
//

import UIKit
import TelinkBleMesh
import Toast

class DeviceSettingsViewController: UITableViewController {
    
    weak var device: MyDevice!
    var network: MeshNetwork!
    
    private var options: [SettingsOption] = [
        .changeAddress, .resetNetwork, .syncDatetime, .getDatetime,
        .setLightOnOffDuration, .getLightOnOffDuration, .ota, .lightRunning,
        .lightSwitchType, .lightPwmFrequency, .enablePairing, .enableRgbIndependence,
        .timezone, .location, .sunriseSunset
    ]
    
    /// (short address, mac data)
    private var newAddress: (Int, Data)?
    private var changeAddressTimer: Timer?
    private let changeAddressTimeInterval: TimeInterval = 4

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings".localization
        
        MeshManager.shared.deviceDelegate = self
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let option = options[indexPath.row]
        switch option {
        
        case .changeAddress:
            changeAddressAction()
            
        case .resetNetwork:
            resetNetworkAction()
            
        case .syncDatetime:
            syncDatetimeAction()
            
        case .getDatetime:
            getDatetimeAction()
            
        case .setLightOnOffDuration:
            setLightOnOffDurationAction()
            
        case .getLightOnOffDuration:
            getLightOnOffDurationAction()
            
        case .ota:
            
            MeshManager.shared.deviceDelegate = self
            MeshCommand.getFirmwareVersion(Int(device.meshDevice.address)).send()
            
        case .lightRunning:
            
            let controller = LightRunningViewController(style: .grouped)
            controller.device = device
            navigationController?.pushViewController(controller, animated: true)
            
        case .lightSwitchType:
            lightSwitchTypeAction()
            
        case .lightPwmFrequency:
            lightPwmFrequencyAction()
            
        case .enablePairing:
            enablePairingAction()
            
        case .enableRgbIndependence:
            enableRgbIndependenceAction()
            
        case .timezone:
            timezoneAction()
            
        case .location:
            locationAction()
            
        case .sunriseSunset:
            
            let controller = SunriseSunsetViewController(style: .grouped)
            controller.address = Int(device.meshDevice.address)
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let option = options[indexPath.row]
        cell.textLabel?.text = option.title
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

extension DeviceSettingsViewController {
    
    enum SettingsOption {
        
        case changeAddress
        
        case resetNetwork
        
        case syncDatetime
        case getDatetime
        
        case setLightOnOffDuration
        case getLightOnOffDuration
        
        case ota
        
        case lightRunning
        
        case lightSwitchType
        case lightPwmFrequency
        case enablePairing
        case enableRgbIndependence
        case timezone
        case location
        case sunriseSunset
        
        var title: String {
            
            switch self {
            
            case .changeAddress:
                return "change_address".localization
                
            case .resetNetwork:
                return "reset_network".localization
                
            case .syncDatetime:
                return "sync_datetime".localization
                
            case .getDatetime:
                return "get_datetime".localization
                
            case .setLightOnOffDuration:
                return "set_light_onoff_duration".localization
                
            case .getLightOnOffDuration:
                return "get_light_onoff_duration".localization
                
            case .ota:
                return "firmware_update".localization
                
            case .lightRunning:
                return "light_running".localization
                
            case .lightSwitchType:
                return "light_switch_type".localization
                
            case .lightPwmFrequency:
                return "light_pwm_frequency".localization
                
            case .enablePairing:
                return "enable_pairing".localization
                
            case .enableRgbIndependence:
                return "enable_rgb_independence".localization
                
            case .timezone:
                return "timezone".localization
                
            case .location:
                return "location".localization
                
            case .sunriseSunset:
                return "sunrise_sunset".localization
            }
        }
    }
    
}

extension DeviceSettingsViewController {
    
    private func changeAddressAction() {
        
        let alertController = UIAlertController(title: "change_address".localization, message: "change_address_msg".localization, preferredStyle: .alert)
        alertController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alertController.popoverPresentationController?.sourceView = view
        
        var addressTextField: UITextField!
        alertController.addTextField { (textField) in
            
            addressTextField = textField
            
            textField.keyboardType = .numberPad
            textField.autocorrectionType = .no
            textField.placeholder = "1~255"
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        let changeAction = UIAlertAction(title: "change".localization, style: .default) { [weak self] (_) in
            
            guard let self = self, let macData = self.device.macData else { return }
            guard let valueString = addressTextField.text, valueString.count > 0, let address = Int(valueString, radix: 10) else { return }
            
            guard address >= 1 && address <= 255 else {
                
                self.view.makeToast("out_of_range".localization, position: .center)
                return
            }
            
            self.newAddress = (address, macData)
            self.changeAddressTimer?.invalidate()
            self.changeAddressTimer = Timer.scheduledTimer(timeInterval: self.changeAddressTimeInterval, target: self, selector: #selector(self.changeAddressTimerAction), userInfo: nil, repeats: false)
            
            self.view.makeToastActivity(.center)
            
//            MeshCommand.changeAddress(Int(self.device.meshDevice.address), withNewAddress: address, macData: macData).send()
            MeshCommand.changeAddress(Int(self.device.meshDevice.address), withNewAddress: address).send()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(changeAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func changeAddressTimerAction() {
        
        view.hideToastActivity()
        view.makeToast("change_address_overtime".localization, position: .center)
    }
    
    private func resetNetworkAction() {
        
        let alertController = UIAlertController(title: "reset_network".localization, message: "reset_network_msg".localization, preferredStyle: .alert)
        alertController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alertController.popoverPresentationController?.sourceView = view
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        let resetAction = UIAlertAction(title: "reset".localization, style: .default) { [weak self] (_) in
            
            guard let self = self else { return }
            
            MeshCommand.resetNetwork(Int(self.device.meshDevice.address)).send()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(resetAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func syncDatetimeAction() {
        
        MeshCommand.syncDatetime(Int(device.meshDevice.address)).send()
        view.makeToast("sent".localization, position: .center)
    }
    
    private func getDatetimeAction() {
     
        MeshCommand.getDatetime(Int(device.meshDevice.address)).send()
    }
    
    private func setLightOnOffDurationAction() {
        
        let alert = UIAlertController(title: "set_light_onoff_duration".localization, message: "[0, 65535]", preferredStyle: .alert)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        
        var valueTextField: UITextField?
        alert.addTextField { (textField) in
            valueTextField = textField
            textField.keyboardType = .numberPad
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "ok".localization, style: .default) { [weak self] (_) in
            
            guard let self = self else { return }
            guard let valueString = valueTextField?.text, let value = Int(valueString, radix: 10) else {
                
                return
            }
            
            MeshCommand.setLightOnOffDuration(Int(self.device.meshDevice.address), duration: value).send()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func getLightOnOffDurationAction() {
        
        MeshCommand.getLightOnOffDuration(Int(device.meshDevice.address)).send()
    }
    
    private func lightSwitchTypeAction() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.height / 2, y: view.bounds.width / 2, width: 1, height: 1)
        
        let address = Int(device.meshDevice.address)
        MeshManager.shared.deviceDelegate = self
        
        let normalOnOffAction = UIAlertAction(title: MeshCommand.LightSwitchType.normalOnOff.title, style: .default) { _ in
            
            MeshCommand.setLightSwitchType(address, switchType: .normalOnOff).send()
        }
        
        let pushButtonAction = UIAlertAction(title: MeshCommand.LightSwitchType.pushButton.title, style: .default) { _ in
            
            MeshCommand.setLightSwitchType(address, switchType: .pushButton).send()
        }
        
        let threeChannelsAction = UIAlertAction(title: MeshCommand.LightSwitchType.threeChannels.title, style: .default) { _ in
            
            MeshCommand.setLightSwitchType(address, switchType: .threeChannels).send()
        }
        
        let getAction = UIAlertAction(title: "get".localization, style: .default) { _ in
            
            MeshCommand.getLightSwitchType(address).send()
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        
        alert.addAction(normalOnOffAction)
        alert.addAction(pushButtonAction)
        alert.addAction(threeChannelsAction)
        alert.addAction(getAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func lightPwmFrequencyAction() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.height / 2, y: view.bounds.width / 2, width: 1, height: 1)
        
        let address = Int(device.meshDevice.address)
        MeshManager.shared.deviceDelegate = self
        
        let fiveHundredAction = UIAlertAction(title: "600", style: .default) { action in
            
            MeshCommand.setLightPwmFrequency(address, frequency: 600).send()
        }
        
        let threeThousandAction = UIAlertAction(title: "3000", style: .default) { action in
            
            MeshCommand.setLightPwmFrequency(address, frequency: 3000).send()
        }
        
        let tenThousandAction = UIAlertAction(title: "10000", style: .default) { action in
            
            MeshCommand.setLightPwmFrequency(address, frequency: 10000).send()
        }
        
        let getAction = UIAlertAction(title: "get".localization, style: .default) { _ in
            
            MeshCommand.getLightPwmFrequency(address).send()
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)

        alert.addAction(fiveHundredAction)
        alert.addAction(threeThousandAction)
        alert.addAction(tenThousandAction)
        alert.addAction(getAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func enablePairingAction() {
        
        let address = Int(device.meshDevice.address)
        MeshCommand.enablePairing(address).send()
        view.makeToast("ok".localization, position: .center)
    }
    
    private func enableRgbIndependenceAction() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.height / 2, y: view.bounds.width / 2, width: 1, height: 1)
        
        let address = Int(device.meshDevice.address)
        MeshManager.shared.deviceDelegate = self
        
        let enableAction = UIAlertAction(title: "enable".localization, style: .default) { _ in
        
            MeshCommand.setRgbIndependence(address, isEnabled: true).send()
        }
        
        let disableAction = UIAlertAction(title: "disable".localization, style: .default) { _ in
        
            MeshCommand.setRgbIndependence(address, isEnabled: false).send()
        }
        
        let getAction = UIAlertAction(title: "get".localization, style: .default) { _ in
        
            MeshCommand.getRgbIndependence(address).send()
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        
        alert.addAction(enableAction)
        alert.addAction(disableAction)
        alert.addAction(getAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func timezoneAction() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.height / 2, y: view.bounds.width / 2, width: 1, height: 1)
        
        let address = Int(device.meshDevice.address)
        MeshManager.shared.deviceDelegate = self
        
        let setAction = UIAlertAction(title: "set".localization, style: .default) { _ in
        
            let seconds = TimeZone.current.secondsFromGMT()
            
            let isNegative = seconds < 0
            let hour = seconds / 3600
            let minute = (seconds - hour * 3600) / 60
            MeshCommand.setTimezone(address, hour: hour, minute: minute, isNegative: isNegative).send()
        }
        
        let getAction = UIAlertAction(title: "get".localization, style: .default) { _ in
        
            MeshCommand.getTimezone(address).send()
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        
        alert.addAction(setAction)
        alert.addAction(getAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func locationAction() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.height / 2, y: view.bounds.width / 2, width: 1, height: 1)
        
        let address = Int(device.meshDevice.address)
        MeshManager.shared.deviceDelegate = self
        
        let setAction = UIAlertAction(title: "set".localization, style: .default) { _ in
        
            MeshCommand.setLocation(address, longitude: 116.46, latitude: 39.92).send()
        }
        
        let getAction = UIAlertAction(title: "get".localization, style: .default) { _ in
        
            MeshCommand.getLocation(address).send()
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        
        alert.addAction(setAction)
        alert.addAction(getAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
}

extension DeviceSettingsViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, didUpdateMeshDevices meshDevices: [MeshDevice]) {
        
//        meshDevices.forEach {
//            
//            MeshCommand.requestMacDeviceType(Int($0.address)).send()
//        }
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didUpdateDeviceType deviceType: MeshDeviceType, macData: Data) {
        
        guard let newAddress = self.newAddress else { return }
        
        if newAddress.0 == address && newAddress.1 == macData {
            
            // Change succeed
            changeAddressTimer?.invalidate()
            view.hideToastActivity()
            view.makeToast("change_address_successful".localization, position: .center)
        }
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetDate date: Date) {
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = dateComponents.year ?? 0
        let month = dateComponents.month ?? 0
        let day = dateComponents.day ?? 0
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        let second = dateComponents.second ?? 0
        let dateString = "\(address): \(year)/\(month)/\(day) \(hour):\(minute):\(second)"
        view.makeToast(dateString, position: .center)
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetLightOnOffDuration duration: Int) {
        
        let message = "\(address): duration \(duration) seconds"
        view.makeToast(message, position: .center)
    }
    
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetFirmwareVersion version: String) {
        
        guard address == device.meshDevice.address else { return }
        
        view.makeToast("Frimware: \(version)", position: .center)
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetLightSwitchType switchType: MeshCommand.LightSwitchType) {
        
        guard address == device.meshDevice.address else { return }
        
        view.makeToast("LightSwitchType: \(switchType.title)", position: .center)
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetLightPwmFrequency frequency: Int) {
        
        guard address == device.meshDevice.address else { return }
        
        view.makeToast("LightPwmFrequency: \(frequency)", position: .center)
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetRgbIndependence isEnabled: Bool) {
        
        guard address == device.meshDevice.address else { return }
        
        view.makeToast("RGBIndependence: " + (isEnabled ? "True" : "False"), position: .center)
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetTimezone isNegative: Bool, hour: Int, minute: Int, sunriseHour: Int, sunriseMinute: Int, sunsetHour: Int, sunsetMinute: Int) {
        
        guard address == device.meshDevice.address else { return }
        
        let sign = isNegative ? "-" : ""
        let msg = "\(sign)\(hour):\(minute), \(sunriseHour):\(sunriseMinute), \(sunsetHour):\(sunsetMinute)"
        view.makeToast(msg, position: .center)
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetLocation longitude: Float, latitude: Float) {
        
        guard address == device.meshDevice.address else { return }
        
        view.makeToast("Location: \(longitude), \(latitude)", position: .center)
    }
    
}

extension MeshCommand.LightSwitchType {
    
    var title: String {
        
        switch self {
            
        case .normalOnOff: return "normal_onoff".localization
        case .pushButton: return "push_button".localization
        case .threeChannels: return "three_channels".localization
        }
    }
}
