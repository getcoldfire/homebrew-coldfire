cask "coldfire" do
  version "0.2.14"
  sha256 "0af487d0e3e27b8adfa8ed8a756e6062919889be047a12b8d5088e64317d2a93"

  url "https://dl.getcoldfire.com/app/Coldfire-#{version}.dmg",
      verified: "dl.getcoldfire.com/app/"
  name "Coldfire"
  desc "Menu-bar app to contribute idle GPU compute to the Coldfire inference network"
  homepage "https://getcoldfire.com/"

  # The app also self-updates from the same manifest; livecheck lets `brew` see new
  # versions, and auto_updates tells brew the app manages its own updates so
  # `brew upgrade` won't fight the in-app updater over /Applications/Coldfire.app.
  livecheck do
    url "https://dl.getcoldfire.com/app/manifest.json"
    strategy :json do |json|
      json["version"]
    end
  end

  auto_updates true
  depends_on macos: :sonoma
  depends_on arch: :arm64

  app "Coldfire.app"

  zap trash: [
    "~/Library/Application Support/Coldfire",
    "~/Library/Caches/com.getcoldfire.agent",
    "~/Library/HTTPStorages/com.getcoldfire.agent",
    "~/Library/Preferences/com.getcoldfire.agent.plist",
  ]
end
