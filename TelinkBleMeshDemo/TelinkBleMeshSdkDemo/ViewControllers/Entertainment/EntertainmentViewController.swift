//
//  EntertainmentViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2022/1/17.
//

import UIKit
import TelinkBleMesh

class EntertainmentViewController: UITableViewController {
    
    private let sections: [[CellType]] = [
        [.start, .stop]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Entertainment"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MeshEntertainmentManager.shared.stop()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cellType = sections[indexPath.section][indexPath.row]
        switch cellType {
        case .start:
            startActions()
        case .stop:
            MeshEntertainmentManager.shared.stop()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return sections[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
        UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let cellType = sections[indexPath.section][indexPath.row]
        cell.textLabel?.text = cellType.title
        
        return cell
    }

}

extension EntertainmentViewController {
    
    enum CellType {
        case start
        case stop
        
        var title: String {
            switch self {
            case .start: return "Start"
            case .stop: return "Stop"
            }
        }
    }
    
    private func startActions() {
        
        let target = 0x35
        
        var red = MeshEntertainmentAction(target: target)
        red.rgb = 0xFF0000
        var green = MeshEntertainmentAction(target: target)
        green.rgb = 0x00FF00
        var blue = MeshEntertainmentAction(target: target)
        blue.rgb = 0x0000FF
        var off = MeshEntertainmentAction(target: target)
        off.isOn = false
        var on = MeshEntertainmentAction(target: target, delay: 2)
        on.isOn = true
        let offDuration = MeshEntertainmentAction(target: target, delay: 1)
        
        let actions = [red, green, blue, off, on, offDuration]
        MeshEntertainmentManager.shared.start(actions)
    }
}
