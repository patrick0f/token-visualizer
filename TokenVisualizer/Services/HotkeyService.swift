import Carbon
import AppKit

final class HotkeyService {
    static let shared = HotkeyService()

    private var hotKeyRef: EventHotKeyRef?
    private static var action: (() -> Void)?

    func register(action: @escaping () -> Void) {
        Self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            HotkeyService.action?()
            return noErr
        }, 1, &eventType, nil, nil)

        // Cmd+Shift+T
        let hotKeyID = EventHotKeyID(signature: OSType(0x5456_495A), id: 1) // "TVIZ"
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 17 // 't'

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}
