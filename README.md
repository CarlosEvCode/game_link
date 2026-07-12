# Game Link

Desktop companion for Linux users who manage game libraries across multiple launchers (Lutris, Steam, etc.). 

Game Link unifies your retro and modern gaming setup:
- **ROM Injection**: Automatically scans, identifies, and injects local ROM collections directly into Lutris.
- **Visual Metadata Management**: Downloads and applies high-quality covers, banners, and icons from SteamGridDB.
- **High-Precision Identification**: Uses offline DAT databases by default for precise name resolution, with optional ScreenScraper hash-matching integration (CRC32, MD5, SHA1) for extra metadata.
- **Steam Integration**: Exports shortcuts and artwork to Steam for seamless non-Steam game management.

---

## Table of Contents
- [Key Features](#key-features)
- [Supported Platforms](#supported-platforms)
- [Installation](#installation)
  - [Arch Linux](#arch-linux)
  - [Ubuntu / Debian](#ubuntu--debian)
  - [Fedora](#fedora)
  - [AppImage](#appimage-universal-linux)
  - [Flatpak](#flatpak-universal-linux)
  - [From Source](#from-source)
- [Configuration](#configuration)
- [How Metadata Works](#how-metadata-works)
- [Steam Export Requirements](#steam-export-requirements)
- [Lutris Integration](#lutris-integration)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Key Features

### 1. Smart ROM Injection & Platform Mapping
- **Batch Scans**: Identifies games by platform-specific extensions.
- **Standalone Runner Support**: Automatically configures emulators like **Cemu (Wii U)**, mapping unpacked Loadiine folders (using `meta/meta.xml` and `code/app.rpx`) or compressed formats (`.wua`/`.wux`).
- **BIOS & Update Filtering**:
  - Filters out arcade BIOS/devices (MAME) automatically.
  - Skips Wii U updates and DLCs by inspecting Title IDs in `code/app.xml`.
- **Duplicate Prevention**: Handles extension priority (e.g., favoring `.bin`/`.iso` over `.cue`).
- **Cleanups**: Option to clean previous entries of a platform before re-injecting.

### 2. High-Precision Identification (ScreenScraper)
- **Offline DAT Databases**: Uses Libretro databases to resolve game names offline.
- **Serial Parsing**: Parses game serials directly from **PlayStation (PS1, PS2, PSP)** ISOs/CSOs and **GameCube/Wii** ISOs/WBFs for 100% accurate matches.
- **Online Matching**: Uses CRC32, MD5, and SHA1 hashes to query ScreenScraper.
- **Syncd Quota & Caches**: Keeps persistent local caches and respects daily API request limits.

### 3. Visual Media Manager (SteamGridDB)
- **Grid Layout**: Preview and apply cover art (portrait), banners (landscape), and icons (square).
- **Lutris Integration**: Writes downloaded artwork directly into Lutris's media directories and updates Lutris databases.
- **Artwork Caching**: Minimizes API requests and speeds up loading times.

### 4. Steam Export
- **Non-Steam Shortcuts**: Creates and updates shortcuts linking to `lutris:rungameid/<id>`.
- **Artwork Sync**: Automatically maps Steam artwork slots (`cover`, `hero`, `icon`, `wide`).
- **Auto-Collections**: Groups games into Steam categories by platform.

---

## Supported Platforms

| Platform | ID | Supported Extensions | Identification Features |
| :--- | :--- | :--- | :--- |
| **Arcade (MAME)** | `mame` | `.zip`, `.7z` | Offline DAT resolution, BIOS & device filtering |
| **Sega Dreamcast** | `dreamcast` | `.chd`, `.gdi`, `.cdi` | Offline DAT & clean name matching |
| **Sony PlayStation** | `ps1` | `.bin`, `.chd`, `.pbp`, `.cue` | Serial extraction from disc files |
| **Sony PlayStation 2** | `ps2` | `.iso`, `.chd` | Serial extraction from disc files |
| **Sony PlayStation Portable** | `psp` | `.iso`, `.cso`, `.pbp` | Serial extraction from disc files |
| **Sony PlayStation Vita** | `vita` | `.vpk`, `.zip` | Clean name matching |
| **Nintendo Game Boy (Color)** | `gb` | `.gb`, `.gbc`, `.zip`, `.7z` | Offline DAT resolution |
| **Nintendo Game Boy Advance** | `gba` | `.gba`, `.zip`, `.7z` | Offline DAT resolution |
| **Nintendo DS** | `ds` | `.nds`, `.ds` | Header serial extraction |
| **Nintendo 3DS** | `3ds` | `.3ds`, `.cia`, `.cci` | Header serial extraction |
| **Nintendo GameCube** | `gamecube` | `.iso`, `.gcz`, `.rvz` | Disc header serial extraction |
| **Nintendo Wii** | `wii` | `.iso`, `.wbfs`, `.rvz` | Disc header serial extraction |
| **Nintendo Wii U** | `wii_u` | Folder (`code/`), `.wua`, `.wux`, `.wud`, `.rpx` | XML Title ID parsing, automatic DLC/Update filtering |
| **Nintendo NES** | `nes` | `.nes`, `.zip`, `.7z` | Offline DAT resolution |
| **Super Nintendo** | `snes` | `.sfc`, `.smc`, `.zip`, `.7z` | Offline DAT resolution |
| **Nintendo 64** | `n64` | `.n64`, `.z64`, `.v64`, `.zip` | Clean name matching |
| **Sega Genesis / Mega Drive**| `genesis` / `megadrive` | `.md`, `.smd`, `.gen`, `.zip`, `.7z` | Offline DAT resolution |
| **Nintendo Switch** | `switch` | `.nsp`, `.xci`, `.nca`, `.nso` | Clean name matching |
| **Xbox** | `xbox` | `.iso`, `.xiso` | Clean name matching |

---

## Installation

### Arch Linux
Install the pre-compiled binary package directly from the **AUR** using your preferred AUR helper:
```bash
paru -S game-link-bin
# or
yay -S game-link-bin
```
*Note: You can also download the pre-compiled `.tar.xz` directly from the [Releases](https://github.com/CarlosEvCode/game_link/releases) page.*

### Ubuntu / Debian
Add the official **PPA** repository and install:
```bash
sudo add-apt-repository ppa:evcode/ubuntu/game-link
sudo apt update
sudo apt install game-link
```
*Note: You can also download the standalone `.deb` package directly from the [Releases](https://github.com/CarlosEvCode/game_link/releases) page.*

### Fedora
Enable the **Copr** repository and install:
```bash
sudo dnf copr enable evcode/game-link
sudo dnf install game-link
```
*Note: You can also download the standalone `.rpm` package directly from the [Releases](https://github.com/CarlosEvCode/game_link/releases) page.*

### AppImage (Universal Linux)
You can download the standalone `.AppImage` directly from the [Releases](https://github.com/CarlosEvCode/game_link/releases) page.

To run it manually:
```bash
chmod +x game-link-*.AppImage
./game-link-*.AppImage
```

*Tip: For seamless desktop integration (automatic menu shortcuts, system updates, and isolated file management), we highly recommend using an AppImage manager like **Gear Lever**, **AppImageLauncher**, or **AppImageKitDaemon**.*

### Flatpak (Universal Linux)
You can download the `.flatpak` package directly from the [Releases](https://github.com/CarlosEvCode/game_link/releases) page.

To install it:
```bash
flatpak install --user game_link-*.flatpak
```

### From Source
1. **Clone the repository**:
   ```bash
   git clone https://github.com/CarlosEvCode/game_link.git
   cd game_link
   ```
2. **Setup environment variables**:
   Create a `.env` file in the root directory to automatically embed ScreenScraper developer credentials at compile time:
   ```env
   SS_DEV_ID=your_screenscraper_dev_id
   SS_DEV_PASSWORD=your_screenscraper_dev_password
   SS_SOFT_NAME=your_registered_soft_name
   ```
3. **Compile or Run**:
   - Run in development mode:
     ```bash
     flutter run -d linux
     ```
   - Build a production release:
     ```bash
     # The build script will automatically detect and load your .env credentials
     ./scripts/build_all.sh
     ```

---

## Configuration

Open the **Settings** dialog in Game Link to configure your API keys.

1. **SteamGridDB API Key (Required for Artwork)**:
   - Create an account at [steamgriddb.com](https://www.steamgriddb.com/).
   - Generate your API key at [steamgriddb.com/profile/preferences/api](https://www.steamgriddb.com/profile/preferences/api) and paste it into the app.

2. **ScreenScraper User Credentials (Optional for High-Precision)**:
   - Register an account at [screenscraper.fr](https://www.screenscraper.fr/).
   - Enter your username and password in Settings to unlock hash-based scraping.

---

## How Metadata Works

Game Link separates responsibilities between metadata providers:
1. **Lutris Database Mapping**: Scans ROM directories and checks offline DAT/Serials first to find the clean game title.
2. **ScreenScraper**: Supplements local games with release dates, developers, descriptions, and verified IDs via hash matching.
3. **SteamGridDB**: Used during the visual selection step to fetch, display, and apply cover grids, banners, and icons.

---

## Steam Export Requirements

To sync artwork and create shortcuts for non-Steam games, ensure the following are installed on your system:
- Python 3
- Python modules: `vdf` and `Pillow`

Install python modules:
```bash
python3 -m pip install --user vdf pillow
```
*Note: Export options are dynamically hidden if Steam or Python runtime requirements are not detected.*

---

## Lutris Integration

Game Link seamlessly integrates with Lutris by auto-detecting user directories for both Native and Flatpak installations:
- **Native Lutris**: `~/.local/share/lutris/`
- **Flatpak Lutris**: `~/.var/app/net.lutris.Lutris/data/lutris/`

To reflect your game imports and visual media choices without manual intervention, the app writes directly to the standard Lutris configuration files:
- **Game Configurations**: updates or creates the `games/*.yml` game runner settings.
- **SQLite Database (`pga.db`)**: registers injected ROMs into the central library database.
- **Visual Assets**: places covers, banners, and icons in their respective subdirectories (`coverart/`, `banners/`, and `icons/`).

---

## Project Structure

- `lib/ui/` - Desktop GUI screens, detail panels, and settings.
- `lib/core/injector/` - Scanners, serial extraction algorithms, and database injection.
- `lib/core/lutris/` - PGA database repository and Flatpak/Native path detection.
- `lib/core/metadata/` - SteamGridDB and ScreenScraper clients, query limits, and cache.
- `lib/platforms/` - Supported systems registry and extension parameters.

---

## Troubleshooting

### SteamGridDB search returns no matches
- Double-check that your API key is correct in Settings.
- Verify your internet connection.

### High-precision mode is grayed out
- Verify that your ScreenScraper username and password are saved in Settings.
- Ensure the app was compiled with developer credentials (defined in `.env` or passed via `--dart-define`).

### Artwork does not show up in Lutris
- Verify whether Lutris is installed as a Flatpak or Native package, and check that the path in Settings matches.

---

## Contributing

Contributions are welcome! If you want to add support for a new platform, improve parsing/scanners, or enhance the UI:
1. Open an issue describing your proposal.
2. Submit a pull request targetting the `features` branch.
