//
//  DeviceAddressesViewController.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/5/6.
//

import UIKit
import TelinkBleMesh

class DeviceAddressesViewController: UITableViewController {
    
    var network: MeshNetwork!
    
    private let sectionTypes: [SectionType] = [.used, .available]
    private var usedAddresses: [Int] = []
    private var availableAddresses: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "device_addresses".localization
        
        let clearItem = UIBarButtonItem(title: "clear_used".localization, style: .plain, target: self, action: #selector(self.clearUsedAction(_:)))
        navigationItem.rightBarButtonItem = clearItem
        
        usedAddresses = MeshAddressManager.shared.existAddressList(network).sorted(by: <)
        availableAddresses = MeshAddressManager.shared.availableAddressList(network).sorted(by: <)
    }
    
    @objc func clearUsedAction(_ sender: Any) {
        
        let alertController = UIAlertController(title: "clear_used".localization, message: "clear_used_msg".localization, preferredStyle: .alert)
        alertController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 1, height: 1)
        alertController.popoverPresentationController?.sourceView = view
        
        let cancelAction = UIAlertAction(title: "cancel".localization, style: .cancel, handler: nil)
        
        let clearAction = UIAlertAction(title: "clear".localization, style: .destructive) { [weak self] (_) in
            
            guard let self = self else { return }
            
            MeshAddressManager.shared.removeAll(self.network)
            self.availableAddresses.append(contentsOf: self.usedAddresses)
            self.usedAddresses.removeAll()
            self.tableView.reloadData()
        }
            
        alertController.addAction(cancelAction)
        alertController.addAction(clearAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sectionTypes.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch sectionTypes[section] {
        
        case .used:
            return usedAddresses.count
            
        case .available:
            return availableAddresses.count
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sectionTypes[section].title
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        switch sectionTypes[indexPath.section] {
        
        case .used:
            
            let deleteAction = UIContextualAction(style: .destructive, title: "delete".localization.uppercased(), handler: { [weak self] (_, _, completion) in
                
                guard let self = self else { return }
                
                let address = self.usedAddresses[indexPath.row]
                MeshAddressManager.shared.remove(address, network: self.network)
                self.usedAddresses.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.availableAddresses.insert(address, at: 0)
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                completion(true)
            })
            
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            configuration.performsFirstActionWithFullSwipe = false
            return configuration
            
        case .available:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        var address: Int!
        
        switch sectionTypes[indexPath.section] {
        
        case .used:
            address = usedAddresses[indexPath.row]
            cell.textLabel?.text = "\(address!)"
            
        case .available:
            address = availableAddresses[indexPath.row]
            cell.textLabel?.text = "\(address!) *"
        }
        
        cell.selectionStyle = .none
        
        return cell
    }

}

extension DeviceAddressesViewController {
    
    private enum SectionType {
        
        case used
        case available
        
        var title: String {
            
            switch self {
            
            case .used:
                return "used_addresses".localization
                
            case .available:
                return "available_addresses".localization
            }
        }
    }
    
}
