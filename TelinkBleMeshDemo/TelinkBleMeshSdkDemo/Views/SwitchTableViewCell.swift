//
//  SwitchTableViewCell.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/3/25.
//

import UIKit

protocol SwitchTableViewCellDelegate: NSObjectProtocol {
    
    func switchCell(_ cell: SwitchTableViewCell, switchValueChanged isOn: Bool)
    
}

class SwitchTableViewCell: UITableViewCell {
    
    private(set) var rightSwitch: UISwitch!
    
    weak var delegate: SwitchTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "cell")
        
        selectionStyle = .none
        
        rightSwitch = UISwitch()
        rightSwitch.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rightSwitch)
        
        rightSwitch.addTarget(self, action: #selector(self.handleValueChanged(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            rightSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            rightSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func handleValueChanged(_ sender: UISwitch) {
        
        delegate?.switchCell(self, switchValueChanged: sender.isOn)
    }

}
