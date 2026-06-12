class ColdfireAdminAssetDownloadStrategy < CurlDownloadStrategy
  # Downloads a release ASSET (the prebuilt tarball uploaded by the
  # Release coldfire-admin GitHub Actions workflow) from a private repo
  # via the GH API + bearer token. The asset name is embedded in the
  # formula URL; we resolve it to the API asset endpoint and stream
  # the binary blob with Accept: application/octet-stream.
  def initialize(url, name, version, **meta)
    super
    @owner = "getcoldfire"
    @repo = "coldfire"
    @tag = "coldfire-admin-v#{version}"
    @asset_name = "coldfire-admin-#{version}-darwin-arm64.tar.gz"
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

class ColdfireAdmin < Formula
  desc "Operator CLI for the Coldfire coordinator (admin endpoints)"
  homepage "https://getcoldfire.com"
  url "https://github.com/getcoldfire/coldfire/releases/download/coldfire-admin-v0.1.1/coldfire-admin-0.1.1-darwin-arm64.tar.gz",
      using: ColdfireAdminAssetDownloadStrategy
  version "0.1.1"
  sha256 "9f38447e88e6c72c4fa07cac564ec8a6f83aaa6ff15cda3fd28cf6ff1da3ccee"
  license "MIT"

  depends_on arch: :arm64
  depends_on macos: :ventura

  def install
    bin.install "coldfire-admin"
    # `system` raises on exit 1 starting in brew 6.0.1, which trips when
    # com.apple.quarantine isn't present (the common case for curl-downloaded
    # tarballs). `quiet_system` returns false instead.
    quiet_system "xattr", "-dr", "com.apple.quarantine", bin/"coldfire-admin"
  end

  def caveats
    <<~EOS
      coldfire-admin needs an admin API token to talk to the coordinator. Two
      sources, checked in order:

        1. The COLDFIRE_API_TOKEN env var (wins if set).
        2. A sops-encrypted YAML config at
           ~/.config/coldfire-admin/config.enc.yaml, with fields:
             api_token: <admin token>
             coordinator_url: https://coordinator.getcoldfire.com   # optional

      Optional: install `sops` (`brew install sops`) only if you intend to
      use the config-file fallback. Operators using the env-var path do
      not need it.

      Default coordinator URL: https://coordinator.getcoldfire.com
      Override per-invocation with --coordinator-url <URL>.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/coldfire-admin --version")
  end
end
