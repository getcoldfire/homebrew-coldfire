class ColdfireNode < Formula
  desc "Coldfire v2 inference daemon for Apple Silicon"
  homepage "https://getcoldfire.com"
  url "https://github.com/getcoldfire/homebrew-coldfire/releases/download/coldfire-node-v0.1.37/coldfire-node-0.1.37-darwin-arm64.tar.gz"
  version "0.1.37"
  sha256 "9235e68a737d959433c1d23be6646310c674758e8b89adb0068bde6ea9be55e4"
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

  # post_install fires after every install / upgrade. We can't actually
  # run `coldfire-ctl restart` from here — Homebrew's install sandbox
  # blocks launchctl bootstrap calls, and detached subshells get reaped
  # with the sandbox. What we CAN do is detect a running daemon and
  # print an unmissable recipe so the operator knows the one command
  # to run. The recipe is a single line; in practice it's what zero-
  # touch would have given them anyway.
  def post_install
    return if ENV["COLDFIRE_NO_AUTO_RESTART"]
    require "etc"
    # Etc.getpwuid(Process.uid).dir reads the operator's real home from
    # the passwd entry. Dir.home / ~ expansion both go through
    # ENV["HOME"], which Homebrew's install sandbox rewrites to a
    # /private/tmp/coldfire-node-postinstall-… tmpdir.
    home = Etc.getpwuid(Process.uid).dir
    socket = File.join(home, ".coldfire", "daemon.sock")
    return unless File.socket?(socket)
    ohai "A coldfire-node daemon is running. Restart it so the new binary takes effect:"
    ohai "    coldfire-ctl restart"
    ohai "(`coldfire-ctl restart` is a single-command wrapper around stop + launchctl bootstrap)"
  end

  def caveats
    <<~EOS
      Before running, configure Coldfire with an invite code or interactively:

        coldfire-ctl setup --invite-code <code>     # invite path (auto-approve)
        coldfire-ctl setup                          # interactive (manual approval)

      The setup wizard writes ~/.coldfire/config.yaml and the launchd plist
      at ~/Library/LaunchAgents/com.getcoldfire.node.plist, then bootstraps
      the daemon. `coldfire-ctl status` shows daemon + bridge health.

      Upgrades:
        brew upgrade coldfire-node       # then: coldfire-ctl restart
        coldfire-ctl restart             # one-command stop + launchctl bootstrap

      post_install prints the restart recipe when a daemon is running;
      auto-execution isn't possible because Homebrew's install sandbox
      blocks the launchctl bootstrap that restart needs. Suppress the
      reminder with COLDFIRE_NO_AUTO_RESTART=1 if you handle restarts
      elsewhere.

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
