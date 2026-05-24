class Coldfire < Formula
  include Language::Python::Virtualenv

  desc "Local LLM inference CLI for macOS"
  homepage "https://getcoldfire.com"
  url "https://github.com/getcoldfire/coldfire/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "b19cb0fb53310ffa7c7bbe8e716a31071b74d89f601c93b4579713a9cc543610"
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
