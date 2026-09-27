import Foundation

// Минимальный адаптер существующих синхронных XCTest-проверок для Command Line Tools.
// Файлы продукта компилируются без изменений в один модуль с тестами.
// Асинхронные тесты, UI-тесты и полноценный жизненный цикл XCTest требуют Xcode.
class XCTestCase {
    func setUp() {}
    func tearDown() {}
    func setUpWithError() throws {}
    func tearDownWithError() throws {}
}

enum LocalTestReport {
    static var assertions = 0
    static var failures = 0
    static var currentTest = ""

    static func fail(_ message: String, file: StaticString = #filePath, line: UInt = #line) {
        failures += 1
        fputs("ОШИБКА \(currentTest) — \(file):\(line): \(message)\n", stderr)
    }
}

private enum LocalAssertionError: Error { case nilValue }

func runLocalTest<T: XCTestCase>(_ name: String, make: () -> T, body: (T) throws -> Void) {
    LocalTestReport.currentTest = name
    let test = make()
    do {
        try test.setUpWithError()
        test.setUp()
        do {
            try body(test)
        } catch LocalAssertionError.nilValue {
            // XCTUnwrap уже зарегистрировал ошибку утверждения.
        } catch {
            LocalTestReport.fail("Неожиданная ошибка: \(error)")
        }
        test.tearDown()
        try test.tearDownWithError()
    } catch {
        LocalTestReport.fail("Ошибка подготовки или завершения теста: \(error)")
    }
}

func XCTFail(_ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    LocalTestReport.fail(message, file: file, line: line)
}

func XCTAssertTrue(_ expression: @autoclosure () throws -> Bool, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    LocalTestReport.assertions += 1
    do {
        if try !expression() { XCTFail("Ожидалось true. \(message)", file: file, line: line) }
    } catch {
        XCTFail("Ошибка выражения: \(error). \(message)", file: file, line: line)
    }
}

func XCTAssertFalse(_ expression: @autoclosure () throws -> Bool, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(try !expression(), message, file: file, line: line)
}

func XCTAssertEqual<T: Equatable>(_ expression: @autoclosure () throws -> T, _ expected: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    LocalTestReport.assertions += 1
    do {
        let value = try expression()
        let other = try expected()
        if value != other { XCTFail("\(value) != \(other). \(message)", file: file, line: line) }
    } catch {
        XCTFail("Ошибка выражения: \(error). \(message)", file: file, line: line)
    }
}

func XCTAssertEqual(_ expression: @autoclosure () throws -> Double, _ expected: @autoclosure () throws -> Double, accuracy: Double, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    LocalTestReport.assertions += 1
    do {
        let value = try expression()
        let other = try expected()
        if !(abs(value - other) <= accuracy) {
            XCTFail("\(value) != \(other) с точностью \(accuracy). \(message)", file: file, line: line)
        }
    } catch {
        XCTFail("Ошибка выражения: \(error). \(message)", file: file, line: line)
    }
}

func XCTAssertNotEqual<T: Equatable>(_ expression: @autoclosure () throws -> T, _ other: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(try expression() != other(), message, file: file, line: line)
}

func XCTAssertGreaterThan<T: Comparable>(_ expression: @autoclosure () throws -> T, _ other: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(try expression() > other(), message, file: file, line: line)
}

func XCTAssertNil<T>(_ expression: @autoclosure () throws -> T?, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(try expression() == nil, message, file: file, line: line)
}

func XCTAssertNotNil<T>(_ expression: @autoclosure () throws -> T?, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(try expression() != nil, message, file: file, line: line)
}

func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) throws -> T {
    LocalTestReport.assertions += 1
    guard let value = try expression() else {
        XCTFail("Значение отсутствует. \(message)", file: file, line: line)
        throw LocalAssertionError.nilValue
    }
    return value
}

func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (Error) -> Void = { _ in }) {
    LocalTestReport.assertions += 1
    do {
        _ = try expression()
        XCTFail("Ожидалась ошибка. \(message)", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
