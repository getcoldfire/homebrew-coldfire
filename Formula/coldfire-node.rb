class ColdfireNode < Formula
  desc "Coldfire v2 inference daemon for Apple Silicon"
  homepage "https://getcoldfire.com"
  url "https://github.com/getcoldfire/homebrew-coldfire/releases/download/coldfire-node-v0.1.23/coldfire-node-0.1.23-darwin-arm64.tar.gz"
  version "0.1.23"
  sha256 "e0695f9d7205bcc39a4c3a118574f9aa642a0eb2cda0b46f5183eae372ceec27"
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

  # post_install fires after every install / upgrade. If a daemon is
  # currently running on this user, automatically restart it so the new
  # binary takes effect — operators no longer need to remember the
  # `coldfire-ctl stop && launchctl bootstrap …` dance after every
  # `brew upgrade coldfire-node`. Detection is purely a socket-existence
  # check (~/.coldfire/daemon.sock); if no daemon is running, this is a
  # silent no-op. Opt out by setting COLDFIRE_NO_AUTO_RESTART=1 in the
  # brew-invoking shell (also gets passed through Homebrew). The
  # `coldfire-ctl restart` invocation handles the launchd job-domain
  # teardown race that breaks the bare bootstrap.
  def post_install
    if ENV["COLDFIRE_NO_AUTO_RESTART"]
      ohai "coldfire-node post_install: COLDFIRE_NO_AUTO_RESTART set, skipping auto-restart"
      return
    end
    # Homebrew's install sandbox mutates ENV["HOME"] (and therefore
    # Dir.home / ~ expansion) to a tmpdir like
    # /private/tmp/coldfire-node-postinstall-…  — operator's real home
    # comes from the passwd entry for the running uid, which the
    # sandbox doesn't touch.
    require "etc"
    home = Etc.getpwuid(Process.uid).dir
    socket = File.join(home, ".coldfire", "daemon.sock")
    unless File.socket?(socket)
      # Silent no-op — most installs are first-time (no daemon yet) or
      # CI-style (no operator daemon to bother).
      return
    end
    ohai "Restarting coldfire-node so the new binary takes effect (set COLDFIRE_NO_AUTO_RESTART=1 to opt out)"
    # Pass the operator's real HOME so coldfire-ctl's ~/.coldfire and
    # ~/Library/LaunchAgents expansions go to the operator's tree, not
    # the sandbox tmpdir. Pass --socket explicitly as belt-and-suspenders
    # for the IPC path (the launchctl plist path is derived from the
    # label inside coldfire-ctl, so HOME has to be right for that too).
    system({ "HOME" => home }, bin/"coldfire-ctl", "--socket", socket, "restart")
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
        brew upgrade coldfire-node       # restarts a running daemon automatically
        COLDFIRE_NO_AUTO_RESTART=1 brew upgrade coldfire-node   # skip the restart
        coldfire-ctl restart             # one-command stop + bootstrap

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
