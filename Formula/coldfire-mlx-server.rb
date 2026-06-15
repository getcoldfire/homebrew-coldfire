class ColdfireMlxServer < Formula
  desc "Renamed: see coldfire-inference-server"
  homepage "https://github.com/getcoldfire/inference-server"
  url "https://github.com/getcoldfire/inference-server/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "54c22d6a1fd509e996bbb1969cce4e56104513914da82cbe464deb0ab3d414b3"
  license "MIT"

  disable! date: "2026-06-15",
           because: "renamed to coldfire-inference-server in v0.4.0; " \
                    "run: brew uninstall coldfire-mlx-server && " \
                    "brew install getcoldfire/coldfire/coldfire-inference-server"
end
