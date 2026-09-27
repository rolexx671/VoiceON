import Foundation

public struct LanguageOption: Equatable, Sendable {
    public let code: String
    public let name: String
}

public struct DictionaryEntry: Codable, Equatable {
    public var from: String
    public var to: String

    public init(from: String, to: String) {
        self.from = from
        self.to = to
    }
}

public struct Config: Codable {
    public var hotkeys: [HotkeyConfig]
    public var modelPath: String?
    public var modelSize: String
    public var language: String
    public var whisperPrompt: String?
    public var voiceActivityDetection: Bool?
    public var vadThreshold: Double?
    public var spokenPunctuation: FlexBool?
    public var maxRecordings: Int?
    public var toggleMode: FlexBool?
    public var soundFeedback: FlexBool?
    public var voiceProcessing: FlexBool?
    public var customDictionary: [DictionaryEntry]?
    public var audioInputDeviceID: UInt32?
    public var audioInputDeviceUID: String?

    public var hotkey: HotkeyConfig {
        get { hotkeys[0] }
        set { hotkeys = Config.deduplicateHotkeys([newValue]) }
    }

    public func hotkeySummary() -> String {
        hotkeys
            .map { KeyCodes.describe(keyCode: $0.keyCode, modifiers: $0.modifiers) }
            .joined(separator: " · ")
    }

    private static func deduplicateHotkeys(_ list: [HotkeyConfig]) -> [HotkeyConfig] {
        var out: [HotkeyConfig] = []
        for h in list where !out.contains(h) {
            out.append(h)
        }
        return out
    }

    private enum CodingKeys: String, CodingKey {
        case hotkey
        case hotkeys
        case modelPath
        case modelSize
        case language
        case whisperPrompt
        case voiceActivityDetection
        case vadThreshold
        case spokenPunctuation
        case maxRecordings
        case toggleMode
        case soundFeedback
        case voiceProcessing
        case customDictionary
        case audioInputDeviceID
        case audioInputDeviceUID
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let hotkeysList = try c.decodeIfPresent([HotkeyConfig].self, forKey: .hotkeys)
        let legacyHotkey = try c.decodeIfPresent(HotkeyConfig.self, forKey: .hotkey)
        if let list = hotkeysList, !list.isEmpty {
            self.hotkeys = Config.deduplicateHotkeys(list)
        } else if let legacy = legacyHotkey {
            self.hotkeys = [legacy]
        } else {
            self.hotkeys = [HotkeyConfig(keyCode: 63, modifiers: [])]
        }
        self.modelPath = try c.decodeIfPresent(String.self, forKey: .modelPath)
        self.modelSize = try c.decode(String.self, forKey: .modelSize)
        self.language = try c.decode(String.self, forKey: .language)
        self.whisperPrompt = try c.decodeIfPresent(String.self, forKey: .whisperPrompt)
        self.voiceActivityDetection = try c.decodeIfPresent(Bool.self, forKey: .voiceActivityDetection)
        self.vadThreshold = try c.decodeIfPresent(Double.self, forKey: .vadThreshold)
        self.spokenPunctuation = try c.decodeIfPresent(FlexBool.self, forKey: .spokenPunctuation)
        self.maxRecordings = try c.decodeIfPresent(Int.self, forKey: .maxRecordings)
        self.toggleMode = try c.decodeIfPresent(FlexBool.self, forKey: .toggleMode)
        self.soundFeedback = try c.decodeIfPresent(FlexBool.self, forKey: .soundFeedback)
        self.voiceProcessing = try c.decodeIfPresent(FlexBool.self, forKey: .voiceProcessing)
        self.customDictionary = try c.decodeIfPresent([DictionaryEntry].self, forKey: .customDictionary)
        self.audioInputDeviceID = try c.decodeIfPresent(UInt32.self, forKey: .audioInputDeviceID)
        self.audioInputDeviceUID = try c.decodeIfPresent(String.self, forKey: .audioInputDeviceUID)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(hotkeys, forKey: .hotkeys)
        try c.encode(hotkeys[0], forKey: .hotkey)
        try c.encodeIfPresent(modelPath, forKey: .modelPath)
        try c.encode(modelSize, forKey: .modelSize)
        try c.encode(language, forKey: .language)
        try c.encodeIfPresent(whisperPrompt, forKey: .whisperPrompt)
        try c.encodeIfPresent(voiceActivityDetection, forKey: .voiceActivityDetection)
        try c.encodeIfPresent(vadThreshold, forKey: .vadThreshold)
        try c.encodeIfPresent(spokenPunctuation, forKey: .spokenPunctuation)
        try c.encodeIfPresent(maxRecordings, forKey: .maxRecordings)
        try c.encodeIfPresent(toggleMode, forKey: .toggleMode)
        try c.encodeIfPresent(soundFeedback, forKey: .soundFeedback)
        try c.encodeIfPresent(voiceProcessing, forKey: .voiceProcessing)
        try c.encodeIfPresent(customDictionary, forKey: .customDictionary)
        try c.encodeIfPresent(audioInputDeviceID, forKey: .audioInputDeviceID)
        try c.encodeIfPresent(audioInputDeviceUID, forKey: .audioInputDeviceUID)
    }

    public init(
        hotkeys: [HotkeyConfig],
        modelPath: String?,
        modelSize: String,
        language: String,
        whisperPrompt: String? = nil,
        voiceActivityDetection: Bool? = nil,
        vadThreshold: Double? = nil,
        spokenPunctuation: FlexBool?,
        maxRecordings: Int?,
        toggleMode: FlexBool?,
        soundFeedback: FlexBool? = nil,
        voiceProcessing: FlexBool? = nil,
        customDictionary: [DictionaryEntry]? = nil,
        audioInputDeviceID: UInt32? = nil,
        audioInputDeviceUID: String? = nil
    ) {
        self.hotkeys = hotkeys.isEmpty
            ? [HotkeyConfig(keyCode: 63, modifiers: [])]
            : Config.deduplicateHotkeys(hotkeys)
        self.modelPath = modelPath
        self.modelSize = modelSize
        self.language = language
        self.whisperPrompt = whisperPrompt
        self.voiceActivityDetection = voiceActivityDetection
        self.vadThreshold = vadThreshold
        self.spokenPunctuation = spokenPunctuation
        self.maxRecordings = maxRecordings
        self.toggleMode = toggleMode
        self.soundFeedback = soundFeedback
        self.voiceProcessing = voiceProcessing
        self.customDictionary = customDictionary
        self.audioInputDeviceID = audioInputDeviceID
        self.audioInputDeviceUID = audioInputDeviceUID
    }

    public static let supportedLanguages: [LanguageOption] = [
        LanguageOption(code: "auto", name: "Определять автоматически"),
        LanguageOption(code: "en", name: "Английский"),
        LanguageOption(code: "zh", name: "Китайский"),
        LanguageOption(code: "de", name: "Немецкий"),
        LanguageOption(code: "es", name: "Испанский"),
        LanguageOption(code: "ru", name: "Русский"),
        LanguageOption(code: "ko", name: "Корейский"),
        LanguageOption(code: "fr", name: "Французский"),
        LanguageOption(code: "ja", name: "Японский"),
        LanguageOption(code: "pt", name: "Португальский"),
        LanguageOption(code: "tr", name: "Турецкий"),
        LanguageOption(code: "pl", name: "Польский"),
        LanguageOption(code: "ca", name: "Каталанский"),
        LanguageOption(code: "nl", name: "Нидерландский"),
        LanguageOption(code: "ar", name: "Арабский"),
        LanguageOption(code: "sv", name: "Шведский"),
        LanguageOption(code: "it", name: "Итальянский"),
        LanguageOption(code: "id", name: "Индонезийский"),
        LanguageOption(code: "hi", name: "Хинди"),
        LanguageOption(code: "fi", name: "Финский"),
        LanguageOption(code: "vi", name: "Вьетнамский"),
        LanguageOption(code: "he", name: "Иврит"),
        LanguageOption(code: "uk", name: "Украинский"),
        LanguageOption(code: "el", name: "Греческий"),
        LanguageOption(code: "ms", name: "Малайский"),
        LanguageOption(code: "cs", name: "Чешский"),
        LanguageOption(code: "ro", name: "Румынский"),
        LanguageOption(code: "da", name: "Датский"),
        LanguageOption(code: "hu", name: "Венгерский"),
        LanguageOption(code: "ta", name: "Тамильский"),
        LanguageOption(code: "no", name: "Норвежский"),
        LanguageOption(code: "th", name: "Тайский"),
        LanguageOption(code: "ur", name: "Урду"),
        LanguageOption(code: "hr", name: "Хорватский"),
        LanguageOption(code: "bg", name: "Болгарский"),
        LanguageOption(code: "lt", name: "Литовский"),
        LanguageOption(code: "la", name: "Латинский"),
        LanguageOption(code: "mi", name: "Маори"),
        LanguageOption(code: "ml", name: "Малаялам"),
        LanguageOption(code: "cy", name: "Валлийский"),
        LanguageOption(code: "sk", name: "Словацкий"),
        LanguageOption(code: "te", name: "Телугу"),
        LanguageOption(code: "fa", name: "Персидский"),
        LanguageOption(code: "lv", name: "Латышский"),
        LanguageOption(code: "bn", name: "Бенгальский"),
        LanguageOption(code: "sr", name: "Сербский"),
        LanguageOption(code: "az", name: "Азербайджанский"),
        LanguageOption(code: "sl", name: "Словенский"),
        LanguageOption(code: "kn", name: "Каннада"),
        LanguageOption(code: "et", name: "Эстонский"),
        LanguageOption(code: "mk", name: "Македонский"),
        LanguageOption(code: "br", name: "Бретонский"),
        LanguageOption(code: "eu", name: "Баскский"),
        LanguageOption(code: "is", name: "Исландский"),
        LanguageOption(code: "hy", name: "Армянский"),
        LanguageOption(code: "ne", name: "Непальский"),
        LanguageOption(code: "mn", name: "Монгольский"),
        LanguageOption(code: "bs", name: "Боснийский"),
        LanguageOption(code: "kk", name: "Казахский"),
        LanguageOption(code: "sq", name: "Албанский"),
        LanguageOption(code: "sw", name: "Суахили"),
        LanguageOption(code: "gl", name: "Галисийский"),
        LanguageOption(code: "mr", name: "Маратхи"),
        LanguageOption(code: "pa", name: "Панджаби"),
        LanguageOption(code: "si", name: "Сингальский"),
        LanguageOption(code: "km", name: "Кхмерский"),
        LanguageOption(code: "sn", name: "Шона"),
        LanguageOption(code: "yo", name: "Йоруба"),
        LanguageOption(code: "so", name: "Сомалийский"),
        LanguageOption(code: "af", name: "Африкаанс"),
        LanguageOption(code: "oc", name: "Окситанский"),
        LanguageOption(code: "ka", name: "Грузинский"),
        LanguageOption(code: "be", name: "Белорусский"),
        LanguageOption(code: "tg", name: "Таджикский"),
        LanguageOption(code: "sd", name: "Синдхи"),
        LanguageOption(code: "gu", name: "Гуджарати"),
        LanguageOption(code: "am", name: "Амхарский"),
        LanguageOption(code: "yi", name: "Идиш"),
        LanguageOption(code: "lo", name: "Лаосский"),
        LanguageOption(code: "uz", name: "Узбекский"),
        LanguageOption(code: "fo", name: "Фарерский"),
        LanguageOption(code: "ht", name: "Гаитянский креольский"),
        LanguageOption(code: "ps", name: "Пушту"),
        LanguageOption(code: "tk", name: "Туркменский"),
        LanguageOption(code: "nn", name: "Нюнорск"),
        LanguageOption(code: "mt", name: "Мальтийский"),
        LanguageOption(code: "sa", name: "Санскрит"),
        LanguageOption(code: "lb", name: "Люксембургский"),
        LanguageOption(code: "my", name: "Бирманский"),
        LanguageOption(code: "bo", name: "Тибетский"),
        LanguageOption(code: "tl", name: "Тагальский"),
        LanguageOption(code: "mg", name: "Малагасийский"),
        LanguageOption(code: "as", name: "Ассамский"),
        LanguageOption(code: "tt", name: "Татарский"),
        LanguageOption(code: "haw", name: "Гавайский"),
        LanguageOption(code: "ln", name: "Лингала"),
        LanguageOption(code: "ha", name: "Хауса"),
        LanguageOption(code: "ba", name: "Башкирский"),
        LanguageOption(code: "jw", name: "Яванский"),
        LanguageOption(code: "su", name: "Сунданский"),
    ]

    public static let supportedModels: [String] = [
        "tiny.en", "tiny.en-q5_1",
        "tiny",
        "base.en", "base.en-q5_1",
        "base",
        "small.en", "small.en-q5_1",
        "small",
        "medium.en", "medium.en-q5_0",
        "medium",
        "large-v3-turbo", "large-v3-turbo-q8_0", "large-v3-turbo-q5_0",
        "large-v3",
    ]

    public static let modelAliases: [String: String] = [
        "large": "large-v3",
    ]

    public static func resolveModelAlias(_ size: String) -> String {
        return modelAliases[size] ?? size
    }

    public static func isEnglishOnlyModel(_ name: String) -> Bool {
        return name.hasSuffix(".en") || name.contains(".en-")
    }

    public static let defaultMaxRecordings = 0

    public var isSoundFeedbackEnabled: Bool { soundFeedback?.value ?? false }
    public var isVoiceProcessingEnabled: Bool { voiceProcessing?.value ?? false }

    public var isVADEnabled: Bool { voiceActivityDetection ?? false }

    public var effectiveVADThreshold: Double {
        guard let vadThreshold, vadThreshold.isFinite else { return 0.5 }
        return min(max(vadThreshold, 0), 1)
    }

    public static func effectiveMaxRecordings(_ value: Int?) -> Int {
        let raw = value ?? Config.defaultMaxRecordings
        if raw == 0 { return 0 }
        return min(max(1, raw), 100)
    }

    public static let defaultConfig = Config(
        hotkeys: [HotkeyConfig(keyCode: 63, modifiers: [])],
        modelPath: nil,
        modelSize: "base",
        language: "ru",
        whisperPrompt: nil,
        voiceActivityDetection: false,
        spokenPunctuation: FlexBool(false),
        maxRecordings: nil,
        toggleMode: FlexBool(false),
        soundFeedback: FlexBool(false),
        voiceProcessing: FlexBool(false)
    )

    public static var configDir: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/voiceon")
    }

    public static var configFile: URL {
        configDir.appendingPathComponent("config.json")
    }

    public static func load() -> Config {
        guard let data = try? Data(contentsOf: configFile) else {
            let config = Config.defaultConfig
            try? config.save()
            return config
        }

        do {
            var config = try JSONDecoder().decode(Config.self, from: data)
            let resolved = Config.resolveModelAlias(config.modelSize)
            if resolved != config.modelSize {
                config.modelSize = resolved
                try? config.save()
            }
            return config
        } catch {
            fputs("Предупреждение: файл настроек \(configFile.path) повреждён или имеет неверный формат. Используются исходные настройки VoiceON.\n", stderr)
            return Config.defaultConfig
        }
    }

    public static func decode(from data: Data) throws -> Config {
        var config = try JSONDecoder().decode(Config.self, from: data)
        config.modelSize = Config.resolveModelAlias(config.modelSize)
        return config
    }

    public func save() throws {
        try FileManager.default.createDirectory(at: Config.configDir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: Config.configFile)
    }
}

public struct FlexBool: Codable {
    public let value: Bool

    public init(_ value: Bool) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            value = b
        } else if let s = try? container.decode(String.self) {
            value = ["true", "yes", "1"].contains(s.lowercased())
        } else if let i = try? container.decode(Int.self) {
            value = i != 0
        } else {
            value = false
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

public struct HotkeyConfig: Codable, Equatable {
    public var keyCode: UInt16
    public var modifiers: [String]

    public init(keyCode: UInt16, modifiers: [String]) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public var modifierFlags: UInt64 {
        var flags: UInt64 = 0
        for mod in modifiers {
            // Ошибка в настройках не должна расширять сочетание клавиш.
            guard let flag = Self.flag(for: mod) else { return UInt64.max }
            flags |= flag
        }
        return flags
    }

    public static func flag(for modifier: String) -> UInt64? {
        switch modifier.lowercased() {
        case "cmd", "command": return UInt64(1 << 20)
        case "shift": return UInt64(1 << 17)
        case "ctrl", "control": return UInt64(1 << 18)
        case "opt", "option", "alt": return UInt64(1 << 19)
        case "fn", "globe", "function": return UInt64(1 << 23)
        default: return nil
        }
    }
}
