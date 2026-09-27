import Foundation

public struct TextPostProcessor {
    // Составные команды должны обрабатываться раньше слов «точка» и «запятая».
    // Горизонтальные пробелы не захватывают уже вставленные переводы строки.
    private static let replacements: [(pattern: String, replacement: String)] = [
        (#"\b(?:точка\h+с\h+запятой|semicolon|semi\h+colon)\b"#, ";"),
        (#"\b(?:вопросительный\h+знак|знак\h+вопроса|question\h+mark)\b"#, "?"),
        (#"\b(?:восклицательный\h+знак|знак\h+восклицания|exclamation\h+(?:mark|point))\b"#, "!"),
        (#"\h*\b(?:новый\h+абзац|с\h+нового\h+абзаца|new\h+paragraph)\b\h*"#, "\n\n"),
        (#"\h*\b(?:новая\h+строка|с\h+новой\h+строки|перенос\h+строки|new\h*line)\b\h*"#, "\n"),
        (#"\b(?:открыть\h+кавычки|кавычки\h+открываются|открывающие\h+кавычки)\b\h*"#, "«"),
        (#"\h*\b(?:закрыть\h+кавычки|кавычки\h+закрываются|закрывающие\h+кавычки)\b"#, "»"),
        (#"\bopen\h+quote\b\h*"#, "\""),
        (#"\h*\bclose\h+quote\b"#, "\""),
        (#"\b(?:открыть\h+квадратную\h+скобку|квадратная\h+скобка\h+открывается|открывающая\h+квадратная\h+скобка)\b\h*"#, "["),
        (#"\h*\b(?:закрыть\h+квадратную\h+скобку|квадратная\h+скобка\h+закрывается|закрывающая\h+квадратная\h+скобка)\b"#, "]"),
        (#"\b(?:открыть\h+фигурную\h+скобку|фигурная\h+скобка\h+открывается|открывающая\h+фигурная\h+скобка)\b\h*"#, "{"),
        (#"\h*\b(?:закрыть\h+фигурную\h+скобку|фигурная\h+скобка\h+закрывается|закрывающая\h+фигурная\h+скобка)\b"#, "}"),
        (#"\b(?:открыть\h+(?:круглую\h+)?скобку|(?:круглая\h+)?скобка\h+открывается|открывающая\h+(?:круглая\h+)?скобка|open\h+paren)\b\h*"#, "("),
        (#"\h*\b(?:закрыть\h+(?:круглую\h+)?скобку|(?:круглая\h+)?скобка\h+закрывается|закрывающая\h+(?:круглая\h+)?скобка|close\h+paren)\b"#, ")"),
        (#"\b(?:многоточие|ellipsis)\b"#, "..."),
        (#"\b(?:двоеточие|colon)\b"#, ":"),
        (#"\b(?:точка|period|full\h+stop)\b"#, "."),
        (#"\b(?:запятая|comma|[ck]a?r?ma)\b"#, ","),
        (#"\h*\b(?:тире|dash)\b\h*"#, " — "),
        (#"\h*\b(?:дефис|hyphen)\b\h*"#, "-"),
    ]

    private static let compiledReplacements: [(regex: NSRegularExpression, replacement: String)] =
        replacements.compactMap { item in
            guard let regex = try? NSRegularExpression(pattern: item.pattern, options: .caseInsensitive) else {
                return nil
            }
            return (regex, item.replacement)
        }

    public static func process(_ text: String) -> String {
        var result = text
        for (regex, replacement) in compiledReplacements {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: replacement
            )
        }
        result = fixSpacingAroundPunctuation(result)
        result = ensureSpaceAfterPunctuation(result)
        return result
    }

    private static func fixSpacingAroundPunctuation(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\h+([.,?!:;])"#) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "$1"
        )
    }

    private static func ensureSpaceAfterPunctuation(_ text: String) -> String {
        // Не разбиваем числа вроде 3,14 и 10:30. Буквы включают кириллицу.
        guard let regex = try? NSRegularExpression(pattern: #"([.,?!:;])(\p{L})"#) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "$1 $2"
        )
    }
}
