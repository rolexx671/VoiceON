import AppKit
import Foundation
import OpenWisprLib

setvbuf(stdout, nil, _IOLBF, 0)
setvbuf(stderr, nil, _IOLBF, 0)

let version = OpenWispr.version

func printUsage() {
    print("""
    VoiceON, версия \(version) — Голосовой ввод для macOS

    ИСПОЛЬЗОВАНИЕ:
        voiceon start              Запустить голосовой ввод
        voiceon set-hotkey <клавиша>   Назначить клавишу диктовки
        voiceon get-hotkey         Показать текущую клавишу
        voiceon set-model <модель>   Выбрать модель Whisper
        voiceon set-language <код>  Выбрать язык (например, ru, auto)
        voiceon download-model [модель]  Скачать модель Whisper
        voiceon transcribe <файл.wav>  Распознать речь из звукового файла
        voiceon status             Показать настройки и состояние
        voiceon --help             Показать эту справку

    ПРИМЕРЫ КЛАВИШ:
        voiceon set-hotkey globe             Клавиша глобуса/fn (по умолчанию)
        voiceon set-hotkey rightoption        Правая клавиша Option
        voiceon set-hotkey f5                 Клавиша F5
        voiceon set-hotkey ctrl+space         Ctrl + пробел

    ДОСТУПНЫЕ МОДЕЛИ:
        \(Config.supportedModels.joined(separator: ", "))
    """)
}

func cmdStart() {
    let instanceLock: DaemonInstanceLock
    do {
        guard let acquiredLock = try DaemonInstanceLock.acquire() else {
            fputs("VoiceON уже запущен.\n", stderr)
            exit(0)
        }
        instanceLock = acquiredLock
    } catch {
        fputs("Ошибка: не удалось заблокировать повторный запуск VoiceON: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    let app = NSApplication.shared
    let terminationResult = LegacyInstanceTerminator.terminatePreviousInstances()
    if terminationResult.foundCount > 0 {
        print("Завершены предыдущие экземпляры VoiceON: \(terminationResult.foundCount).")
    }
    if !terminationResult.remainingProcessIdentifiers.isEmpty {
        let processList = terminationResult.remainingProcessIdentifiers
            .map(String.init)
            .joined(separator: ", ")
        fputs("Не удалось завершить предыдущие процессы VoiceON: \(processList).\n", stderr)
        exit(0)
    }
    app.setActivationPolicy(.accessory)

    let delegate = AppDelegate()
    app.delegate = delegate

    signal(SIGINT) { _ in
        print("\nЗавершение VoiceON…")
        exit(0)
    }

    withExtendedLifetime(instanceLock) {
        app.run()
    }
}

func cmdSetHotkey(_ keyString: String) {
    let keyNames = keyString.lowercased().split(separator: "+")
        .map { $0.trimmingCharacters(in: .whitespaces) }
    if keyNames.contains("capslock") {
        print("Ошибка: Caps Lock нельзя использовать для диктовки: macOS переключает её состояние и не сообщает об отпускании. Выберите другую клавишу.")
        exit(1)
    }

    guard let parsed = KeyCodes.parse(keyString) else {
        print("Ошибка: неизвестная клавиша '\(keyString)'")
        print("Примеры: выполните «voiceon --help»")
        exit(1)
    }

    var config = Config.load()
    config.hotkey = HotkeyConfig(keyCode: parsed.keyCode, modifiers: parsed.modifiers)

    do {
        try config.save()
        let desc = KeyCodes.describe(keyCode: parsed.keyCode, modifiers: parsed.modifiers)
        print("Клавиша диктовки: \(desc)")
    } catch {
        print("Не удалось сохранить настройки: \(error.localizedDescription)")
        exit(1)
    }
}

func cmdSetModel(_ size: String) {
    guard Config.supportedModels.contains(size) else {
        print("Ошибка: неизвестная модель '\(size)'")
        print("Доступны: \(Config.supportedModels.joined(separator: ", "))")
        exit(1)
    }

    var config = Config.load()
    config.modelSize = size

    do {
        try config.save()
        print("Выбрана модель: \(size)")
        if !Transcriber.modelExists(modelSize: size) {
            print("Модель будет скачана при следующем запуске.")
        }
    } catch {
        print("Не удалось сохранить настройки: \(error.localizedDescription)")
        exit(1)
    }
}

func cmdSetLanguage(_ lang: String) {
    let validCodes = Config.supportedLanguages.map { $0.code }
    guard validCodes.contains(lang) else {
        print("Ошибка: неизвестный язык '\(lang)'")
        print("Доступны: auto, en, fr, de, es, zh, ja, ko, pt, it, nl, ru, ...")
        print("Полный список: https://github.com/rolexx671/VoiceON")
        exit(1)
    }

    var config = Config.load()
    config.language = lang

    do {
        try config.save()
        let name = Config.supportedLanguages.first(where: { $0.code == lang })?.name ?? lang
        print("Выбран язык: \(name) (\(lang))")
    } catch {
        print("Не удалось сохранить настройки: \(error.localizedDescription)")
        exit(1)
    }
}

func cmdGetHotkey() {
    let config = Config.load()
    let desc = config.hotkeySummary()
    print("Текущая клавиша: \(desc)")
}

func cmdDownloadModel(_ size: String) {
    guard Config.supportedModels.contains(size) else {
        print("Ошибка: неизвестная модель «\(size)»")
        exit(1)
    }
    do {
        try ModelDownloader.download(modelSize: size)
    } catch {
        print("Ошибка: \(error.localizedDescription)")
        exit(1)
    }
}

func cmdTranscribe(_ path: String) {
    let config = Config.load()
    let transcriber = Transcriber(modelSize: config.modelSize, language: config.language,
                                  whisperPrompt: config.whisperPrompt,
                                  vadEnabled: config.isVADEnabled, vadThreshold: config.effectiveVADThreshold)
    transcriber.spokenPunctuation = config.spokenPunctuation?.value ?? false
    transcriber.customDictionary = config.customDictionary ?? []
    do {
        var text = try transcriber.transcribe(audioURL: URL(fileURLWithPath: path))
        if transcriber.spokenPunctuation { text = TextPostProcessor.process(text) }
        text = DictionaryPostProcessor.process(text, dictionary: transcriber.customDictionary)
        print(text)
    } catch {
        print("Ошибка: \(error.localizedDescription)")
        exit(1)
    }
}

func cmdStatus() {
    let config = Config.load()
    let hotkeyDesc = config.hotkeySummary()

    print("VoiceON, версия \(version)")
    print("Настройки:      \(Config.configFile.path)")
    print("Клавиша:      \(hotkeyDesc)")
    print("Модель:       \(config.modelSize)")
    print("Модель готова: \(Transcriber.modelExists(modelSize: config.modelSize) ? "да" : "нет")")
    print("whisper-cpp: \(Transcriber.findWhisperBinary() != nil ? "да" : "нет")")
    let langName = Config.supportedLanguages.first(where: { $0.code == config.language })?.name ?? config.language
    print("Язык:    \(langName) (\(config.language))")
    let toggleMode = config.toggleMode?.value ?? false
    print("Переключение:      \(toggleMode ? "вкл. (нажатие начинает и завершает запись)" : "выкл. (удерживайте для записи)")")
}

let args = CommandLine.arguments
let rawCommand = args.count > 1 ? args[1] : nil
let command: String? = {
    if let r = rawCommand, r.hasPrefix("-psn_") { return "start" }
    return rawCommand
}()

switch command {
case "start":
    if AppBundleLaunch.relaunchThroughAppBundleIfNeeded() {
        exit(0)
    }
    cmdStart()
case "set-hotkey":
    guard args.count > 2 else {
        print("Использование: voiceon set-hotkey <клавиша>")
        exit(1)
    }
    cmdSetHotkey(args[2])
case "set-model":
    guard args.count > 2 else {
        print("Использование: voiceon set-model <модель>")
        exit(1)
    }
    cmdSetModel(args[2])
case "set-language":
    guard args.count > 2 else {
        print("Использование: voiceon set-language <код>")
        print("Примеры: ru, en, auto")
        exit(1)
    }
    cmdSetLanguage(args[2])
case "get-hotkey":
    cmdGetHotkey()
case "download-model":
    let size = args.count > 2 ? args[2] : Config.defaultConfig.modelSize
    cmdDownloadModel(size)
case "status":
    cmdStatus()
case "transcribe":
    guard args.count > 2 else {
        print("Использование: voiceon transcribe <файл.wav>")
        exit(1)
    }
    cmdTranscribe(args[2])
case "--help", "-h", "help":
    printUsage()
case nil:
    if AppBundleLaunch.isExecutableInsideAppBundle(args[0]) {
        cmdStart()
    } else {
        printUsage()
    }
default:
    print("Неизвестная команда: \(command!)")
    printUsage()
    exit(1)
}
