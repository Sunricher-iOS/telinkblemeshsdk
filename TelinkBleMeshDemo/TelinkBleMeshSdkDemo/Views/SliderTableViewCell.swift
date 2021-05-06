//
//  SliderTableViewCell.swift
//  TelinkBleMeshSdkDemo
//
//  Created by maginawin on 2021/3/24.
//

import UIKit

protocol SliderTableViewCellDelegate: NSObjectProtocol {
    
    func sliderCell(_ cell: SliderTableViewCell, sliderValueChanged value: Float)

    func sliderCell(_ cell: SliderTableViewCell, sliderValueChanging value: Float)
}

class SliderTableViewCell: UITableViewCell {
    
    private(set) var slider: UISlider!
    private(set) var valueLabel: UILabel!
    
    weak var delegate: SliderTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textLabel?.isHidden = true
        detailTextLabel?.isHidden = true
        selectionStyle = .none
        
        slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(slider)
        
        slider.addTarget(self, action: #selector(self.handleValueChanging(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(self.handleValueChanged(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(self.handleValueChanged(_:)), for: .touchUpOutside)
        
        valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(valueLabel)
        
        valueLabel.font = UIFont.systemFont(ofSize: 15)
        valueLabel.textAlignment = .left
        valueLabel.text = nil 
        
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 70),
            slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            slider.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
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
    
    @objc func handleValueChanging(_ sender: UISlider) {
        
        delegate?.sliderCell(self, sliderValueChanging: sender.value)
    }
    
    @objc func handleValueChanged(_ sender: UISlider) {
     
        delegate?.sliderCell(self, sliderValueChanged: sender.value)
    }

}


