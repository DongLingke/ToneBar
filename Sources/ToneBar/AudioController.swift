import AppKit
import CoreAudio

/// Thin wrapper around CoreAudio for reading/writing the default output
/// device's volume + mute state, and observing external changes (so the
/// menu-bar slider stays in sync when the user uses media keys, etc.).
final class AudioController: ObservableObject {

    @Published var volume: Double = 0.5
    @Published var muted: Bool = false
    @Published var deviceName: String = ""

    private let systemObject = AudioObjectID(kAudioObjectSystemObject)
    private var deviceID = AudioObjectID(kAudioObjectUnknown)

    /// Whether the device exposes a single master volume channel (element 0).
    private var hasMasterVolume = false
    /// Fallback per-channel elements used when there is no master channel.
    private let fallbackChannels: [AudioObjectPropertyElement] = [1, 2]

    /// Active listeners so we can detach them when the device changes.
    private var listeners: [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []

    init() {
        startSystemListener()
        refreshDevice()
    }

    // MARK: - Address helper

    private func addr(_ selector: AudioObjectPropertySelector,
                      _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                      _ element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain)
        -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
    }

    // MARK: - Device selection

    /// Re-resolve the default output device and rebuild its listeners.
    func refreshDevice() {
        var a = addr(kAudioHardwarePropertyDefaultOutputDevice)
        var dev = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(systemObject, &a, 0, nil, &size, &dev)
        guard status == noErr, dev != kAudioObjectUnknown else { return }

        detachDeviceListeners()
        deviceID = dev
        configureVolumeChannels()
        attachDeviceListeners()
        deviceName = readDeviceName()
        reload()
    }

    private func configureVolumeChannels() {
        var master = addr(kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeOutput)
        hasMasterVolume = AudioObjectHasProperty(deviceID, &master)
    }

    private func readDeviceName() -> String {
        var a = addr(kAudioObjectPropertyName)
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(deviceID, &a, 0, nil, &size, &name) == noErr,
              let cf = name?.takeRetainedValue() else { return "" }
        return cf as String
    }

    // MARK: - Read

    /// Pull the current hardware state into the published properties.
    func reload() {
        volume = readVolume()
        muted = readMute()
    }

    private func readVolume() -> Double {
        if hasMasterVolume {
            return scalar(element: kAudioObjectPropertyElementMain) ?? volume
        }
        let values = fallbackChannels.compactMap { scalar(element: $0) }
        guard !values.isEmpty else { return volume }
        return values.reduce(0, +) / Double(values.count)
    }

    private func scalar(element: AudioObjectPropertyElement) -> Double? {
        var a = addr(kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeOutput, element)
        var value = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        guard AudioObjectGetPropertyData(deviceID, &a, 0, nil, &size, &value) == noErr else { return nil }
        return Double(value)
    }

    private func readMute() -> Bool {
        var a = addr(kAudioDevicePropertyMute, kAudioDevicePropertyScopeOutput)
        guard AudioObjectHasProperty(deviceID, &a) else { return false }
        var m = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(deviceID, &a, 0, nil, &size, &m) == noErr else { return false }
        return m != 0
    }

    // MARK: - Write

    func setVolume(_ value: Double) {
        let clamped = max(0, min(1, value))
        // Nudging the slider off zero should also lift mute, matching macOS.
        if muted && clamped > 0 { setMute(false) }

        if hasMasterVolume {
            writeScalar(Float32(clamped), element: kAudioObjectPropertyElementMain)
        } else {
            for ch in fallbackChannels { writeScalar(Float32(clamped), element: ch) }
        }
        volume = clamped
    }

    private func writeScalar(_ value: Float32, element: AudioObjectPropertyElement) {
        var a = addr(kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeOutput, element)
        guard isSettable(&a) else { return }
        var v = value
        AudioObjectSetPropertyData(deviceID, &a, 0, nil, UInt32(MemoryLayout<Float32>.size), &v)
    }

    func setMute(_ on: Bool) {
        var a = addr(kAudioDevicePropertyMute, kAudioDevicePropertyScopeOutput)
        guard AudioObjectHasProperty(deviceID, &a), isSettable(&a) else { return }
        var m = UInt32(on ? 1 : 0)
        AudioObjectSetPropertyData(deviceID, &a, 0, nil, UInt32(MemoryLayout<UInt32>.size), &m)
        muted = on
    }

    func toggleMute() { setMute(!muted) }

    /// Bump volume by a delta (used by scroll-to-adjust).
    func nudge(by delta: Double) {
        setVolume(volume + delta)
    }

    private func isSettable(_ a: inout AudioObjectPropertyAddress) -> Bool {
        var settable: DarwinBoolean = false
        guard AudioObjectIsPropertySettable(deviceID, &a, &settable) == noErr else { return false }
        return settable.boolValue
    }

    // MARK: - Listeners

    private func startSystemListener() {
        var a = addr(kAudioHardwarePropertyDefaultOutputDevice)
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            DispatchQueue.main.async { self?.refreshDevice() }
        }
        AudioObjectAddPropertyListenerBlock(systemObject, &a, DispatchQueue.main, block)
    }

    private func attachDeviceListeners() {
        let reloadBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            DispatchQueue.main.async { self?.reload() }
        }
        // Master + common per-channel elements + mute.
        let elements: [AudioObjectPropertyElement] = [kAudioObjectPropertyElementMain, 1, 2]
        for element in elements {
            register(addr(kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeOutput, element), reloadBlock)
        }
        register(addr(kAudioDevicePropertyMute, kAudioDevicePropertyScopeOutput), reloadBlock)
    }

    private func register(_ address: AudioObjectPropertyAddress, _ block: @escaping AudioObjectPropertyListenerBlock) {
        var a = address
        guard AudioObjectHasProperty(deviceID, &a) else { return }
        if AudioObjectAddPropertyListenerBlock(deviceID, &a, DispatchQueue.main, block) == noErr {
            listeners.append((deviceID, address, block))
        }
    }

    private func detachDeviceListeners() {
        for (obj, address, block) in listeners {
            var a = address
            AudioObjectRemovePropertyListenerBlock(obj, &a, DispatchQueue.main, block)
        }
        listeners.removeAll()
    }
}
