class ColdfireNodeAssetDownloadStrategy < CurlDownloadStrategy
  # Streams a release ASSET from coord-v2's asset-proxy endpoint. The
  # bearer token (HOMEBREW_COLDFIRE_INSTALL_TOKEN) is minted at invite-
  # burn time and validated server-side against the invites DB; coord-v2
  # uses its own server-side bot token to fetch the actual binary from
  # the private getcoldfire/coldfire GitHub releases. Recipients never
  # see a GitHub token of their own.
  #
  # The HOMEBREW_ prefix on the env var is load-bearing: Homebrew
  # sanitizes the formula execution environment and strips any var
  # outside its HOMEBREW_* / system allowlist. Names without the prefix
  # arrive here as nil even when the parent shell exported them. The
  # install script (coord-v2 routes/install.py) exports the same name.
  def initialize(url, name, version, **meta)
    super
    @asset_name = "coldfire-node-#{version}-darwin-arm64.tar.gz"
    @proxy_url = "https://coordinator.getcoldfire.com/assets/coldfire-node/#{version}/#{@asset_name}"
  end

  def _fetch(url:, resolved_url:, timeout:)
    token = ENV["HOMEBREW_COLDFIRE_INSTALL_TOKEN"]
    raise CurlDownloadStrategyError,
          "HOMEBREW_COLDFIRE_INSTALL_TOKEN must be set. Open a fresh invite link " \
          "(https://getcoldfire.com/install?code=<your-code>) and re-run the " \
          "curl command from that page — it exports this for the install. If " \
          "you're seeing this AFTER running the curl from the invite page, " \
          "email support@getcoldfire.com with the install link." unless token

    curl_download @proxy_url,
                  "--header", "Authorization: Bearer #{token}",
                  "--header", "Accept: application/octet-stream",
                  "--location",
                  to: temporary_path,
                  timeout: timeout
  end
end

class ColdfireNode < Formula
  desc "Coldfire v2 inference daemon for Apple Silicon"
  homepage "https://getcoldfire.com"
  url "https://github.com/getcoldfire/coldfire/releases/download/coldfire-node-v0.1.13/coldfire-node-0.1.13-darwin-arm64.tar.gz",
      using: ColdfireNodeAssetDownloadStrategy
  version "0.1.13"
  sha256 "fafdd466e57ba72e34c896e1e835236ac9e331a2c7255b2c837b843293cd09d8"
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
