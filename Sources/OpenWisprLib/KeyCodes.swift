import Foundation

public struct KeyCodes {
    public static let nameToCode: [String: UInt16] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
        "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
        "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "return": 36,
        "l": 37, "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43,
        "/": 44, "n": 45, "m": 46, ".": 47, "tab": 48, "space": 49,
        "`": 50, "delete": 51, "escape": 53,
        "rightcmd": 54, "cmd": 55, "leftcmd": 55,
        "shift": 56, "leftshift": 56,
        "option": 58, "leftoption": 58, "alt": 58, "leftalt": 58,
        "ctrl": 59, "leftctrl": 59, "control": 59,
        "rightshift": 60,
        "rightoption": 61, "rightalt": 61,
        "rightctrl": 62, "rightcontrol": 62,
        "fn": 63, "globe": 63,
        "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97,
        "f7": 98, "f8": 100, "f9": 101, "f10": 109, "f11": 103, "f12": 111,
        "f13": 105, "f14": 107, "f15": 113,
    ]

    public static let codeToName: [UInt16: String] = {
        var result: [UInt16: String] = [:]
        for (name, code) in nameToCode {
            if result[code] == nil {
                result[code] = name
            }
        }
        return result
    }()

    private static let russianAliases: [String: String] = [
        "пробел": "space", "ввод": "return", "табуляция": "tab",
        "удалить": "delete", "удаление": "delete", "отмена": "escape",
        "глобус": "globe", "fn (глобус)": "fn", "функция": "fn",
        "команда": "cmd", "⌘": "cmd", "⇧": "shift", "⌥": "option", "⌃": "ctrl",
        "шифт": "shift", "контрол": "ctrl", "альт": "alt",
        "левая ⌘": "leftcmd", "правая ⌘": "rightcmd",
        "левый ⇧": "leftshift", "правый ⇧": "rightshift",
        "левый ⌥": "leftoption", "правый ⌥": "rightoption",
        "левый ⌃": "leftctrl", "правый ⌃": "rightctrl",
        "ф": "a", "ы": "s", "в": "d", "а": "f", "р": "h", "п": "g",
        "я": "z", "ч": "x", "с": "c", "м": "v", "и": "b", "й": "q",
        "ц": "w", "у": "e", "к": "r", "н": "y", "е": "t", "щ": "o",
        "г": "u", "ш": "i", "з": "p", "д": "l", "о": "j", "л": "k",
        "т": "n", "ь": "m", "х": "[", "ъ": "]", "ж": ";", "э": "'",
        "б": ",", "ю": ".", "ё": "`",
    ]

    private static let displayNames: [UInt16: String] = [
        36: "Ввод", 48: "Табуляция", 49: "Пробел", 51: "Удалить", 53: "Отмена",
        54: "Правая ⌘", 55: "Левая ⌘", 56: "Левый ⇧", 58: "Левый ⌥",
        59: "Левый ⌃", 60: "Правый ⇧", 61: "Правый ⌥", 62: "Правый ⌃",
        63: "Fn (глобус)",
    ]

    private static let modifierDisplayNames: [String: String] = [
        "cmd": "⌘", "command": "⌘", "shift": "⇧", "ctrl": "⌃", "control": "⌃",
        "opt": "⌥", "option": "⌥", "alt": "⌥", "fn": "Fn", "globe": "Fn", "function": "Fn",
    ]

    public static func parse(_ input: String) -> (keyCode: UInt16, modifiers: [String])? {
        let parts = input.lowercased().split(separator: "+", omittingEmptySubsequences: false)
            .map {
                let value = String($0).trimmingCharacters(in: .whitespaces)
                return russianAliases[value] ?? value
            }

        guard let keyName = parts.last, let code = nameToCode[keyName] else {
            return nil
        }

        let modifiers = Array(parts.dropLast())
        guard modifiers.allSatisfy({ HotkeyConfig.flag(for: $0) != nil }) else {
            return nil
        }
        return (code, modifiers)
    }

    public static func describe(keyCode: UInt16, modifiers: [String]) -> String {
        let keyName = displayNames[keyCode] ?? codeToName[keyCode]?.uppercased() ?? "клавиша(\(keyCode))"
        if modifiers.isEmpty {
            return keyName
        }
        let displayedModifiers = modifiers.map { modifierDisplayNames[$0.lowercased()] ?? $0 }
        return (displayedModifiers + [keyName]).joined(separator: "+")
    }
}
