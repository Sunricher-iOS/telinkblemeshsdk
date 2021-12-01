//
//  File.swift
//  
//
//  Created by maginawin on 2021/1/13.
//

import UIKit
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
        
        case deviceAddressNotify = 0xE1
        
        case resetNetwork = 0xE3
        
        case syncDatetime = 0xE4
        
        case getDatetime = 0xE8
        
        case datetimeResponse = 0xE9
        
        case getFirmware = 0xC7
        
        case firmwareResponse = 0xC8
        
        case getGroups = 0xDD
        
        case responseGroups = 0xD4
        
        case groupAction = 0xD7
        
        case scene = 0xEE
        
        case loadScene = 0xEF
        
        case getScene = 0xC0
        
        case getSceneResponse = 0xC1
        
        case editAlarm = 0xE5
        
        case getAlarm = 0xE6
        
        case getAlarmResponse = 0xE7
        
        case setRemoteGroups = 0xEC
        
        case responseLeadingGroups = 0xD5
        
        case responseTralingGroups = 0xD6
    }
    
    /// Sunricher private protocol
    enum SrIndentifier: UInt8 {
        
        case mac = 0x76
        
        case lightControlMode = 0x01
        
        case lightSwitchType = 0x07
        
        case special = 0x12
        
        case timezone = 0x1E
        
        case setLocation = 0x1A
        case getLocation = 0x1B
        
        case sunrise = 0x1C
        case sunset = 0x1D
    }
    
    enum SrLightControlMode: UInt8 {
        
        case lightOnOffDuration = 0x0F
        
        case getLightRunningMode = 0x00
        
        case setLightRunningMode = 0x05
        
        case setLightRunningSpeed = 0x03
        
        case customLightRunningMode = 0x01
        
        case lightPwmFrequency = 0x0A
        
        case channelMode = 0x07
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

// MARK: - OTA

extension MeshCommand {
    
    public static func getFirmwareVersion(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .getFirmware
        cmd.dst = address
        return cmd
    }
    
}

// MARK: - Light Running Mode

extension MeshCommand {
    
    public struct LightRunningMode {
        
        public enum State: UInt8 {
            
            case stopped = 0x00
            case defaultMode = 0x01
            case customMode = 0x02
        }
        
        public enum DefaultMode: UInt8 {
            
            case colorfulMixed = 0x01
            case redShade = 0x02
            case greenShade = 0x03
            case blueShade = 0x04
            case yellowShade = 0x05
            case cyanShade = 0x06
            case purpleShade = 0x07
            case whiteShade = 0x08
            case redGreenShade = 0x09
            case redBlueShade = 0x0A
            case greenBlueShade = 0x0B
            case colorfulStrobe = 0x0C
            case redStrobe = 0x0D
            case greenStrobe = 0x0E
            case blueStrobe = 0x0F
            case yellowStrobe = 0x10
            case cyanStrobe = 0x11
            case purpleStrobe = 0x12
            case whiteStrobe = 0x13
            case colorfulJump = 0x14
            
            public static let all: [DefaultMode] = (0x01...0x14).map { return DefaultMode(rawValue: $0)! }
        }
        
        public enum CustomMode: UInt8 {
            
            case ascendShade = 0x01
            case descendShade = 0x02
            case ascendDescendShade = 0x03
            case mixedShade = 0x04
            case jump = 0x05
            case strobe = 0x06
            
            public static let all: [CustomMode] = (0x01...0x06).map { CustomMode(rawValue: $0)! }
        }
        
        public struct Color {
            
            public var red: UInt8
            public var green: UInt8
            public var blue: UInt8
            
            public var uiColor: UIColor {
                
                return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
            }
            
            public init(red: UInt8, green: UInt8, blue: UInt8) {
                
                self.red = red
                self.green = green
                self.blue = blue
            }
            
            public init(color: UIColor) {
                
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: nil)
                
                self.red = UInt8(red * 255.0)
                self.green = UInt8(green * 255.0)
                self.blue = UInt8(blue * 255.0)
            }
        }
        
        public var address: Int
        
        public var state: State
        
        public var defaultMode: DefaultMode = .colorfulMixed
        
        public var customMode: CustomMode = .ascendShade
        
        /// range [0x00, 0x0F]
        public var speed: Int = 0x0A
        
        /// range [0x01, 0x10]
        public var customModeId: Int = 0x01
        
        /// It's always empty if you don't change it.
        public var userValues: [String: Any] = [:]
        
        public init(address: Int, state: State) {
            
            self.address = address
            self.state = state
        }
        
        init?(address: Int, userData: Data) {
            
            guard userData[0] == SrIndentifier.lightControlMode.rawValue,
                  userData[1] == SrLightControlMode.getLightRunningMode.rawValue,
                  let state = State(rawValue: userData[4]) else {
                
                return nil
            }
            
            self.address = address
            self.speed = max(0x00, min(0x0F, Int(userData[2])))
            self.state = state
            
            switch state {
            
            case .stopped:
                break
                
            case .defaultMode:
                self.defaultMode = DefaultMode(rawValue: userData[5]) ?? self.defaultMode
                
            case .customMode:
                self.customModeId = max(0x01, min(0x10, Int(userData[5])))
                self.customMode = CustomMode(rawValue: userData[6]) ?? self.customMode
            }
        }
    }
    
    public static func getLightRunningMode(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.getLightRunningMode.rawValue
        return cmd
    }
    
    public static func updateLightRunningMode(_ mode: LightRunningMode) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = mode.address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.setLightRunningMode.rawValue
        cmd.userData[2] = mode.state.rawValue
        
        switch mode.state {
        
        case .stopped:
            break
            
        case .defaultMode:
            cmd.userData[3] = mode.defaultMode.rawValue
            
        case .customMode:
            cmd.userData[3] = UInt8(mode.customModeId)
            cmd.userData[4] = mode.customMode.rawValue
        }
        
        return cmd
    }
    
    /// speed range: [0x00, 0x0F], 0x00 -> fastest, 0x0F -> slowest
    public static func updateLightRunningSpeed(_ address: Int, speed: Int) -> MeshCommand {
        
        assert(speed >= 0x00 && speed <= 0x0F, "speed \(speed) is out of range [0x00, 0x0F]")
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.setLightRunningSpeed.rawValue
        cmd.userData[2] = UInt8(speed)
        return cmd
    }
    
    // cmd.userData[2]
    // 0x00, read custom mode
    // 0x01, add
    // 0x02, remove
    
    public static func getLightRunningCustomModeIdList(_ address: Int) -> MeshCommand {
        
        // 0x00 for mode id list
        return getLightRunningCustomModeColors(address, modeId: 0x00)
    }
    
    /// modeId range [0x01, 0x10]
    public static func getLightRunningCustomModeColors(_ address: Int, modeId: Int) -> MeshCommand {
        
        assert(modeId >= 0x00 && modeId <= 0x10, "modeId out of range [0x00, 0x10]")
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.customLightRunningMode.rawValue
        cmd.userData[2] = 0x00
        cmd.userData[3] = UInt8(modeId)
        return cmd
    }
    
    /// - Parameters:
    ///     - modeId: range [0x01, 0x10]
    ///     - colors: colors.count range [1, 5]
    public static func updateLightRunningCustomModeColors(_ address: Int, modeId: Int, colors: [LightRunningMode.Color]) -> [MeshCommand] {
        
        assert(modeId >= 0x01 && modeId <= 0x10, "modeId out of range [0x00, 0x10]")
        assert(colors.count > 0 && colors.count <= 5, "colors.count out of range [1, 5]")
        
        var commands: [MeshCommand] = []
        
        for i in 0..<colors.count {
            
            let index = i + 1
            let color = colors[i]
            
            var cmd = MeshCommand()
            cmd.tag = .appToNode
            cmd.dst = address
            cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
            cmd.userData[1] = SrLightControlMode.customLightRunningMode.rawValue
            cmd.userData[2] = 0x01
            cmd.userData[3] = UInt8(modeId)
            cmd.userData[4] = UInt8(index)
            cmd.userData[5] = color.red
            cmd.userData[6] = color.green
            cmd.userData[7] = color.blue
            
            commands.append(cmd)
        }
        
        return commands
    }
    
    public static func removeLightRunningCustomModeId(_  address: Int, modeId: Int) -> MeshCommand {
        
        assert(modeId >= 0x01 && modeId <= 0x10, "modeId out of range [0x00, 0x10]")
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.customLightRunningMode.rawValue
        cmd.userData[2] = 0x02
        cmd.userData[3] = UInt8(modeId)
        return cmd
    }
    
}

// MARK: - Groups

extension MeshCommand {
    
    public static func getGroups(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .getGroups
        cmd.dst = address
        cmd.userData[0] = 0x01
        return cmd
    }
    
    public static func getGroupDevices(_ groupId: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .replaceAddress
        cmd.dst = groupId
        cmd.param = 0xFF
        cmd.userData[0] = 0xFF
        return cmd
    }
    
    public static func addGroup(_ groupId: Int, address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .groupAction
        cmd.dst = address
        cmd.param = 0x01
        cmd.userData[0] = UInt8(groupId & 0xFF)
        cmd.userData[1] = 0x80
        return cmd
    }
    
    public static func deleteGroup(_ groupId: Int, address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .groupAction
        cmd.dst = address
        cmd.param = 0x00
        cmd.userData[0] = UInt8(groupId & 0xFF)
        cmd.userData[1] = 0x80
        return cmd
    }
    
}

// MARK: - Advanced Configuration

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
    
    // Light switch type - push button, 3 ways button
    
    public enum LightSwitchType: UInt8 {
        
        case normalOnOff = 0x01
        case pushButton = 0x02
        case threeChannels = 0x03
    }
    
    public static func setLightSwitchType(_ address: Int, switchType: LightSwitchType) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightSwitchType.rawValue
        cmd.userData[1] = 0x01 // set
        cmd.userData[2] = switchType.rawValue
        return cmd
    }
    
    public static func getLightSwitchType(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightSwitchType.rawValue
        cmd.userData[1] = 0x00 // get
        return cmd
    }
    
    // Pwm frequency
    
    /// - Parameter frequency: Range `[500, 10_000]`, unit `Hz`.
    public static func setLightPwmFrequency(_ address: Int, frequency: Int) -> MeshCommand {
                
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.lightPwmFrequency.rawValue
        cmd.userData[2] = 0x01 // set
        cmd.userData[3] = UInt8(frequency & 0xFF)
        cmd.userData[4] = UInt8((frequency >> 8) & 0xFF)
        return cmd
    }
    
    public static func getLightPwmFrequency(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.lightPwmFrequency.rawValue
        cmd.userData[2] = 0x00 // get
        return cmd
    }
    
    // Enable pairing
    
    /// The device enters pairing mode for 5 seconds after receiving this command.
    public static func enablePairing(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.special.rawValue
        cmd.userData[1] = 0x01 // enable pairing
        return cmd
    }
    
    // Enable rgb independence
    
    /// If `true`, the other channels will be closed when change the RGB,
    /// the RGB will be closed when change the other channels.
    public static func setRgbIndependence(_ address: Int, isEnabled: Bool) -> MeshCommand {
                
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.channelMode.rawValue
        cmd.userData[2] = 0x04 // RGB independence
        cmd.userData[3] = 0x01 // set
        cmd.userData[4] = isEnabled ? 0x01 : 0x00
        return cmd
    }
    
    public static func getRgbIndependence(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.lightControlMode.rawValue
        cmd.userData[1] = SrLightControlMode.channelMode.rawValue
        cmd.userData[2] = 0x04 // RGB independence
        cmd.userData[3] = 0x00 // get 
        return cmd
    }
    
    // Sensor configuration
    
    // Smart switch configuration
    
}

// MARK: - Sunrise & Sunset

public enum SunriseSunsetType: UInt8 {
    
    case sunrise = 0x1C
    case sunset = 0x1D
}

public enum SunriseSunsetActionType: UInt8 {
    
    case onOff = 0x01
    case scene = 0x02
    case custom = 0x04
}

public protocol SunriseSunsetAction {
    
    var type: SunriseSunsetType { get set }
    
    var actionType: SunriseSunsetActionType { get }
    
    var isEnabled: Bool { get set }
    
    var description: String { get }
}

public struct SunriseSunsetOnOffAction: SunriseSunsetAction {
    
    public var type: SunriseSunsetType
    
    public let actionType: SunriseSunsetActionType = .onOff
    
    /// Default true
    public var isEnabled: Bool = true
    
    /// Default true
    public var isOn: Bool = true
    
    /// Range [0x0000, 0xFFFF], default 0
    public var duration: Int = 0
    
    public init(type: SunriseSunsetType) {
        self.type = type
    }
    
    public var description: String {
        
        return "OnOffAction \(type), isEnabled \(isEnabled), isOn \(isOn), duration \(duration)"
    }
}

public struct SunriseSunsetSceneAction: SunriseSunsetAction {
    
    public var type: SunriseSunsetType
    
    public let actionType: SunriseSunsetActionType = .scene
    
    /// Default rue
    public var isEnabled: Bool = true
    
    /// Range [1, 16], default 1
    public var sceneID: Int = 1
    
    public init(type: SunriseSunsetType) {
        self.type = type
    }
    
    public var description: String {
        
        return "SceneAction \(type), isEnabled \(isEnabled), sceneID \(sceneID)"
    }
}

public struct SunriseSunsetCustomAction: SunriseSunsetAction {
    
    public var type: SunriseSunsetType
    
    public let actionType: SunriseSunsetActionType = .custom
    
    /// Default true
    public var isEnabled: Bool = true
    
    /// Range [0, 100], default 100
    public var brightness: Int = 100
    
    /// Range [0, 255], default 255
    public var red: Int = 255
    
    /// Range [0, 255], default 255
    public var green: Int = 255
    
    /// Range [0, 255], default 255
    public var blue: Int = 255
    
    /// CT range [0, 100], White range [0, 255], default 100
    public var ctOrW: Int = 100
    
    /// Range [0x0000, 0xFFFF], default 0
    public var duration: Int = 0
    
    public init(type: SunriseSunsetType) {
        self.type = type
    }
    
    public var description: String {
        
        return "CustomAction \(type), isEnabled \(isEnabled), Brightness \(brightness), RGBW \(red) \(green) \(blue) \(ctOrW), duration \(duration)"
    }
}

extension MeshCommand {
    
    /// Only support single device address, don't use `0xFFFF` or `0x8---` as a adress.
    /// If it's East area, `isNegative = false`, else `isNegative = true`.
    public static func setTimezone(_ address: Int, hour: Int, minute: Int, isNegative: Bool) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.timezone.rawValue
        cmd.userData[1] = 0x01 // set
        cmd.userData[2] = UInt8(abs(hour)) | (isNegative ? 0x80 : 0x00)
        cmd.userData[3] = UInt8(minute)
        return cmd
    }
    
    public static func getTimezone(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.timezone.rawValue
        cmd.userData[1] = 0x00 // get
        return cmd
    }
    
    /// Only suuport single device address, don't use `0xFFFF` or `0x8---` as a adress.
    public static func setLocation(_ address: Int, longitude: Float, latitude: Float) -> MeshCommand {
        
        // 1-4
        let longitudeData = longitude.data
        // 5-8
        let latitudeData = latitude.data
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.setLocation.rawValue
        cmd.userData[1] = longitudeData[0]
        cmd.userData[2] = longitudeData[1]
        cmd.userData[3] = longitudeData[2]
        cmd.userData[4] = longitudeData[3]
        cmd.userData[5] = latitudeData[0]
        cmd.userData[6] = latitudeData[1]
        cmd.userData[7] = latitudeData[2]
        cmd.userData[8] = latitudeData[3]
        return cmd
    }
    
    public static func getLocation(_ address: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = SrIndentifier.getLocation.rawValue
        return cmd
    }
    
    public static func getSunriseSunset(_ address: Int, type: SunriseSunsetType) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = type.rawValue
        return cmd
    }
    
    public static func setSunriseSunsetAction(_ address: Int, action: SunriseSunsetAction) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = action.type.rawValue
        cmd.userData[1] = action.actionType.rawValue | (action.isEnabled ? 0x00 : 0x80)
        
        switch action.actionType {
            
        case .onOff:
            
            guard let onOffAction = action as? SunriseSunsetOnOffAction else { return cmd }
            cmd.userData[2] = onOffAction.isOn ? 0x01 : 0x00
            cmd.userData[3] = 0x00
            cmd.userData[4] = 0x00
            cmd.userData[5] = 0x00
            cmd.userData[6] = UInt8(onOffAction.duration & 0xFF)
            cmd.userData[7] = UInt8((onOffAction.duration >> 8) & 0xFF)
            cmd.userData[8] = 0x00 // light endpoint bit, unsupport now
            
        case .scene:
            
            guard let sceneAction = action as? SunriseSunsetSceneAction else { return cmd }
            cmd.userData[2] = UInt8(sceneAction.sceneID)
            
        case .custom:
            
            guard let customAction = action as? SunriseSunsetCustomAction else { return cmd }
            cmd.userData[2] = UInt8(customAction.brightness)
            cmd.userData[3] = UInt8(customAction.red)
            cmd.userData[4] = UInt8(customAction.green)
            cmd.userData[5] = UInt8(customAction.blue)
            cmd.userData[6] = UInt8(customAction.ctOrW)
            cmd.userData[7] = UInt8(customAction.duration & 0xFF)
            cmd.userData[8] = UInt8((customAction.duration >> 8) & 0xFF)
        }
        
        return cmd
    }
    
    public static func clearSunriseSunsetContent(_ address: Int, type: SunriseSunsetType) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = type.rawValue
        cmd.userData[1] = 0xC0 // clear
        return cmd
    }
    
    public static func enableSunriseSunset(_ address: Int, type: SunriseSunsetType, isEnabled: Bool) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .appToNode
        cmd.dst = address
        cmd.userData[0] = type.rawValue
        cmd.userData[1] = isEnabled ? 0xE0 : 0xF0 // enable 0xE0, disable 0xF0
        return cmd
    }
    
}

// MARK: - Scenes

extension MeshCommand {
    
    public struct Scene {
        
        public var sceneID: Int
        
        /// Range [0, 100], if `brightness = 0` means `power off`.
        public var brightness: Int = 100
        
        /// Range [0, 255]
        public var red: Int = 255
        
        /// Range [0, 255]
        public var green: Int = 255
        
        /// Range [0, 255]
        public var blue: Int = 255
        
        /// CCT range [0, 100], White range [0, 255]
        public var ctOrW = 100
        
        /// Range [0, 65535]
        public var duration: Int = 0
        
        public init(sceneID: Int) {
            
            self.sceneID = sceneID
        }
    }
    
    public static func addOrUpdateScene(_ address: Int, scene: Scene) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .scene
        cmd.dst = address
        cmd.param = 0x01 // add
        cmd.userData[0] = UInt8(scene.sceneID)
        cmd.userData[1] = UInt8(scene.brightness)
        cmd.userData[2] = UInt8(scene.red)
        cmd.userData[3] = UInt8(scene.green)
        cmd.userData[4] = UInt8(scene.blue)
        cmd.userData[5] = UInt8(scene.ctOrW)
        cmd.userData[6] = UInt8(scene.duration & 0xFF)
        cmd.userData[7] = UInt8(scene.duration >> 8)
        return cmd
    }
    
    public static func deleteScene(_ address: Int, sceneID: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .scene
        cmd.dst = address
        cmd.param = 0x00 // delete
        cmd.userData[0] = UInt8(sceneID)
        return cmd
    }
    
    public static func clearScenes(_ address: Int) -> MeshCommand {
        
        return deleteScene(address, sceneID: 0xFF)
    }
    
    public static func loadScene(_ address: Int, sceneID: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .loadScene
        cmd.dst = address
        cmd.param = sceneID
        return cmd
    }
    
    /// The `address` must be a device address. sceneID range [1, 16]
    public static func getSceneDetail(_ address: Int, sceneID: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .getScene
        cmd.dst = address
        cmd.userData[0] = UInt8(sceneID)
        return cmd
    }
    
}

// MARK: - Alarm

public enum AlarmActionType: UInt8 {
    
    case off = 0
    case on = 1
    case scene = 2
}

public enum AlarmDayType: UInt8 {
    
    case day = 0
    case week = 1
}

public protocol AlarmProtocol {
    
    var alarmID: Int { get set }
    
    var actionType: AlarmActionType { get set }
    
    var dayType: AlarmDayType { get }
    
    var isEnabled: Bool { get set }
    
    var hour: Int { get set }
    
    var minute: Int { get set }
    
    var second: Int { get set }
    
    var sceneID: Int { get set }
}

extension AlarmProtocol {
    
    var alarmEvent: UInt8 {
        
        return actionType.rawValue
            | (dayType.rawValue << 4)
            | UInt8(isEnabled ? 0x80 : 0x00)
    }
}

public struct DayAlarm: AlarmProtocol {
    
    public var alarmID: Int
    
    public var actionType: AlarmActionType = .off
    
    public let dayType: AlarmDayType = .day
    
    public var isEnabled: Bool = true
    
    public var hour: Int = 10
    
    public var minute: Int = 10
    
    public var second: Int = 0
    
    public var sceneID: Int = 0
    
    public var month: Int = 1
    
    public var day: Int = 1
    
    public init(alarmID: Int) {
        self.alarmID = alarmID
    }
    
}

public struct WeekAlarm: AlarmProtocol {
    
    public var alarmID: Int
    
    public var actionType: AlarmActionType = .off
    
    public let dayType: AlarmDayType = .week
    
    public var isEnabled: Bool = true
    
    public var hour: Int = 10
    
    public var minute: Int = 10
    
    public var second: Int = 0
    
    public var sceneID: Int = 0
    
    /// bit0 Sun, bit1 Mon, bit2 Tue, bit3 Wed, bit4 Thu, bit5 Fri, bit6 Sat,
    /// bit7 must be 0.
    public var week: Int = 0
    
    public init(alarmID: Int) {
        self.alarmID = alarmID
    }
}

extension MeshCommand {
    
    static func makeAlarm(_ command: MeshCommand) -> AlarmProtocol? {
        
        // 0xA5 is valid alarm
        guard command.param == 0xA5 else { return nil }
        let alarmID = Int(command.userData[0])
        guard alarmID > 0 && alarmID <= 16 else { return nil }
        
        let event = Int(command.userData[1])
        // bit0~bit3, 0 off, 1 on, 2 scene
        guard let actionType = AlarmActionType(rawValue: UInt8(event & 0b1111)) else { return nil }
        // bit4~bit6 0 day, 1 week
        guard let dayType = AlarmDayType(rawValue: UInt8((event & 0b0111_0000) >> 4)) else { return nil }
        let isEnabled = (event & 0x80) == 0x80
        let hour = Int(command.userData[4])
        let minute = Int(command.userData[5])
        let second = Int(command.userData[6])
        let sceneID = Int(command.userData[7])
        
        var alarm: AlarmProtocol?
        
        switch dayType {
        case .day:
            
            let month = Int(command.userData[2])
            guard month > 0 && month <= 12 else { return nil }
            let day = Int(command.userData[3])
            
            var dayAlarm = DayAlarm(alarmID: alarmID)
            dayAlarm.actionType = actionType
            dayAlarm.isEnabled = isEnabled
            dayAlarm.hour = hour
            dayAlarm.minute = minute
            dayAlarm.second = second
            dayAlarm.sceneID = sceneID
            dayAlarm.month = month
            dayAlarm.day = day
            
            alarm = dayAlarm
            
        case .week:
            
            let week = Int(command.userData[3]) & 0x7F
            
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
        
        return alarm
    }
}

extension MeshCommand {
    
    // The `alarmID = 0` means get all alarms of the device.
    public static func getAlarm(_ address: Int, alarmID: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .getAlarm
        cmd.dst = address
        cmd.userData[0] = UInt8(alarmID)
        return cmd
    }
    
    /// Note: `alarm.alarmID` will be set to `0x00`, the device will automatically
    /// set the new `alarmID`.
    public static func addAlarm(_ address: Int, alarm: AlarmProtocol) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .editAlarm
        cmd.dst = address
        cmd.param = 0x00 // add
        cmd.userData[0] = 0x00 // automatically set alarmID
        cmd.userData[1] = alarm.alarmEvent
        
        // 2 day.month
        // 3 day.day, week.week
        if alarm.dayType == .day, let dayAlarm = alarm as? DayAlarm {
            
            cmd.userData[2] = UInt8(dayAlarm.month)
            cmd.userData[3] = UInt8(dayAlarm.day)
            
        } else if alarm.dayType == .week, let weekAlarm = alarm as? WeekAlarm {
            
            cmd.userData[3] = UInt8(weekAlarm.week & 0x7F)
        }
        
        cmd.userData[4] = UInt8(alarm.hour)
        cmd.userData[5] = UInt8(alarm.minute)
        cmd.userData[6] = UInt8(alarm.second)
        cmd.userData[7] = UInt8(alarm.sceneID)
        return cmd
    }
    
    public static func enableAlarm(_ address: Int, alarmID: Int, isEnabled: Bool) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .editAlarm
        cmd.dst = address
        // enable 0x03, disable 0x04
        cmd.param = isEnabled ? 0x03 : 0x04
        cmd.userData[0] = UInt8(alarmID)
        return cmd
    }
    
    public static func deleteAlarm(_ address: Int, alarmID: Int) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .editAlarm
        cmd.dst = address
        cmd.param = 0x01 // delete
        cmd.userData[0] = UInt8(alarmID)
        return cmd
    }
    
    public static func updateAlarm(_ address: Int, alarm: AlarmProtocol) -> MeshCommand {
        
        var cmd = MeshCommand()
        cmd.tag = .editAlarm
        cmd.dst = address
        cmd.param = 0x02 // update
        cmd.userData[0] = UInt8(alarm.alarmID)
        cmd.userData[1] = alarm.alarmEvent
        
        // 2 day.month
        // 3 day.day, week.week
        if alarm.dayType == .day, let dayAlarm = alarm as? DayAlarm {
            
            cmd.userData[2] = UInt8(dayAlarm.month)
            cmd.userData[3] = UInt8(dayAlarm.day)
            
        } else if alarm.dayType == .week, let weekAlarm = alarm as? WeekAlarm {
            
            cmd.userData[3] = UInt8(weekAlarm.week & 0x7F)
        }
        
        cmd.userData[4] = UInt8(alarm.hour)
        cmd.userData[5] = UInt8(alarm.minute)
        cmd.userData[6] = UInt8(alarm.second)
        cmd.userData[7] = UInt8(alarm.sceneID)
        return cmd
    }
    
}

// MARK: - Remotes

extension MeshCommand {
    
    /// The `groups.count <= 4`, the `groups[x]` range is [1, 254].
    public static func setRemoteGroups(_ address: Int, groups: [Int]) -> MeshCommand {
        
        return setRemoteGroups(address, groups: groups, isLeading: true, isEnd: true)
    }
    
    /// The `groups.count <= 4`, the `groups[x]` range is [1, 254].
    private static func setRemoteGroups(_ address: Int, groups: [Int], isLeading: Bool, isEnd: Bool) -> MeshCommand {
        
        let tempGroups = (groups.filter{ $0 > 0 && $0 <= 254 }).sorted()
        
        var cmd = MeshCommand()
        cmd.tag = .setRemoteGroups
        cmd.dst = address
        cmd.param = 0x00
        cmd.userData[0] = 0x80
        cmd.userData[1] = 0x00
        cmd.userData[2] = 0x80
        cmd.userData[3] = 0x00
        cmd.userData[4] = 0x80
        cmd.userData[5] = 0x00
        cmd.userData[6] = 0x80
        cmd.userData[7] = isLeading ? 0x01 : 0x02 // leading groups 4
        cmd.userData[8] = isEnd ? 0x00 : 0x01
        
        for (index, group) in tempGroups.enumerated() {
            
            let dataIndex = index * 2
            
            if index > 3 { break }
            if group <= 0 || group >= 254 { continue }
            
            if index == 0 {
                
                cmd.param = group
                cmd.userData[dataIndex] = 0x80
                
            } else {
                
                cmd.userData[dataIndex - 1] = UInt8(group)
                cmd.userData[dataIndex] = 0x80
            }
        }
        
        return cmd
    }
    
    public static func getRemoteGroups(_ address: Int, isLeading: Bool = true) -> MeshCommand {
        
        // GET_SW_GRP
        
        var cmd = MeshCommand()
        cmd.tag = .getGroups
        cmd.dst = address
        cmd.userData[0] = isLeading ? 0x02 : 0x03
        return cmd
    }
    
}
