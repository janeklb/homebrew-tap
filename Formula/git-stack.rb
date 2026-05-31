class GitStack < Formula
  desc "Manage personal stacked PR branches"
  homepage "https://github.com/janeklb/git-stack"
  url "https://github.com/janeklb/git-stack/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "9037adce7d9db2259a892abb4380a81851de561e93d0d3f6c4a60940132a395c"
  license "MIT"
  head "https://github.com/janeklb/git-stack.git", branch: "main"

  depends_on "go" => :build

  def install
    ldflags = [
      "-s",
      "-w",
      "-X github.com/janeklb/git-stack/internal/app.buildVersion=#{version}",
      "-X github.com/janeklb/git-stack/internal/app.buildCommit=dd6fa0d463abeb76a69ff1d47c1eeec21a58701f",
      "-X github.com/janeklb/git-stack/internal/app.buildDate=2026-05-31T14:19:29Z",
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/git-stack"

    generate_completions_from_executable(bin/"git-stack", "completion")
  end

  test do
    assert_match "version=#{version}", shell_output("#{bin}/git-stack version")
    assert_match "_git-stack", shell_output("#{bin}/git-stack completion bash")
  end
end
