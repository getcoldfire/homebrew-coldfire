class ColdfireNodeAssetDownloadStrategy < CurlDownloadStrategy
  # Downloads a release ASSET (the prebuilt tarball uploaded by the
  # Release coldfire-node GitHub Actions workflow) from a private repo
  # via the GH API + bearer token. The asset name is embedded in the
  # formula URL; we resolve it to the API asset endpoint and stream
  # the binary blob with Accept: application/octet-stream.
  def initialize(url, name, version, **meta)
    super
    @owner = "getcoldfire"
    @repo = "coldfire"
    @tag = "coldfire-node-v#{version}"
    @asset_name = "coldfire-node-#{version}-darwin-arm64.tar.gz"
  end

  def _fetch(url:, resolved_url:, timeout:)
    token = ENV["HOMEBREW_GITHUB_API_TOKEN"]
    raise CurlDownloadStrategyError,
          "HOMEBREW_GITHUB_API_TOKEN must be set to install this formula." unless token

    # 1. Resolve the asset_id from the release-by-tag endpoint.
    release_url = "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}"
    release_json, = curl_output "--silent",
                                "--fail",
                                "--header", "Authorization: Bearer #{token}",
                                "--header", "Accept: application/vnd.github.v3+json",
                                release_url
    require "json"
    release = JSON.parse(release_json)
    asset = release.fetch("assets", []).find { |a| a["name"] == @asset_name }
    raise CurlDownloadStrategyError,
          "asset #{@asset_name} not found on release #{@tag}" if asset.nil?

    # 2. Stream the asset blob.
    asset_url = "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset["id"]}"
    curl_download asset_url,
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
  url "https://github.com/getcoldfire/coldfire/releases/download/coldfire-node-v0.1.1/coldfire-node-0.1.1-darwin-arm64.tar.gz",
      using: ColdfireNodeAssetDownloadStrategy
  version "0.1.1"
  sha256 "d641551cdf8c19ccba346d0d969494d82d8a597351611c74481036ab71e79092"
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
