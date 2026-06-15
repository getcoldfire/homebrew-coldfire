class ColdfireMlxServer < Formula
  desc "Renamed: see coldfire-inference-server"
  homepage "https://github.com/getcoldfire/inference-server"
  url "https://github.com/getcoldfire/inference-server/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "75bd2e93737ca9eaf76ba27482ae436da2d715ab1fc26d22528c55501ad4ff0a"
  license "MIT"

  disable! date: "2026-06-15",
           because: "renamed to coldfire-inference-server in v0.4.0; " \
                    "run: brew uninstall coldfire-mlx-server && " \
                    "brew install getcoldfire/coldfire/coldfire-inference-server"
end
