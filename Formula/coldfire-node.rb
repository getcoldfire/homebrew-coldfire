class ColdfireNode < Formula
  desc "Coldfire v2 distributed inference daemon for Apple Silicon"
  homepage "https://getcoldfire.com"
  url "https://github.com/getcoldfire/coldfire/releases/download/coldfire-node-v0.1.0-rc.1/coldfire-node-0.1.0-rc.1-darwin-arm64.tar.gz"
  version "0.1.0-rc.1"
  sha256 "REPLACE_AT_RELEASE_TIME"
  license "MIT"

  depends_on arch: :arm64
  depends_on macos: :ventura

  def install
    bin.install "coldfire-node"
    bin.install "coldfire-ctl"
    system "xattr", "-dr", "com.apple.quarantine", bin/"coldfire-node"
    system "xattr", "-dr", "com.apple.quarantine", bin/"coldfire-ctl"
  end

  def caveats
    <<~EOS
      Before running, configure Coldfire with an invite code or interactively:

        coldfire-ctl setup --install-nonce <nonce>     # nonce path (auto-approve)
        coldfire-ctl setup                              # interactive (manual approval)

      The setup wizard writes ~/.coldfire/config.yaml and the launchd plist
      at ~/Library/LaunchAgents/com.getcoldfire.node.plist, then bootstraps
      the daemon. `coldfire-ctl status` shows daemon + bridge health.

      To uninstall:
        coldfire-ctl uninstall
        brew uninstall coldfire-node
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/coldfire-ctl --version")
    assert_match version.to_s, shell_output("#{bin}/coldfire-node --version")
  end
end
