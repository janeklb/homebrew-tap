class GitStack < Formula
  desc "Manage personal stacked PR branches"
  homepage "https://github.com/janeklb/git-stack"
  url "https://github.com/janeklb/git-stack/archive/refs/tags/v0.2.2.tar.gz"
  sha256 "c0262bb02ba40b8939efc0a6e58c2a204b9285fa68a9b75e3b87cb1fcb233ab8"
  license "MIT"
  head "https://github.com/janeklb/git-stack.git", branch: "main"

  depends_on "go" => :build

  def install
    ldflags = [
      "-s",
      "-w",
      "-X github.com/janeklb/git-stack/internal/app.buildVersion=#{version}",
      "-X github.com/janeklb/git-stack/internal/app.buildCommit=2444db9d19e39a1ea2a2d2bb9cca016a786de9aa",
      "-X github.com/janeklb/git-stack/internal/app.buildDate=2026-05-08T23:35:42Z",
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/git-stack"

    generate_completions_from_executable(bin/"git-stack", "completion")
  end

  test do
    assert_match "version=#{version}", shell_output("#{bin}/git-stack version")
    assert_match "_git-stack", shell_output("#{bin}/git-stack completion bash")
  end
end
