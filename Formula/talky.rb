# Homebrew FORMULA for the Talky CLI + local-gateway daemon (T-PACKAGE-INSTALLER).
#
# A FORMULA (not a cask): casks model GUI .app bundles and do NOT register a
# `brew services` daemon. The `service` block below is the supported way to register
# the local-gateway under launchd — exactly the laptop Box Gateway model (ADR 0017).
# macOS-only artifacts (no `on_linux`): Linux installs via apt, not Linuxbrew. Lives
# in the custom tap `sriviswanath/homebrew-talky`;
# {{...}} placeholders are stamped at release time by build.sh (version + sha256).
class Talky < Formula
  desc "Talky CLI + local-gateway daemon (the laptop Box Gateway)"
  homepage "https://talky.so"
  version "0.1.0-34-g687af9dd"

  on_macos do
    on_arm do
      url "https://dl.talky.so/v0.1.0-34-g687af9dd/talky_0.1.0-34-g687af9dd_darwin_arm64.tar.gz"
      sha256 "d1c5854442bf1eb6ddd43d1d19aae27b4d98d5dc250b8ff23c2923663a99a8a8"
    end
    on_intel do
      url "https://dl.talky.so/v0.1.0-34-g687af9dd/talky_0.1.0-34-g687af9dd_darwin_amd64.tar.gz"
      sha256 "9ce7b997bfeff0a3ae75818f1c7885e9fabb2fe5aaa3d24c18f35595c9c646dd"
    end
  end

  # The daemon spawns Talky-branded tmux sessions (ADR 0018) — tmux must be present.
  depends_on "tmux"

  def install
    bin.install "talky"
    bin.install "talky-local-gateway"
  end

  # `brew services start talky` registers the daemon under launchd (per-user). The
  # daemon dials OUT to the hub (no inbound) and reads the owner-only config that
  # `talky login` writes when it registers this machine as a box (ADR 0028).
  service do
    run [opt_bin/"talky-local-gateway", "--config", "#{Dir.home}/.talky/local-gateway.json"]
    keep_alive true
    run_at_load true
    # Explicit PATH: launchd's default (/usr/bin:/bin:/usr/sbin:/sbin) misses Homebrew
    # and common user bins, so the daemon could not find tmux or the agent CLIs it
    # spawns. ONLY PATH + TALKY_HOME here — never secrets (tokens live in owner-only
    # files under ~/.talky).
    environment_variables PATH:       "#{Dir.home}/.local/bin:#{HOMEBREW_PREFIX}/bin:#{HOMEBREW_PREFIX}/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
                          TALKY_HOME: "#{Dir.home}/.talky"
    log_path var/"log/talky/local-gateway.out.log"
    error_log_path var/"log/talky/local-gateway.err.log"
  end

  def caveats
    <<~EOS
      Next: run `talky login` — it signs you in AND registers this Mac as one of
      your boxes; the daemon (brew service) starts automatically.
      State lives in ~/.talky (local-gateway.json + proxy.token).
      Troubleshooting — if the daemon is not running after login, start it with
        brew services start sriviswanath/talky/talky
    EOS
  end

  test do
    assert_match "talky #{version}", shell_output("#{bin}/talky --version")
  end
end
