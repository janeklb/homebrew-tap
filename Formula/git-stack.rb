class GitStack < Formula
  desc "Manage personal stacked PR branches"
  homepage "https://github.com/janeklb/git-stack"
  url "https://github.com/janeklb/git-stack/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0691c036db530d6e8703ccc4f8c11b160ab64f5546ef6dc7090425cb43c49a27"
  license "MIT"
  head "https://github.com/janeklb/git-stack.git", branch: "main"

  depends_on "go" => :build

  def install
    ldflags = [
      "-s",
      "-w",
      "-X github.com/janeklb/git-stack/internal/app.buildVersion=#{version}",
      "-X github.com/janeklb/git-stack/internal/app.buildCommit=9db79b657860817bd4017781ce52e61e1e2ab269",
      "-X github.com/janeklb/git-stack/internal/app.buildDate=2026-04-17T18:25:24Z",
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/git-stack"

    generate_completions_from_executable(bin/"git-stack", "completion")
  end

  test do
    assert_match "version=#{version}", shell_output("#{bin}/git-stack version")
    assert_match "_git-stack", shell_output("#{bin}/git-stack completion bash")
  end
end
