cask "shelf" do
  version "__VERSION__"
  sha256 "__SHA256__"

  url "https://github.com/fatihsen-dev/shelf/releases/download/v#{version}/Shelf-#{version}.zip"
  name "Shelf"
  desc "Clipboard manager for macOS"
  homepage "https://github.com/fatihsen-dev/shelf"

  auto_updates false
  depends_on macos: ">= :ventura"

  app "Shelf.app"

  zap trash: [
    "~/Library/Application Support/Shelf",
    "~/Library/Preferences/com.fatihsen.shelf.plist",
    "~/Library/Caches/com.fatihsen.shelf",
  ]
end
