import XCTest
@testable import OpenWisprLib

final class ModelDownloaderTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("voiceon-model-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testRejectsMissingModel() {
        XCTAssertFalse(ModelDownloader.isValidGGMLFile(at: directory.appendingPathComponent("missing.bin")))
    }

    func testRejectsHTMLAndJSONErrorResponses() throws {
        for (name, text) in [("proxy.bin", "<!DOCTYPE html><html>Ошибка прокси</html>"), ("error.bin", "{\"error\":\"denied\"}")] {
            let path = directory.appendingPathComponent(name)
            try Data(text.utf8).write(to: path)
            XCTAssertFalse(ModelDownloader.isValidGGMLFile(at: path))
        }
    }

    func testRejectsEmptyAndTruncatedSignatures() throws {
        for count in 0..<4 {
            let path = directory.appendingPathComponent("short-\(count).bin")
            try Data([0x6c, 0x6d, 0x67].prefix(count)).write(to: path)
            XCTAssertFalse(ModelDownloader.isValidGGMLFile(at: path))
        }
    }

    func testRecognizesSupportedModelSignatures() throws {
        // Проверяется только формат заголовка; целостность весов проверяет движок Whisper.
        let signatures: [[UInt8]] = [[0x6c, 0x6d, 0x67, 0x67], [0x74, 0x6a, 0x67, 0x67], [0x47, 0x47, 0x55, 0x46]]
        for (index, signature) in signatures.enumerated() {
            let path = directory.appendingPathComponent("header-\(index).bin")
            try Data(signature + Array(repeating: 0, count: 32)).write(to: path)
            XCTAssertTrue(ModelDownloader.isValidGGMLFile(at: path))
        }
    }

    func testRejectsUnrecognizedSignature() throws {
        let path = directory.appendingPathComponent("unknown.bin")
        try Data([0, 1, 2, 3, 4, 5]).write(to: path)
        XCTAssertFalse(ModelDownloader.isValidGGMLFile(at: path))
    }
}
