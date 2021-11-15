//
//  WeekdaysViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/11/15.
//

import UIKit

protocol WeekdaysControllerDelegate: NSObjectProtocol {
    
    func weekdaysController(_ controller: WeekdaysViewController, didUpdateWeek week: Int)
    
}

class WeekdaysViewController: UITableViewController {
    
    var week: Int = 0
    var delegate: WeekdaysControllerDelegate?
    
    private let cellTypes: [CellType] = [
        .sun, .mon, .tue, .wed, .thu, .fri, .sat
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Week"
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        week ^= (0x01 << indexPath.row)
        tableView.reloadData()
        delegate?.weekdaysController(self, didUpdateWeek: week)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cellTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        let cellType = cellTypes[indexPath.row]
        cell.textLabel?.text = cellType.title
        let isSelected = (week & (0x01 << indexPath.row)) > 0
        cell.accessoryType = isSelected ? .checkmark : .none
        
        return cell
    }

}

extension WeekdaysViewController {
    
    private enum CellType {
        
        case sun
        case mon
        case tue
        case wed
        case thu
        case fri
        case sat
        
        var title: String {
            
            switch self {
                
            case .sun: return "Sunday"
            case .mon: return "Monday"
            case .tue: return "Tuesday"
            case .wed: return "Wednesday"
            case .thu: return "Thursday"
            case .fri: return "Friday"
            case .sat: return "Saturday"
            }
        }
    }
}
