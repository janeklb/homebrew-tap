class GitStack < Formula
  desc "Manage personal stacked PR branches"
  homepage "https://github.com/janeklb/git-stack"
  url "https://github.com/janeklb/git-stack/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "a889c5d53ffd7ab47792e476eb00cc96819558ffe6b2f38413e68eea8e2538f3"
  license "MIT"
  head "https://github.com/janeklb/git-stack.git", branch: "main"

  depends_on "go" => :build

  def install
    ldflags = [
      "-s",
      "-w",
      "-X github.com/janeklb/git-stack/internal/app.buildVersion=#{version}",
      "-X github.com/janeklb/git-stack/internal/app.buildCommit=5d55991b44821d2593bb29eda142089bfaa0310c",
      "-X github.com/janeklb/git-stack/internal/app.buildDate=2026-05-07T14:10:42Z",
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/git-stack"

    generate_completions_from_executable(bin/"git-stack", "completion")
  end

  test do
    assert_match "version=#{version}", shell_output("#{bin}/git-stack version")
    assert_match "_git-stack", shell_output("#{bin}/git-stack completion bash")
  end
end
