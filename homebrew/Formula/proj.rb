class Proj < Formula
  desc "Project Hub in your Terminal — links, time tracking, AI sessions per project"
  homepage "https://github.com/gbechtold/proj"
  url "https://github.com/gbechtold/proj/archive/refs/tags/v1.0.0.tar.gz"
  # sha256 "UPDATE_AFTER_RELEASE"
  license "MIT"

  depends_on "python@3"
  depends_on "zsh" => :optional

  def install
    prefix.install "src"
    prefix.install "install.sh"
  end

  def caveats
    <<~EOS
      Add this to your ~/.zshrc:

        source "#{opt_prefix}/src/proj.zsh"

      Then restart your shell or run:

        source ~/.zshrc

      Quick start:
        proj          # interactive menu
        proj demo     # load demo projects
        proj help     # all commands
    EOS
  end

  test do
    system "python3", "-c", "import json"
    assert_predicate prefix/"src/proj.zsh", :exist?
    assert_predicate prefix/"src/proj_helper.py", :exist?
  end
end
