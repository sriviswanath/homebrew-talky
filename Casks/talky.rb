# Homebrew CASK for the Talky Mac app (T-BOTS-MAC-SHIP, ADR 0083).
#
# A CASK (not a formula): casks model GUI .app bundles. The `talky` CLI, the
# `talky-local-gateway` daemon and its launchd registration stay in the FORMULA next
# door (../talky.rb) because only a formula can declare a `service` block.
#
# THE APP AND THE CLI ARE TWO INDEPENDENT INSTALLS (ADR 0083), which is why this cask
# declares no `depends_on formula:` edge. The app is not a client of the local daemon:
# it signs in with a device-code flow straight to the Talky Edge over HTTPS, gets that
# address from the release-stamped bundle setting when this Mac has no daemon config,
# and treats "which box is this Mac" as a designed unknown rather than a guess. Bots,
# conversations, turns, files and the TalkyBrain viewer are all Edge calls.
#
# What you give up without the CLI is the box: nothing registers this Mac as a Talky
# box, and no row in the app is marked as this machine. The caveats below say so and
# name the separate install. Sign-in is separate too, for now (ADR 0083 defers merging
# them).
#
# {{...}} placeholders are stamped at release time by tools/packaging/mac-app-release.sh
# from the NOTARIZED, STAPLED bundle it produced, never by hand.
cask "talky" do
  version "0.1.0-2456-g691096936"
  sha256 "c39cf34ed197179a8f88712fbfb462c583c797258be808b9c53814a1a6d88c23"

  url "https://dl.talky.so/v#{version}/Talky-#{version}.zip"
  name "Talky"
  desc "Native client for your bots and your computers"
  homepage "https://talky.so/"

  # Matches MACOSX_DEPLOYMENT_TARGET in apps/mac/TalkyMac.xcodeproj.
  depends_on macos: ">= :sequoia"

  app "Talky.app"

  uninstall quit: "so.talky.mac"

  # Only the APP's own state. The daemon's owner-only directory (where `talky login`
  # writes local-gateway.json and proxy.token, and which the brew service reads)
  # belongs to the formula, so removing the app must never take the CLI's
  # configuration and box registration with it. That matters MORE now that the two
  # install independently: uninstalling the app is no longer any statement at all
  # about the CLI, and a person may well have only one of them.
  zap trash: [
    "~/Library/Application Support/so.talky.mac",
    "~/Library/Caches/so.talky.mac",
    "~/Library/HTTPStorages/so.talky.mac",
    "~/Library/Preferences/so.talky.mac.plist",
    "~/Library/Saved Application State/so.talky.mac.savedState",
    "~/Library/WebKit/so.talky.mac",
  ]

  caveats <<~EOS
    Next: open Talky and sign in.

    The `talky` command line tool is a separate install. Add it when you want this
    Mac registered as one of your boxes:

      brew install sriviswanath/talky/talky
      talky login
  EOS
end
