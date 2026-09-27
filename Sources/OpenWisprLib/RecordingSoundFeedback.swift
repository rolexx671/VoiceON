import AppKit

/// Сохраняет системные звуки в памяти, пока AppKit воспроизводит их асинхронно.
final class RecordingSoundFeedback {
    private let started = NSSound(named: NSSound.Name("Tink"))
    private let stopped = NSSound(named: NSSound.Name("Pop"))

    func playStarted() {
        started?.play()
    }

    func playStopped() {
        stopped?.play()
    }
}
