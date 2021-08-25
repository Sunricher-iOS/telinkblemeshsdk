//
//  File.swift
//  
//
//  Created by maginawin on 2021/1/13.
//

import Foundation
import CryptoAction

public struct MeshCommand {
    
    private static var seqNo: Int = 0
    
    /// [0-2],
    /// 3 bytes, for data notify
    var seqNo: Int = 0
    
    /// [0-2],
    /// 3 bytes, for command data, will auto increment
    var seqNoForCommandData: Int {
        
        if MeshCommand.seqNo >= 0xFFFFFF {
            
            MeshCommand.seqNo = 0
        }
        
        MeshCommand.seqNo += 1
        return MeshCommand.seqNo
    }
    
    /// [3-4],
    /// 2 bytes
    var src: Int = 0
    
    /// [5-6],
    /// 2 bytes
    var dst: Int = 0
    
    /// [7],
    /// 1 bytes
    var tag: Tag = .appToNode
    
    /// [8-9],
    /// 2 bytes
    let vendorID: Int = 0x1102
    
    /// [10],
    /// 1 bytes, default is 0x10, transfer this command to the mesh network times
    var param: Int = 0x10
    
    /// [11, 19],
    /// 9 bytes
    var userData = Data(repeating: 0x00, count: 9)
    
    /// Data for send.
    var commandData: Data {
        
        var data = Data(repeating: 0, count: 20)
        
        let seqNo = self.seqNoForCommandData
        data[0] = UInt8((seqNo >> 16) & 0xFF)
        data[1] = UInt8((seqNo >> 8) & 0xFF)
        data[2] = UInt8(seqNo & 0xFF)
        
        data[3] = UInt8(src & 0xFF)
        data[4] = UInt8((src >> 8) & 0xFF)
        data[5] = UInt8(dst & 0xFF)
        data[6] = UInt8((dst >> 8) & 0xFF)
        
        data[7] = UInt8(tag.rawValue)
        data[8] = UInt8((vendorID >> 8) & 0xFF)
        data[9] = UInt8(vendorID & 0xFF)
        data[10] = UInt8(param)
        
        for i in 11..<20 {
            
            data[i] = userData[i - 11]
        }
        
        return data
    }
    
    init() {
        
    }
    
    /// Init with a notify data `(charactersistic.value)`.
    init?(notifyData data: Data) {
        
        guard data.count == 20 else { return nil }
        
        guard let tempTag = Tag(rawValue: data[7]) else {
            
            return
        }
        
        var tempSeqNo = Int(data[0]) << 16
        tempSeqNo |= Int(data[1]) << 8
        tempSeqNo |= Int(data[2])
        seqNo = tempSeqNo
        
        var tempSrc = Int(data[3])
        tempSrc |= Int(data[4]) << 8
        src = tempSrc
        
        var tempDst = Int(data[5])
        tempDst |= Int(data[6]) << 8
        dst = tempDst
        
        // data[7]
        tag = tempTag
        
        var tempVendorID = Int(data[8]) << 8
        tempVendorID |= Int(data[9])
        
        param = Int(data[10])
        userData = Data(data[11..<20])
    }
    
    init?(mqttCommandData data: Data) {
        
        guard data.count == 20 else { return nil }
        
        guard let tempTag = Tag(rawValue: data[7]) else {
            
            return
        }
        
        var tempSrc = Int(data[3])
        tempSrc |= Int(data[4]) << 8
        src = tempSrc
        
        var tempDst = Int(data[5])
        tempDst |= Int(data[6]) << 8
        dst = tempDst
        
        tag = tempTag
        
        var tempVendorID = Int(data[8]) << 8
        tempVendorID |= Int(data[9])
        
        param = Int(data[10])
        userData = Data(data[11..<20])
    }
    
}

extension MeshCommand {
    
    /// `data[7]`
    enum Tag: UInt8 {
        
        case appToNode = 0xEA
        
        case nodeToApp = 0xEB
        
        case lightStatus = 0xDC
        
        case onOff = 0xD0
        
        case brightness = 0xD2
        
        case singleChannel = 0xE2
        
        case replaceAddress = 0xE0
        
        case getMacNotify = 0xE1
        
        case resetNetwork = 0xE3
        
        case syncDatetime = 0xE4
        
        case getDatetime = 0xE8
        
        case datetimeResponse = 0xE9
        
        case getFirmware = 0xC7
        
        case firmwareResponse = 0xC8
    }
    
    /// Sunricher private protocol
    enum SrIndentifier: UInt8 {
        
        case mac = 0x76
        
        case lightControlMode = 0x01
    }
    
    enum SrLightControlMode: UInt8 {
        
        case lightOnOffDuration = 0x0F
    }
    
    enum SingleChannel: UInt8 {
        
        case red = 0x01
        case green = 0x02
        case blue = 0x03
        case rgb = 0x04
        case colorTemperature = 0x05
    }
    
}

extension MeshCommand {
    
    public struct Address {
        
        /// Send command to the connected node.
        public static let connectedNode = 0x0000
        
        /// Sned command to all mesh devices.
        public static let all = 0xFFFF
        
    }
    
}

extension MeshCommand {
    
    /**
     - Parameter isSample: Default value is `false`.
     */
    public func send(isSample: Bool = false) {
        
        MeshManager.shared.send(self, isSample: isSample)
    }
    
}

// MARK: - Mesh

extension MeshCommand {
    
    /**
     __@Telink__.
     */
    public static func requestAddressMac(_ address: Int = Address.all) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .replaceAddress
        cmd.dst = address
        cmd.param = 0xFF
        cmd.userData[0] = 0xFF
        cmd.userData[1] = 0x01
        cmd.userData[2] = 0x10
        return cmd
    }
    
    /**
     __@Telink__
     Change device address with new address.
     
     - Note: After change the address, you need to power off and restart all devices.
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode`, default is `.connectedNode`
        - newAddress: The new address, range is [1, 255].
     */
    public static func changeAddress(_ address: Int, withNewAddress newAddress: Int, macData: Data) -> MeshCommand {
        
        assert(newAddress > 0 && newAddress <= 0xFF, "New address out of range [1, 255].")
        assert(macData.count == 6, "macData.count != 6")
        
        var cmd = MeshCommand()
        cmd.tag = .replaceAddress
        cmd.dst = address
        cmd.param = newAddress & 0xFF
        cmd.userData[0] = 0x00
        cmd.userData[1] = 0x01
        cmd.userData[2] = 0x10
        cmd.userData[3] = macData[5]
        cmd.userData[4] = macData[4]
        cmd.userData[5] = macData[3]
        cmd.userData[6] = macData[2]
        cmd.userData[7] = macData[1]
        cmd.userData[8] = macData[0]
        return cmd
    }
    
    public static func changeAddress(_ address: Int, withNewAddress newAddress: Int) -> MeshCommand {
        
        assert(newAddress > 0 && newAddress <= 0xFF, "New address out of range [1, 255].")
        
        var cmd = MeshCommand()
        cmd.tag = .replaceAddress
        cmd.dst = address
        cmd.param = newAddress & 0xFF
        cmd.userData[0] = 0x00
        return cmd
    }
    
    /**
     __@Telink__
     Restore to the default (factory) network.
     
     - Note: After reset the network, you need to power off and restart all devices.
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode`, default is `.connectedNode`
     */
    public static func resetNetwork(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .resetNetwork
        cmd.dst = address
        // 0x01 reset network name to default value, 0x00 reset to `out_of_mesh`.
        cmd.param = 0x01
        return cmd
    }
    
}

// MARK: - Request

extension MeshCommand {
    
    /**
     __@Sunricher__
     Request the MAC and MeshDeviceType of the MeshDevice.
     
     - Parameter address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
     */
    public static func requestMacDeviceType(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = 0x76
        return cmd
    }
    
}

// MARK: - Control

extension MeshCommand {
    
    /**
     __@Sunricher__
     Turn on/off the device.
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
        - isOn: Is turn on.
        - delay: Delay time (millisecond), range is [0x00, 0xFFFF], defalt is 0.
     */
    public static func turnOnOff(_ address: Int, isOn: Bool, delay: UInt16 = 0) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .onOff
        cmd.dst = address
        cmd.param = isOn ? 0x01 : 0x00
        cmd.userData[0] = UInt8(delay & 0xFF)
        cmd.userData[1] = UInt8((delay >> 8) & 0xFF)
        return cmd
    }
    
    /**
     __@Sunricher__
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
        - value: Range [0, 100].
     */
    public static func setBrightness(_ address: Int, value: Int) -> MeshCommand {
        
        assert(value >= 0 && value <= 100, "value out of range [0, 100].")
        
        var cmd = MeshCommand()
        cmd.tag = .brightness
        cmd.dst = address
        cmd.param = value
        return cmd
    }
    
    /**
     __@Sunricher__
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
        - value: Range [0, 100], 0 means the coolest color, 100 means the warmest color.
     */
    public static func setColorTemperature(_ address: Int, value: Int) -> MeshCommand {
        
        assert(value >= 0 && value <= 100, "value out of range [0, 100].")
        
        var cmd = MeshCommand()
        cmd.tag = .singleChannel
        cmd.dst = address
        cmd.param = Int(SingleChannel.colorTemperature.rawValue)
        cmd.userData[0] = UInt8(value)
        cmd.userData[1] = 0b0000_0000
        return cmd
    }
    
    /**
     __@Sunricher__
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
        - value: Range [0, 255].
     */
    public static func setWhite(_ address: Int, value: Int) -> MeshCommand {
        
        assert(value >= 0 && value <= 255, "value out of range [0, 255].")
        
        var cmd = MeshCommand()
        cmd.tag = .singleChannel
        cmd.dst = address
        cmd.param = Int(SingleChannel.colorTemperature.rawValue)
        cmd.userData[0] = UInt8(value)
        cmd.userData[1] = 0b0001_0000
        return cmd
    }
    
    /**
     __@Sunricher__
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
        - value: Range [0, 255].
     */
    public static func setRed(_ address: Int, value: Int) -> MeshCommand {
        
        assert(value >= 0 && value <= 255, "value out of range [0, 255].")
        
        var cmd = MeshCommand()
        cmd.tag = .singleChannel
        cmd.dst = address
        cmd.param = Int(SingleChannel.red.rawValue)
        cmd.userData[0] = UInt8(value)
        return cmd
    }
    
    /**
      __@Sunricher__
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
        - value: Range [0, 255].
     */
    public static func setGreen(_ address: Int, value: Int) -> MeshCommand {
        
        assert(value >= 0 && value <= 255, "value out of range [0, 255].")
        
        var cmd = MeshCommand()
        cmd.tag = .singleChannel
        cmd.dst = address
        cmd.param = Int(SingleChannel.green.rawValue)
        cmd.userData[0] = UInt8(value)
        return cmd
    }
    
    /**
     __@Sunricher__
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
        - value: Range [0, 255].
     */
    public static func setBlue(_ address: Int, value: Int) -> MeshCommand {
        
        assert(value >= 0 && value <= 255, "value out of range [0, 255].")
        
        var cmd = MeshCommand()
        cmd.tag = .singleChannel
        cmd.dst = address
        cmd.param = Int(SingleChannel.blue.rawValue)
        cmd.userData[0] = UInt8(value)
        return cmd
    }
    
    /**
     __@Sunricher__
     
     - Parameters:
        - address: `Int(MeshDevice.address)` or `MeshCommand.Address.connectedNode | .all`.
        - red: Range [0, 255].
         - green: Range [0, 255].
         - blue: Range [0, 255].
     */
    public static func setRgb(_ address: Int, red: Int, green: Int, blue: Int) -> MeshCommand {
        
        assert(red >= 0 && red <= 255, "red out of range [0, 255].")
        assert(green >= 0 && green <= 255, "green out of range [0, 255].")
        assert(blue >= 0 && blue <= 255, "blue out of range [0, 255].")
        
        var cmd = MeshCommand()
        cmd.tag = .singleChannel
        cmd.dst = address
        cmd.param = Int(SingleChannel.rgb.rawValue)
        cmd.userData[0] = UInt8(red)
        cmd.userData[1] = UInt8(green)
        cmd.userData[2] = UInt8(blue)
        return cmd
    }
    
}

// MARK: - Date-time

extension MeshCommand {
    
    public static func syncDatetime(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .syncDatetime
        cmd.dst = address
        
        let now = Date()
        let calendar = Calendar.current
        let dateComponent = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        let year = dateComponent.year ?? 2000
        let month = dateComponent.month ?? 1
        let day = dateComponent.day ?? 1
        let hour = dateComponent.hour ?? 0
        let minute = dateComponent.minute ?? 0
        let second = dateComponent.second ?? 0
        
        cmd.param = (year & 0xFF)
        cmd.userData[0] = UInt8((year >> 8) & 0xFF)
        cmd.userData[1] = UInt8(month & 0xFF)
        cmd.userData[2] = UInt8(day & 0xFF)
        cmd.userData[3] = UInt8(hour & 0xFF)
        cmd.userData[4] = UInt8(minute & 0xFF)
        cmd.userData[5] = UInt8(second & 0xFF)
        return cmd
    }
    
    public static func getDatetime(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .getDatetime
        cmd.dst = address
        cmd.param = 0x10
        return cmd
    }
}

// MARK: - Light Control Mode

extension MeshCommand {
    
    /// - Parameter duration: Range `[1, 0xFFFF]`, unit `second(s)`.
    public static func setLightOnOffDuration(_ address: Int, duration: Int) -> MeshCommand {
                
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.lightOnOffDuration.rawValue
        cmd.userData[2] = 0x01 // set
        cmd.userData[3] = UInt8(duration & 0xFF)
        cmd.userData[4] = UInt8((duration >> 8) & 0xFF)
        return cmd
    }
    
    public static func getLightOnOffDuration(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.lightOnOffDuration.rawValue
        cmd.userData[2] = 0x00 // get
        return cmd
    }
    
}

// MARK: - OTA

extension MeshCommand {
    
    public static func getFirmwareVersion(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .getFirmware
        cmd.dst = address
        return cmd
    }
    
}
