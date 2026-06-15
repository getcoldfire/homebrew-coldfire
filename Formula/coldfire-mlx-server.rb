class ColdfireMlxServer < Formula
  desc "Renamed: see coldfire-inference-server"
  homepage "https://github.com/getcoldfire/inference-server"
  url "https://github.com/getcoldfire/inference-server/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "993cef7ecf470015990af1ebf401d486650b5ac510511ff635d2d1fd32545b15"
  license "MIT"

  disable! date: "2026-06-15",
           because: "renamed to coldfire-inference-server in v0.4.0; " \
                    "run: brew uninstall coldfire-mlx-server && " \
                    "brew install getcoldfire/coldfire/coldfire-inference-server"
end
