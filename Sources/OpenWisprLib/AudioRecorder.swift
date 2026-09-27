import CoreAudio
import Foundation

class AudioRecorder {
    private let queue = DispatchQueue(label: "OpenWispr.AudioRecorder", qos: .userInitiated)
    private var capture: AudioCaptureUnit?
    private var currentOutputURL: URL?
    private var selectedDeviceID: AudioDeviceID?
    private var selectedVoiceProcessing = false

    var preferredDeviceID: AudioDeviceID? {
        get { queue.sync { selectedDeviceID } }
        set { queue.async { self.selectedDeviceID = newValue } }
    }

    var voiceProcessingEnabled: Bool {
        get { queue.sync { selectedVoiceProcessing } }
        set { queue.async { self.selectedVoiceProcessing = newValue } }
    }

    func prepare() {
        queue.async {
            guard self.currentOutputURL == nil else { return }
            // Инициализированный блок ввода может удерживать Bluetooth-наушники в режиме гарнитуры.
            // Определяем текущий маршрут звука только в начале записи.
            self.capture = nil
        }
    }

    func teardown() {
        queue.sync {
            capture = nil
            currentOutputURL = nil
        }
    }

    private func configuredCapture() throws -> AudioCaptureUnit {
        let defaultInput = AudioDeviceManager.getDefaultInputDeviceID()
        let route = AudioEngineCacheState.Route(
            inputDeviceID: selectedDeviceID ?? defaultInput,
            outputDeviceID: AudioDeviceManager.getDefaultOutputDeviceID(),
            defaultInputDeviceID: defaultInput
        )
        if let capture, capture.cacheState.canReuse(for: route) { return capture }
        capture = nil
        let startedAt = DispatchTime.now().uptimeNanoseconds
        // VoiceProcessingIO привязывает устройство вывода и может медленно запускаться.
        // Стандартный путь HAL захватывает только вход и не удерживает устройство воспроизведения.
        let useVoiceProcessing: Bool
        if #available(macOS 14.0, *) { useVoiceProcessing = selectedVoiceProcessing }
        else { useVoiceProcessing = false }
        let configured = try AudioCaptureUnit(route: route, voiceProcessing: useVoiceProcessing)
        capture = configured
        print("Подготовка звука: \((DispatchTime.now().uptimeNanoseconds - startedAt) / 1_000_000) мс; вход=\(route.inputDeviceID), выход=\(route.outputDeviceID)")
        return configured
    }

    func startRecording(to outputURL: URL) throws {
        let requestedAt = DispatchTime.now().uptimeNanoseconds
        try queue.sync {
            guard currentOutputURL == nil else { return }
            do {
                let capture = try configuredCapture()
                try capture.start(to: outputURL, requestedAt: requestedAt)
                currentOutputURL = outputURL
                print("Микрофон готов через \((DispatchTime.now().uptimeNanoseconds - requestedAt) / 1_000_000) мс (обработка голоса: \(capture.voiceProcessing ? "включена" : "выключена"))")
            } catch {
                capture = nil
                throw error
            }
        }
    }

    func stopRecording() -> URL? {
        queue.sync {
            guard let url = currentOutputURL else { return nil }
            currentOutputURL = nil
            defer { capture = nil }
            do {
                try capture?.stop()
                return url
            } catch {
                try? FileManager.default.removeItem(at: url)
                print("Ошибка записи: \(error.localizedDescription)")
                return nil
            }
        }
    }
}
