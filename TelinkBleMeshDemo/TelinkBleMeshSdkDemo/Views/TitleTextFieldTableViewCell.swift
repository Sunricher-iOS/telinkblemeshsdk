//
//  TitleTextFieldTableViewCell.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/11/11.
//

import UIKit

class TitleTextFieldTableViewCell: UITableViewCell {
    
    private(set) var textField: UITextField!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
        
        textField.autocorrectionType = .no
        textField.keyboardType = .numberPad
        
        NSLayoutConstraint.activate([
            textField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 20),
            textField.widthAnchor.constraint(equalToConstant: 64),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 36)
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

}
