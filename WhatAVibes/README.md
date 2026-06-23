# WhatAVibes 🎵

A chaotic, vibey Apple Music tweak. Inspired by WhatAMess.

## What it does

| Feature | Details |
|---|---|
| 🎨 Custom fonts | SF Rounded throughout the app — softer, quirkier feel |
| 🟣 Accent color | Electric violet tint on labels, buttons, scrubber, shadows |
| 🎬 Animated now playing | Pulsing album art, floating drift, animated gradient background |
| 🃏 Card layouts | Rounded frosted-glass controls bar, card-style library cells |
| ✨ Mini player | Frosted dark card with glow shadow |

## Requirements

- iOS 15.0 – 17.x
- Rootless jailbreak (Dopamine / Palera1n) **or** rootful
- Substitute / libhooker / ElleKit

---

## Building (Windows — no Mac needed)

### Option A: GitHub Actions (easiest)

1. Fork / push this repo to your GitHub account
2. Go to **Actions** tab → run the `Build WhatAVibes` workflow
3. Download the `.deb` from the **Artifacts** section
4. Transfer the `.deb` to your device and install via Filza or `dpkg -i`

### Option B: WSL2

1. Install WSL2 (Ubuntu 22.04) from the Microsoft Store
2. Inside WSL, install Theos:
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
   ```
3. Clone this repo into WSL, then:
   ```bash
   cd WhatAVibes
   make package FINALPACKAGE=1
   ```
4. Find the `.deb` in `packages/` and transfer to device

---

## Customization

Edit the top of `Tweak.xm` to change colors:

```objc
// Electric violet — change R/G/B values to anything you want
static UIColor *accentColor() {
    return [UIColor colorWithRed:0.45 green:0.20 blue:1.00 alpha:1.0];
}
```

Some ideas:
- Hot pink: `red:1.0 green:0.2 blue:0.6`
- Neon green: `red:0.2 green:1.0 blue:0.4`
- Gold: `red:1.0 green:0.8 blue:0.1`

---

## File structure

```
WhatAVibes/
├── Makefile          # Theos build config
├── control           # Package metadata
├── Tweak.xm          # All the hooks (main file)
├── WhatAVibes.plist  # Injects only into com.apple.Music
└── .github/
    └── workflows/
        └── build.yml # GitHub Actions CI
```
