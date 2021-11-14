//
//  AlarmsViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/11/13.
//

import UIKit
import TelinkBleMesh

class AlarmsViewController: UITableViewController {
    
    var address: Int = 0
    
    private var alarms: [AlarmProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "alarms".localization
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addAction))
        let refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
        navigationItem.rightBarButtonItems = [addItem, refreshItem]
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getAlarm(address, alarmID: 0x00).send()
    }
    
    @objc private func addAction() {
        
        let controller = AlarmViewController(style: .grouped)
        controller.address = address
        controller.isAdd = true
        controller.isEnabled = true 
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc private func refreshAction() {
        
        alarms.removeAll()
        tableView.reloadData()
        
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getAlarm(address, alarmID: 0x00).send()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var alarm = alarms[indexPath.row]
        alarm.isEnabled = !alarm.isEnabled
        alarms[indexPath.row] = alarm
        tableView.reloadRows(at: [indexPath], with: .automatic)
        MeshCommand.enableAlarm(address, alarmID: alarm.alarmID, isEnabled: alarm.isEnabled).send()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return alarms.count
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let edit = UIContextualAction(style: .normal, title: "edit".localization) { action, view, completion in
            
            let alarm = self.alarms[indexPath.row]
            let controller = AlarmViewController(style: .grouped)
            controller.isAdd = false
            controller.address = self.address
            controller.alarmID = alarm.alarmID
            controller.actionType = alarm.actionType
            controller.dayType = alarm.dayType
            controller.isEnabled = alarm.isEnabled
            controller.hour = alarm.hour
            controller.minute = alarm.minute
            controller.second = alarm.second
            controller.sceneID = alarm.sceneID
            
            if alarm.dayType == .day, let dayAlarm = alarm as? DayAlarm {
                controller.month = dayAlarm.month
                controller.day = dayAlarm.day
            } else if alarm.dayType == .week, let weekAlarm = alarm as? WeekAlarm {
                controller.week = weekAlarm.week
            }
            self.navigationController?.pushViewController(controller, animated: true)
            
            completion(true)
        }
        
        let delete = UIContextualAction(style: .destructive, title: "delete".localization) { action, view, completion in
            
            let alarm = self.alarms[indexPath.row]
            MeshCommand.deleteAlarm(self.address, alarmID: alarm.alarmID).send()
            self.alarms.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            completion(true)
        }
        
        let config = UISwipeActionsConfiguration(actions: [edit, delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let alarm = alarms[indexPath.row]
        let timeString = String(format: "%02d:%02d", alarm.hour, alarm.minute)
        cell.textLabel?.text = timeString 
        cell.accessoryType = alarm.isEnabled ? .checkmark : .none
        if alarm.dayType == .day, let dayAlarm = alarm as? DayAlarm {
            let detail = String(format: "%02d/%02d", dayAlarm.month, dayAlarm.day)
            cell.detailTextLabel?.text = detail
        } else if alarm.dayType == .week, let weekAlarm = alarm as? WeekAlarm {
            cell.detailTextLabel?.text = weekAlarm.weekString
        }
        
        return cell
    }

}

extension WeekAlarm {
    
    var weekString: String {
        
        return week.weekStirng
    }
    
}

extension Int {
    
    var weekStirng: String {
        
        if self == 0x41 {
            return "Weekend"
        } else if self == 0x3E {
            return "Weekday"
        } else if self == 0x7F {
            return "Every day"
        } else if self == 0 {
            return "No Repeats"
        }
        
        let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var currentDays = ""
        for i in 0...6 {
            if (self & (0x01 << i)) > 0 {
                    currentDays += weekDays[i] + " "
            }
        }
        return currentDays.trimmingCharacters(in: .whitespaces)
    }
}

extension AlarmsViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetAlarm alarm: AlarmProtocol) {
        
        guard address == self.address, !alarms.contains(where: { $0.alarmID == alarm.alarmID }) else {
            return
        }
        
        alarms.append(alarm)
        tableView.reloadData()
    }
    
}
