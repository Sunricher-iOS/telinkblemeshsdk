//
//  AlarmViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/11/14.
//

import UIKit
import TelinkBleMesh

class AlarmViewController: UITableViewController {
    
    var isAdd: Bool = true
    var address: Int = 0
    var alarmID: Int = 0
    var actionType: AlarmActionType = .off
    var dayType: AlarmDayType = .day
    var isEnabled = true
    var hour: Int = 10
    var minute: Int = 10
    var second: Int = 0
    var sceneID: Int = 0
    var month: Int = 1
    var day: Int = 1
    var week: Int = 0
    
    private var cellTypes: [CellType] = [
        .alarmID, .actionType, .dayType, .hour,
        .minute, .second, .sceneID, .month,
        .day, .week
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = isAdd ? "Add Alarm" : "Edit Alarm"
        
        let doneItem = UIBarButtonItem(title: "done".localization, style: .done, target: self, action: #selector(self.doneAction))
        navigationItem.rightBarButtonItem = doneItem
    }
    
    @objc private func doneAction() {
        
        var alarm: AlarmProtocol!
        
        if dayType == .day {
            
            var dayAlarm = DayAlarm(alarmID: alarmID)
            dayAlarm.actionType = actionType
            dayAlarm.isEnabled = isEnabled
            dayAlarm.hour = hour
            dayAlarm.minute = minute
            dayAlarm.second = second
            dayAlarm.sceneID = sceneID
            dayAlarm.month = month
            dayAlarm.hour = hour
            alarm = dayAlarm
            
        } else if dayType == .week {
            
            var weekAlarm = WeekAlarm(alarmID: alarmID)
            weekAlarm.actionType = actionType
            weekAlarm.isEnabled = isEnabled
            weekAlarm.hour = hour
            weekAlarm.minute = minute
            weekAlarm.second = second
            weekAlarm.sceneID = sceneID
            weekAlarm.week = week
            alarm = weekAlarm
        }
        
        if isAdd {
            
            MeshCommand.addAlarm(address, alarm: alarm).send()
            
        } else {
            
            MeshCommand.updateAlarm(address, alarm: alarm).send()
        }
        
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellType = cellTypes[indexPath.row]
        switch cellType {
            
        case .actionType:
            toggleActionType()
            
        case .dayType:
            toggleDayType()
            
        case .hour: fallthrough
        case .minute: fallthrough
        case .second: fallthrough
        case .sceneID: fallthrough
        case .month: fallthrough
        case .day:
            showTextFieldAlert(cellType)
            
        case .week:
            showWeekdaysSelection()
            
        case .alarmID:
            break
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cellTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let cellType = cellTypes[indexPath.row]
        cell.textLabel?.text = cellType.title
        cell.selectionStyle = .default
        
        switch cellType {
            
        case .alarmID:
            cell.detailTextLabel?.text = "\(alarmID)"
            cell.selectionStyle = .none
            
        case .actionType:
            cell.detailTextLabel?.text = actionType.title
            
        case .dayType:
            cell.detailTextLabel?.text = dayType.title
            
        case .hour:
            cell.detailTextLabel?.text = "\(hour)"
            
        case .minute:
            cell.detailTextLabel?.text = "\(minute)"
            
        case .second:
            cell.detailTextLabel?.text = "\(second)"
            
        case .sceneID:
            cell.detailTextLabel?.text = "\(sceneID)"
            
        case .month:
            cell.detailTextLabel?.text = "\(month)"
            
        case .day:
            cell.detailTextLabel?.text = "\(day)"
            
        case .week:
            cell.detailTextLabel?.text = week.weekStirng
            
        }
        
        return cell
    }

    
}

extension AlarmViewController {
    
    private enum CellType {
        
        case alarmID
        case actionType
        case dayType
        case hour
        case minute
        case second
        case sceneID
        
        case month
        case day
        
        case week
        
        var title: String {
            
            switch self {
                
            case .alarmID: return "Alarm ID"
            case .actionType: return "Action Type"
            case .dayType: return "Day Type"
            case .hour: return "Hour"
            case .minute: return "Minute"
            case .second: return "Second"
            case .sceneID: return "Scene ID"
            case .month: return "Month"
            case .day: return "Day"
            case .week: return "Week"
            }
        }
    }
    
}

extension AlarmActionType {
    
    var title: String {
        
        switch self {
            
        case .on: return "On"
        case .off: return "Off"
        case .scene: return "Scene"
        }
    }
}

extension AlarmDayType {
    
    var title: String {
        
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        }
    }
}

extension AlarmViewController {
    
    private func toggleActionType() {
        
    }
    
    private func toggleDayType() {
        
    }
    
    private func showTextFieldAlert(_ cellType: CellType) {
        
    }
    
    private func showWeekdaysSelection() {
        
    }
}
