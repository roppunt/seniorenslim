Live-build config for the SeniorenSlim ISO. Trigger the workflow manually or push to iso/**.

## Base distribution

The ISO targets **Debian 12 (Bookworm)**. The package selection (`config/package-lists`) and
the security-normalising hooks (`config/hooks/normal`) are tailored to Debian's repository
layout, so Bookworm keeps the live-build configuration aligned with the expected package
names and mirror structure.

