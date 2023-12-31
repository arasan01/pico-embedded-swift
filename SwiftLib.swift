import PicoWI

extension StaticString {
    var cString: UnsafeMutablePointer<CChar> {
        UnsafeMutableRawPointer(mutating: utf8Start).assumingMemoryBound(to: CChar.self)
    }
}

let ssid = "" as StaticString
let wifiPass = "" as StaticString
let serverName = "apple.com" as StaticString
var ledTicks: UInt32 = 0

@_cdecl("swiftlib_swiftMain")
public func swiftMain() {
    io_init()

    for _ in 0..<10 {
        usdelay(1_000_000)   
        print("Waiting") // Used so we can connect serial in time
    }

    guard net_init() > 0 && net_join(ssid.cString, wifiPass.cString) > 0 else {
        printLoop("WiFi setup failed")
    }

    set_display_mode(DISP_INFO | DISP_JOIN | DISP_ARP | DISP_DHCP)

    var led = false

    ustimeout(&ledTicks, 0)

    while true {
        net_event_poll()
        net_state_poll()
        tcp_socks_poll()

        let ledDelay: Int32 = link_check() > 0 ? 1_000_000 : 100_000
        if ustimeout(&ledTicks, ledDelay) != 0 {
            led.toggle()
            wifi_set_led(led)
        }
    }    
}

func printLoop(_ string: StaticString) -> Never {
    while true {
        print(string)
        usdelay(1_000_000)
    }
}