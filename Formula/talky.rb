# Homebrew FORMULA for the Talky CLI + local-gateway daemon (T-PACKAGE-INSTALLER).
#
# A FORMULA (not a cask): casks model GUI .app bundles and do NOT register a
# `brew services` daemon. The `service` block below is the supported way to register
# the local-gateway under launchd — exactly the laptop Box Gateway model (ADR 0021).
# macOS-only artifacts (no `on_linux`): Linux installs via apt, not Linuxbrew. Lives
# in the custom tap `sriviswanath/homebrew-talky`;
# {{...}} placeholders are stamped at release time by build.sh (version + sha256).
class Talky < Formula
  desc "Talky CLI + local-gateway daemon (the laptop Box Gateway)"
  homepage "https://talky.so"
  version "0.1.0-1616-gaaa551fd"

  on_macos do
    on_arm do
      url "https://dl.talky.so/v0.1.0-1616-gaaa551fd/talky_0.1.0-1616-gaaa551fd_darwin_arm64.tar.gz"
      sha256 "c9adf80b5feabb047ef462105285773cda6a0945f2fc49c6db73484fceb987a9"
    end
    on_intel do
      url "https://dl.talky.so/v0.1.0-1616-gaaa551fd/talky_0.1.0-1616-gaaa551fd_darwin_amd64.tar.gz"
      sha256 "a48316dae30863fbdfa9df85351cc3b9fe0352a78447df5d6d19ad4c8bc5e210"
    end
  end

  # The daemon spawns Talky-branded tmux sessions (ADR 0022) — tmux must be present.
  depends_on "tmux"
  # The laptop Hermes runtime runs INSIDE a Lima microVM (the content-isolated boundary,
  # ADR 0031 §7) — pull Lima in here so a fresh `brew install` of talky brings everything
  # `talky install hermes` needs (macOS bundles the Virtualization.framework hypervisor,
  # so Lima is the only extra host dependency). One-step setup, not a manual prerequisite.
  depends_on "lima"

  def install
    bin.install "talky"
    bin.install "talky-local-gateway"
    # The agent-status writer the Claude/Codex hooks invoke. Installed as a sibling of
    # talky so `talky login`/`talky watch` wires a binary that actually exists.
    bin.install "talky-status"
  end

  # `brew services start talky` registers the daemon under launchd (per-user). The
  # daemon dials OUT to the hub (no inbound) and reads the owner-only config that
  # `talky login` writes when it registers this machine as a box (ADR 0010).
  service do
    run [opt_bin/"talky-local-gateway", "--config", "#{Dir.home}/.talky/local-gateway.json"]
    keep_alive true
    run_at_load true
    # Explicit PATH: launchd's default (/usr/bin:/bin:/usr/sbin:/sbin) misses Homebrew
    # and common user bins, so the daemon could not find tmux or the agent CLIs it
    # spawns. TALKY_LOG_FILE lets the process rotate its own logs; keep launchd stderr
    # on a separate fallback file so service-manager writes never race the daemon's
    # rotation. Never secrets here; tokens live in owner-only files under ~/.talky.
    environment_variables PATH:           "#{Dir.home}/.local/bin:#{HOMEBREW_PREFIX}/bin:#{HOMEBREW_PREFIX}/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
                          TALKY_HOME:     "#{Dir.home}/.talky",
                          TALKY_LOG_FILE: "#{var}/log/talky/local-gateway.err.log"
    log_path var/"log/talky/local-gateway.out.log"
    error_log_path var/"log/talky/local-gateway.stderr.log"
  end

  def caveats
    <<~EOS
      Next: run `talky login`. It signs you in AND registers this Mac as one of
      your boxes; the daemon (brew service) starts automatically.
      State lives in ~/.talky (local-gateway.json + proxy.token).
      Troubleshooting: if the daemon is not running after login, start it with
        brew services start sriviswanath/talky/talky
    EOS
  end

  test do
    assert_match "talky #{version}", shell_output("#{bin}/talky --version")
  end
end
