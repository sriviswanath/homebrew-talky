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
  version "0.0.0+gf1f8a212"

  on_macos do
    on_arm do
      url "https://dl.talky.so/v0.0.0+gf1f8a212/talky_0.0.0+gf1f8a212_darwin_arm64.tar.gz"
      sha256 "9d92326219949af969287ed3758d8e7721ae950a7957df87c092ea14abbfbb4d"
    end
    on_intel do
      url "https://dl.talky.so/v0.0.0+gf1f8a212/talky_0.0.0+gf1f8a212_darwin_amd64.tar.gz"
      sha256 "3edfe92fe80777acf4766e2fc1646afc279f98072357509c4cdc3425fee39bd5"
    end
  end

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
    environment_variables TALKY_HOME: "#{Dir.home}/.talky"
    log_path var/"log/talky/local-gateway.out.log"
    error_log_path var/"log/talky/local-gateway.err.log"
  end

  def caveats
    <<~EOS
      Sign in first, then start the daemon:
        run the iOS laptop-link command
        brew services start talky
      State lives in ~/.talky (local-gateway.json + loopback proxy.token).
    EOS
  end

  test do
    assert_match "talky #{version}", shell_output("#{bin}/talky --version")
  end
end
