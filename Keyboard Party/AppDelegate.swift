import Cocoa

enum PartyMode: Int, RawRepresentable {
    case Off, Typing, Sound
    
    static let allItems: [PartyMode] = [.Off, .Typing, .Sound]
    
    var name: String {
        get {
            switch self {
            case Off: return "Off"
            case Typing: return "Typing"
            case Sound: return "Sound"
            }
        }
    }
    
    func makeParty() -> KeyboardParty? {
        switch self {
        case Off: return nil
        case Typing: return TypingKeyboardParty()
        case Sound: return SoundKeyboardParty()
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(30)
    
    @IBOutlet var statusMenu: NSMenu?
    @IBOutlet var partySeparator: NSMenuItem?
    
    var party: KeyboardParty? = nil
    var partyMenuItems: [PartyMode: NSMenuItem] = [:]
    
    var mode: PartyMode = .Off {
        willSet {
            partyMenuItems[mode]!.state = NSOffState
        }
        didSet {
            partyMenuItems[mode]!.state = NSOnState
            party = mode.makeParty()
            NSUserDefaults.standardUserDefaults().setInteger(mode.rawValue, forKey: "Mode")
            statusItem.button?.appearsDisabled = mode == .Off
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        for partyMode in PartyMode.allItems {
            let menuItem = NSMenuItem(title: partyMode.name, action: "changeParty:", keyEquivalent: "")
            menuItem.tag = partyMode.rawValue
            menuItem.target = self
            statusMenu!.insertItem(menuItem, atIndex: statusMenu!.indexOfItem(partySeparator!))
            partyMenuItems[partyMode] = menuItem
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.registerDefaults([
            "Mode": PartyMode.Sound.rawValue
        ])
        
        let statusImage = NSImage(named: "Menu")
        statusImage!.size = NSSize(width: statusImage!.size.width / statusImage!.size.height * 18, height: 18)
        
        statusItem.image = statusImage
        statusItem.menu = statusMenu
        
        if let savedMode = PartyMode(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("Mode")) {
            mode = savedMode
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        party = nil
    }
    
    // MARK: Actions
    
    func changeParty(sender: NSMenuItem) {
        mode = PartyMode(rawValue: sender.tag)!
    }
    
}

func appDelegate() -> AppDelegate {
    return NSApplication.sharedApplication().delegate as AppDelegate
}