class Coldfire < Formula
  include Language::Python::Virtualenv

  desc "Local LLM inference CLI for macOS"
  homepage "https://getcoldfire.com"
  url "https://github.com/getcoldfire/coldfire/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "5daa1b924bab591e1e16bd3f05d22727a623361751bf0a3f6a59b96e99246a44"
  license "MIT"
  version "0.1.0"

  depends_on "python@3.12"
  depends_on :macos

  def install
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install_and_link buildpath
  end

  test do
    system bin/"coldfire", "--help"
  end
end
