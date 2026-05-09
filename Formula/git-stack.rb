class GitStack < Formula
  desc "Manage personal stacked PR branches"
  homepage "https://github.com/janeklb/git-stack"
  url "https://github.com/janeklb/git-stack/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "4d2267270a08734e4127daffa101c172c41877e903ad038248f7484769370ff3"
  license "MIT"
  head "https://github.com/janeklb/git-stack.git", branch: "main"

  depends_on "go" => :build

  def install
    ldflags = [
      "-s",
      "-w",
      "-X github.com/janeklb/git-stack/internal/app.buildVersion=#{version}",
      "-X github.com/janeklb/git-stack/internal/app.buildCommit=5fbf25873941bb24ff6669626b9d413f1baecfe1",
      "-X github.com/janeklb/git-stack/internal/app.buildDate=2026-05-09T10:08:36Z",
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/git-stack"

    generate_completions_from_executable(bin/"git-stack", "completion")
  end

  test do
    assert_match "version=#{version}", shell_output("#{bin}/git-stack version")
    assert_match "_git-stack", shell_output("#{bin}/git-stack completion bash")
  end
end
