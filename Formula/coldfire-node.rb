class ColdfireNode < Formula
  desc "Coldfire v2 inference daemon for Apple Silicon"
  homepage "https://getcoldfire.com"
  url "https://github.com/getcoldfire/homebrew-coldfire/releases/download/coldfire-node-v0.1.20/coldfire-node-0.1.20-darwin-arm64.tar.gz"
  version "0.1.20"
  sha256 "be339b57c41a6d8ccaa3b954cc285e3244102a7f0b5ab99e2a09506c2cd306bd"
  # Proprietary: see LICENSE inside the tarball. The shipped binaries are
  # not open source even though the formula is distributed via a public tap.
  license :cannot_represent

  depends_on arch: :arm64
  depends_on macos: :ventura

  def install
    bin.install "coldfire-node"
    bin.install "coldfire-ctl"
    # Brew downloads via curl, which doesn't set com.apple.quarantine, so
    # these xattr removes are typically no-ops. `system` raises on exit 1
    # ("No such xattr") starting in brew 6.0.1; `quiet_system` returns
    # false instead, keeping the install robust if the attr is absent.
    quiet_system "xattr", "-dr", "com.apple.quarantine", bin/"coldfire-node"
    quiet_system "xattr", "-dr", "com.apple.quarantine", bin/"coldfire-ctl"
  end

  def caveats
    <<~EOS
      Before running, configure Coldfire with an invite code or interactively:

        coldfire-ctl setup --invite-code <code>     # invite path (auto-approve)
        coldfire-ctl setup                          # interactive (manual approval)

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
