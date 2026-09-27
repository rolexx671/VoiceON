# Исторический путь формулы сохранён для понятного сообщения при её вызове.
# VoiceON поставляется автономным приложением; установка через эту формулу отключена.
class OpenWispr < Formula
  desc "VoiceON — голосовой ввод на русском для macOS"
  homepage "https://github.com/rolexx671/VoiceON"
  head "https://github.com/rolexx671/VoiceON.git", branch: "main"
  license "MIT"
  depends_on :macos
  disable! date: "2026-09-28", because: "распространяется как автономный образ VoiceON.dmg; скачайте его со страницы выпусков VoiceON"

  def install
    odie "Установка через Homebrew не поддерживается. Откройте https://github.com/rolexx671/VoiceON/releases и установите VoiceON.dmg."
  end
end
