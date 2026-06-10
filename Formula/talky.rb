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
  version "0.0.0+g35adf68d"

  on_macos do
    on_arm do
      url "https://dl.talky.so/v0.0.0+g35adf68d/talky_0.0.0+g35adf68d_darwin_arm64.tar.gz"
      sha256 "5a6eefc56a898cb301052adc003bb3cb244bc021bb467c1ea4b7e2cd3977876b"
    end
    on_intel do
      url "https://dl.talky.so/v0.0.0+g35adf68d/talky_0.0.0+g35adf68d_darwin_amd64.tar.gz"
      sha256 "6207c22c0e5d8392f064e7006c2beddf0e3062397f36faaca74174d4a953e782"
    end
  end

  # The daemon spawns Talky-branded tmux sessions (ADR 0018) — tmux must be present.
  depends_on "tmux"

  def install
    bin.install "talky"
    bin.install "talky-local-gateway"
  end

  # `brew services start talky` registers the daemon under launchd (per-user). The
  # daemon dials OUT to the hub (no inbound) and reads the owner-only link config
  # created by the iOS laptop-link command.
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
      Link this Mac from your phone:
        1. In Talky iOS, open Boxes and tap "Link Mac".
        2. Run the command it shows in this terminal.
      The link command writes ~/.talky/local-gateway.json and (re)starts the
      brew service. State lives in ~/.talky (local-gateway.json + proxy.token).
    EOS
  end

  test do
    assert_match "talky #{version}", shell_output("#{bin}/talky --version")
  end
end
