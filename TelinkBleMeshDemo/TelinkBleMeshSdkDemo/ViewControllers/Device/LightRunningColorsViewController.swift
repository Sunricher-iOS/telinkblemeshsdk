//
//  LightRunningColorsViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/9/1.
//

import UIKit
import TelinkBleMesh
import Toast

protocol LightRunningColorsViewControllerDelegate: NSObjectProtocol {
    
    func lightRunningColorsViewController(_ controller: LightRunningColorsViewController, didSelectModeId modeId: Int)
    
}

class LightRunningColorsViewController: UITableViewController {
    
    var address: Int!
    weak var delegate: LightRunningColorsViewControllerDelegate?
    
    private var modeIdList: [Int] = []
    private var modeIdColors: [Int: [MeshCommand.LightRunningMode.Color]] = [:]
    
    private var loadingIndex = 0
    private var timer: Timer?
    
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Colors"
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction))
        navigationItem.rightBarButtonItem = addItem
        
        isLoading = true
        MeshManager.shared.deviceDelegate = self
        MeshCommand.getLightRunningCustomModeIdList(address).send()
    }
    
    @objc private func addAction() {
        
        var newModeId = 0
        for i in 1...16 {
            if !modeIdList.contains(i) {
                newModeId = i
                break
            }
        }
        guard newModeId != 0 else {
            
            view.makeToast("No more mode ID", position: .center)
            return
        }
        
        self.isLoading = false
        let controller = LightRunningAddColorViewController(style: .grouped)
        controller.address = address
        controller.modeId = newModeId
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let modeId = modeIdList[indexPath.row]
        delegate?.lightRunningColorsViewController(self, didSelectModeId: modeId)
        navigationController?.popViewController(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return modeIdList.count
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let removeAction = UIContextualAction(style: .destructive, title: "Remove") { action, view, completion in
            
            self.isLoading = false
            let modeId = self.modeIdList[indexPath.row]            
            MeshCommand.removeLightRunningCustomModeId(self.address, modeId: modeId).send()
            
            self.modeIdList.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        
        let configuration =  UISwipeActionsConfiguration(actions: [removeAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        let modeId = modeIdList[indexPath.row]
        cell.textLabel?.text = "\(modeId)"
        let colors = modeIdColors[modeId] ?? []
        cell.detailTextLabel?.text = "\(colors.count) colors"
        
        return cell
    }
}

extension LightRunningColorsViewController: MeshManagerDeviceDelegate {
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetLightRunningModeIdList idList: [Int]) {
        
        guard self.address == address,
              isLoading else { return }
        
        modeIdList = idList
        modeIdColors.removeAll()
        idList.forEach {
            self.modeIdColors[$0] = []
        }
        
        tableView.reloadData()
        
        guard idList.count > 0 else { return }
        
        view.makeToast("Loading colors", duration: Double(Int.max), position: .center)
        
        timer?.invalidate()
        loadingIndex = 0
        MeshCommand.getLightRunningCustomModeColors(self.address, modeId: modeIdList[loadingIndex]).send()
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
    }
    
    @objc private func timerAction() {
        
        if loadingIndex < (modeIdList.count - 1) {
            
            loadingIndex += 1
            MeshCommand.getLightRunningCustomModeColors(self.address, modeId: modeIdList[loadingIndex]).send()
            timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
            
        } else {
            
            // end
            view.hideToast()
        }
    }
    
    func meshManager(_ manager: MeshManager, device address: Int, didGetLightRunningModeId modeId: Int, colorsCount: Int, colorIndex: Int, color: MeshCommand.LightRunningMode.Color) {
        
        guard self.address == address,
              let colors = modeIdColors[modeId],
              colorIndex > colors.count else { return }
        
        modeIdColors[modeId]?.append(color)
        tableView.reloadData()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
    }
    
}
