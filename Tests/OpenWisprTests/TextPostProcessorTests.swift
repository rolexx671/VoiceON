import XCTest
@testable import OpenWisprLib

final class TextPostProcessorTests: XCTestCase {

    func testPeriodReplacement() {
        XCTAssertEqual(TextPostProcessor.process("hello period"), "hello.")
    }

    func testCommaReplacement() {
        XCTAssertEqual(TextPostProcessor.process("one comma two"), "one, two")
    }

    func testQuestionMark() {
        XCTAssertEqual(TextPostProcessor.process("how are you question mark"), "how are you?")
    }

    func testExclamationMark() {
        XCTAssertEqual(TextPostProcessor.process("wow exclamation mark"), "wow!")
    }

    func testExclamationPoint() {
        XCTAssertEqual(TextPostProcessor.process("wow exclamation point"), "wow!")
    }

    func testColon() {
        XCTAssertEqual(TextPostProcessor.process("note colon"), "note:")
    }

    func testSemicolon() {
        XCTAssertEqual(TextPostProcessor.process("first semicolon second"), "first; second")
    }

    func testEllipsis() {
        XCTAssertEqual(TextPostProcessor.process("wait ellipsis"), "wait...")
    }

    func testNewLine() {
        XCTAssertEqual(TextPostProcessor.process("hello new line world"), "hello\nworld")
    }

    func testNewParagraph() {
        XCTAssertEqual(TextPostProcessor.process("hello new paragraph world"), "hello\n\nworld")
    }

    func testOpenCloseQuotes() {
        XCTAssertEqual(TextPostProcessor.process("he said open quote hello close quote"), "he said \"hello\"")
    }

    func testOpenCloseParens() {
        XCTAssertEqual(TextPostProcessor.process("open paren note close paren"), "(note)")
    }

    func testCaseInsensitive() {
        XCTAssertEqual(TextPostProcessor.process("hello Period"), "hello.")
    }

    func testMultiplePunctuationInOneSentence() {
        XCTAssertEqual(TextPostProcessor.process("hello comma how are you question mark"), "hello, how are you?")
    }

    func testSpacingFixRemovesSpaceBeforePunctuation() {
        XCTAssertEqual(TextPostProcessor.process("hello , world"), "hello, world")
    }

    func testPlainTextPassesThrough() {
        XCTAssertEqual(TextPostProcessor.process("hello world"), "hello world")
    }

    func testEmptyString() {
        XCTAssertEqual(TextPostProcessor.process(""), "")
    }

    func testFullStop() {
        XCTAssertEqual(TextPostProcessor.process("done full stop"), "done.")
    }

    func testDash() {
        XCTAssertEqual(TextPostProcessor.process("one dash two"), "one — two")
    }

    func testHyphen() {
        XCTAssertEqual(TextPostProcessor.process("well hyphen known"), "well-known")
    }

    func testSemiColonTwoWords() {
        XCTAssertEqual(TextPostProcessor.process("first semi colon second"), "first; second")
    }

    func testNewlineSingleWord() {
        XCTAssertEqual(TextPostProcessor.process("hello newline world"), "hello\nworld")
    }

    func testEnsureSpaceAfterPunctuation() {
        XCTAssertEqual(TextPostProcessor.process("hello,world"), "hello, world")
    }

    func testRussianSentencePunctuation() {
        XCTAssertEqual(
            TextPostProcessor.process("Привет запятая как дела вопросительный знак Всё хорошо восклицательный знак"),
            "Привет, как дела? Всё хорошо!"
        )
        XCTAssertEqual(TextPostProcessor.process("Готово точка"), "Готово.")
        XCTAssertEqual(TextPostProcessor.process("Ответ двоеточие да"), "Ответ: да")
        XCTAssertEqual(TextPostProcessor.process("Подождите многоточие"), "Подождите...")
    }

    func testRussianSemicolonIsMatchedBeforePeriod() {
        XCTAssertEqual(TextPostProcessor.process("Один точка с запятой два точка"), "Один; два.")
    }

    func testRussianCommandsIgnoreCaseAndAcceptMultipleSpaces() {
        XCTAssertEqual(TextPostProcessor.process("ПРИВЕТ ЗАПЯТАЯ МИР ТОЧКА"), "ПРИВЕТ, МИР.")
        XCTAssertEqual(TextPostProcessor.process("Один точка  с\tзапятой два"), "Один; два")
    }

    func testRussianQuotesUseGuillemetsWithoutInnerSpaces() {
        XCTAssertEqual(TextPostProcessor.process("Он сказал открыть кавычки привет закрыть кавычки точка"), "Он сказал «привет».")
        XCTAssertEqual(TextPostProcessor.process("кавычки открываются текст кавычки закрываются"), "«текст»")
        XCTAssertEqual(TextPostProcessor.process("открывающие кавычки текст закрывающие кавычки"), "«текст»")
    }

    func testRussianBracketsHaveNoInnerSpaces() {
        XCTAssertEqual(TextPostProcessor.process("открыть скобку примечание закрыть скобку"), "(примечание)")
        XCTAssertEqual(TextPostProcessor.process("скобка открывается примечание скобка закрывается"), "(примечание)")
        XCTAssertEqual(TextPostProcessor.process("открыть квадратную скобку текст закрыть квадратную скобку"), "[текст]")
        XCTAssertEqual(TextPostProcessor.process("открыть фигурную скобку текст закрыть фигурную скобку"), "{текст}")
    }

    func testRussianLineAndParagraphBreaksHaveNoExtraSpaces() {
        XCTAssertEqual(TextPostProcessor.process("Первая строка новая строка вторая строка"), "Первая строка\nвторая строка")
        XCTAssertEqual(TextPostProcessor.process("Первый абзац новый абзац второй абзац"), "Первый абзац\n\nвторой абзац")
        XCTAssertEqual(TextPostProcessor.process("Один с новой строки два с нового абзаца три"), "Один\nдва\n\nтри")
        XCTAssertEqual(TextPostProcessor.process("перенос строки текст"), "\nтекст")
    }

    func testRussianHyphenAndDash() {
        XCTAssertEqual(TextPostProcessor.process("кто дефис то"), "кто-то")
        XCTAssertEqual(TextPostProcessor.process("Москва тире столица"), "Москва — столица")
    }

    func testRussianCommandsRespectWordBoundaries() {
        let input = "Цветочка растёт в квартире. Уточка плывёт."
        XCTAssertEqual(TextPostProcessor.process(input), input)
    }

    func testRussianSpacingAndNumbers() {
        XCTAssertEqual(TextPostProcessor.process("Привет,мир!Как дела?Хорошо."), "Привет, мир! Как дела? Хорошо.")
        XCTAssertEqual(TextPostProcessor.process("Числа 3,14 и 3.14, время 10:30."), "Числа 3,14 и 3.14, время 10:30.")
    }

    func testPunctuationDoesNotRemoveLineBreaks() {
        XCTAssertEqual(TextPostProcessor.process("Текст\n точка"), "Текст\n.")
    }
}
