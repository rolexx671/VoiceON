import Foundation

public class Transcriber {
    private let modelSize: String
    private let language: String
    private let whisperPrompt: String?
    private let vadEnabled: Bool
    private let vadThreshold: Double
    public var spokenPunctuation: Bool = false
    public var customDictionary: [DictionaryEntry] = []

    public init(modelSize: String = "base", language: String = "ru", whisperPrompt: String? = nil,
                vadEnabled: Bool = false, vadThreshold: Double = 0.5) {
        self.modelSize = modelSize
        self.language = language
        self.whisperPrompt = whisperPrompt
        self.vadEnabled = vadEnabled
        self.vadThreshold = vadThreshold
    }

    public func transcribe(audioURL: URL) throws -> String {
        guard let whisperPath = Transcriber.findWhisperBinary() else {
            throw TranscriberError.whisperNotFound
        }

        guard let modelPath = Transcriber.findModel(modelSize: modelSize) else {
            throw TranscriberError.modelNotFound(modelSize)
        }

        let vadModelPath: String?
        if vadEnabled {
            guard let path = Transcriber.findVADModel() else { throw TranscriberError.vadModelNotFound }
            vadModelPath = path
        } else {
            vadModelPath = nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: whisperPath)
        process.arguments = arguments(modelPath: modelPath, audioURL: audioURL, vadModelPath: vadModelPath)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        var stderrData = Data()
        let stderrThread = Thread {
            stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        }
        stderrThread.start()

        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        while !stderrThread.isFinished { Thread.sleep(forTimeInterval: 0.01) }
        process.waitUntilExit()

        let output = Transcriber.stripWhisperMarkers(
            String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )

        if process.terminationStatus != 0 {
            let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !stderr.isEmpty { fputs("whisper-cpp: \(stderr)\n", Foundation.stderr) }
            throw TranscriberError.transcriptionFailed
        }

        return output
    }

    func arguments(modelPath: String, audioURL: URL, vadModelPath: String? = nil) -> [String] {
        var args = [
            "-m", modelPath,
            "-f", audioURL.path,
            "-l", language,
            "-nt",
            // Отключаем перенос контекста между фрагментами. whisper.cpp передаёт
            // распознанный текст каждого 30-секундного фрагмента в следующий;
            // при длинной диктовке это может вызывать повторы и выдуманный текст
            // (предложения повторяются, затем обрываются).
            // max-context 0 распознаёт каждый фрагмент независимо и предотвращает повторы.
            "-mc", "0",
        ]
        let dictionaryPrompt = DictionaryPostProcessor.buildPrompt(from: customDictionary)
        let prompt = [effectiveWhisperPrompt, dictionaryPrompt.isEmpty ? nil : dictionaryPrompt]
            .compactMap { $0 }
            .joined(separator: " ")
        if !prompt.isEmpty {
            args += ["--prompt", prompt]
        }
        if spokenPunctuation {
            args += ["--suppress-regex", "[,\\.\\?!;:\\-—]"]
        }
        if vadEnabled, let vadModelPath {
            args += ["--vad", "--vad-model", vadModelPath,
                     "--vad-threshold", String(vadThreshold)]
        }

        return args
    }

    private var effectiveWhisperPrompt: String? {
        guard let whisperPrompt else { return nil }
        return whisperPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : whisperPrompt
    }

    private static let knownMarkers: Set<String> = [
        "BLANK_AUDIO", "blank_audio",
        "Music", "MUSIC", "music",
        "Applause", "APPLAUSE", "applause",
        "Laughter", "LAUGHTER", "laughter",
        "silence", "Silence", "SILENCE",
        "SOUND", "Sound", "sound",
        "NOISE", "Noise", "noise",
        "INAUDIBLE", "inaudible",
        "Музыка", "музыка", "МУЗЫКА",
        "Аплодисменты", "аплодисменты", "Смех", "смех",
        "Тишина", "тишина", "Шум", "шум", "Неразборчиво", "неразборчиво",
    ]

    private static let markerRegex = try! NSRegularExpression(
        pattern: "[\\[\\(]\\s*([^\\]\\)]+?)\\s*[\\]\\)]"
    )

    public static func stripWhisperMarkers(_ text: String) -> String {
        let nsText = text as NSString
        let matches = markerRegex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        var result = text
        for match in matches.reversed() {
            let innerRange = match.range(at: 1)
            let inner = nsText.substring(with: innerRange)
            if knownMarkers.contains(inner) || knownMarkers.contains(inner.lowercased()) {
                let fullRange = Range(match.range, in: result)!
                result.replaceSubrange(fullRange, with: "")
            }
        }
        return result
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func findWhisperBinary() -> String? {
        if let bundled = Bundle.main.url(forAuxiliaryExecutable: "whisper-cli"),
           FileManager.default.isExecutableFile(atPath: bundled.path) {
            return bundled.path
        }
        let candidates = [
            "/opt/homebrew/bin/whisper-cli",
            "/usr/local/bin/whisper-cli",
            "/opt/homebrew/bin/whisper-cpp",
            "/usr/local/bin/whisper-cpp",
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        for name in ["whisper-cli", "whisper-cpp"] {
            let which = Process()
            which.executableURL = URL(fileURLWithPath: "/usr/bin/which")
            which.arguments = [name]
            let pipe = Pipe()
            which.standardOutput = pipe
            which.standardError = Pipe()
            try? which.run()
            which.waitUntilExit()

            let result = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let result = result, !result.isEmpty {
                return result
            }
        }

        return nil
    }

    public static func modelExists(modelSize: String) -> Bool {
        return findModel(modelSize: modelSize) != nil
    }

    static func findVADModel() -> String? {
        let name = ModelDownloader.vadModelFileName
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("models/\(name)"),
           ModelDownloader.isValidGGMLFile(at: bundled) {
            return bundled.path
        }
        let candidates = [
            Config.configDir.appendingPathComponent("models/\(name)").path,
            "/opt/homebrew/share/whisper-cpp/models/\(name)",
            "/usr/local/share/whisper-cpp/models/\(name)",
        ]
        return candidates.first { ModelDownloader.isValidGGMLFile(at: URL(fileURLWithPath: $0)) }
    }

    static func findModel(modelSize: String) -> String? {
        let modelFileName = "ggml-\(modelSize).bin"

        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("models/\(modelFileName)"),
           ModelDownloader.isValidGGMLFile(at: bundled) {
            return bundled.path
        }

        let candidates = [
            "\(Config.configDir.path)/models/\(modelFileName)",
            "/opt/homebrew/share/whisper-cpp/models/\(modelFileName)",
            "/usr/local/share/whisper-cpp/models/\(modelFileName)",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/.cache/whisper/\(modelFileName)",
        ]

        for path in candidates {
            if ModelDownloader.isValidGGMLFile(at: URL(fileURLWithPath: path)) {
                return path
            }
        }

        return nil
    }
}

enum TranscriberError: LocalizedError {
    case whisperNotFound
    case modelNotFound(String)
    case vadModelNotFound
    case transcriptionFailed

    var errorDescription: String? {
        switch self {
        case .whisperNotFound:
            return "Движок распознавания не найден. Установите VoiceON заново из образа VoiceON.dmg."
        case .modelNotFound(let size):
            return "Модель Whisper «\(size)» не найдена. Выберите её в меню «Модель» для загрузки или вернитесь к встроенной модели «Базовая»."
        case .vadModelNotFound:
            return "Модель определения речи не найдена. Перезапустите VoiceON для загрузки или отключите определение речи в настройках."
        case .transcriptionFailed:
            return "Не удалось распознать речь"
        }
    }
}
