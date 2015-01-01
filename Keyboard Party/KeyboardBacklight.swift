import IOKit

enum KeyboardBacklightCommand: UInt32, RawRepresentable {
    case GetSensorReading
    case GetLEDBrightness
    case SetLEDBrightness
    case SetLEDFade
}

class KeyboardBacklight {
    
    let connect: mach_port_t
    
    init() {
        let serviceObject = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleLMUController").takeUnretainedValue())
        assert(serviceObject != 0, "Failed to get service object")
        
        connect = 0
        let status = IOServiceOpen(serviceObject, mach_task_self_, 0, &connect)
        assert(status == KERN_SUCCESS, "Failed to open IO service")
    }
    
    func get() -> UInt64 {
        let input: [UInt64] = [0]
        var output: UInt64 = 0
        var outputCount: UInt32 = 1
        
        let status = IOConnectCallMethod(
            connect, KeyboardBacklightCommand.GetLEDBrightness.rawValue,
            input, UInt32(1),
            nil, 0,
            &output, &outputCount,
            nil, nil
        )
        assert(status == KERN_SUCCESS, "Failed to set brightness")
        return output
    }
    
    func set(brightness: UInt64) {
        let input: [UInt64] = [0, brightness]
        var output: UInt64 = 0
        var outputCount: UInt32 = 1
        
        let status = IOConnectCallMethod(
            connect, KeyboardBacklightCommand.SetLEDBrightness.rawValue,
            input, UInt32(countElements(input)),
            nil, 0,
            &output, &outputCount,
            nil, nil
        )
        assert(status == KERN_SUCCESS, "Failed to set brightness")
    }
    
    func fade(brightness: UInt64, duration: UInt64) {
        let input: [UInt64] = [0, brightness, duration]
        var output: UInt64 = 0
        var outputCount: UInt32 = 1
        
        let status = IOConnectCallMethod(
            connect, KeyboardBacklightCommand.SetLEDFade.rawValue,
            input, UInt32(countElements(input)),
            nil, 0,
            &output, &outputCount,
            nil, nil
        )
        assert(status == KERN_SUCCESS, "Failed to set fade")
    }
}