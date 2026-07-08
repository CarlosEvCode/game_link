# Changelog

## [2.17.0](https://github.com/CarlosEvCode/game_link/compare/v2.16.0...v2.17.0) (2026-07-08)


### Features

* **mame:** automatically filter out BIOS and device files during folder scan ([5b5e138](https://github.com/CarlosEvCode/game_link/commit/5b5e1389795a1dcb233fb432513e10af013eb27f))
* **platforms:** add N64, SNES, and Game Boy (Color) platforms and restrict GBA to libretro only ([5abb79a](https://github.com/CarlosEvCode/game_link/commit/5abb79ab5acc45eb5c457ca91cefd33921e4c44b))
* **platforms:** add RetroArch (libretro) cores for PS1, PS2, GameCube, Wii, Arcade, 3DS, and GBA ([603bdaf](https://github.com/CarlosEvCode/game_link/commit/603bdaffa805a7c0bdbaaee431c450fef4545801))
* **platforms:** expand libretro cores selection with more popular emulator cores ([7813e84](https://github.com/CarlosEvCode/game_link/commit/7813e8403056b9c23730adc9c94acab0f5998549))
* **wiiu:** add Cemu support with automatic game directory detection and DLC/Update filtering ([00f8c33](https://github.com/CarlosEvCode/game_link/commit/00f8c3382bd700840d926877279dd6a850dafac6))
* **wiiu:** resolve real game names from meta.xml/folder, fix gameSlug, and set cleanOldGames default to false ([6411148](https://github.com/CarlosEvCode/game_link/commit/6411148afe6a16b1414a757e805b6f1da9df67c1))


### Bug Fixes

* **platforms:** align platformNames with official Lutris database values ([5d3ae48](https://github.com/CarlosEvCode/game_link/commit/5d3ae48d2c86925264244575f2f110fea5c34d3d))

## [2.16.0](https://github.com/CarlosEvCode/game_link/compare/v2.15.0...v2.16.0) (2026-07-08)


### Features

* **gc/wii:** support game serial extraction for GameCube and Wii and skip hash calculations during scan ([bb53072](https://github.com/CarlosEvCode/game_link/commit/bb53072b72b9a875a0aa57145a5dfeda3c8b35da))
* **injector:** add offline ClrMamePro DAT name resolution for classic platforms ([37a036e](https://github.com/CarlosEvCode/game_link/commit/37a036e63eac93de67e373153a8262c906ab8416))
* **mame:** add local MAME name resolution fallback & progressive scan ([d3b2ca5](https://github.com/CarlosEvCode/game_link/commit/d3b2ca5938abe6a65e2f70d5fc4bc995e6153492))
* **mame:** prioritize offline MAME.dat resolution over emulator binary command ([f1eaea8](https://github.com/CarlosEvCode/game_link/commit/f1eaea87d711deeea5897bbcd55ece65a8c9e873))
* **platforms:** add Nintendo NES platform with libretro cores ([4282451](https://github.com/CarlosEvCode/game_link/commit/428245164560ceacc22ceeecf47a10cda2b7de4e))
* **platforms:** support .nes, .zip, and .7z formats for NES instead of .fds and .unf ([47dcf3a](https://github.com/CarlosEvCode/game_link/commit/47dcf3a0c6981684820646392561a1a344fcfb38))
* **psp:** support game identification from compressed CSO and raw ISO formats using ISO9660 PVD parsing ([802a203](https://github.com/CarlosEvCode/game_link/commit/802a203e2a129dfaf09bce26bfb3356e395d2677))
* **ui:** add option to toggle offline game name auto-detection and inject using raw filenames ([593d784](https://github.com/CarlosEvCode/game_link/commit/593d784d493b7dd008f94cd9753c242ac5d10699))
* **ui:** cache resolved ROM names to local SQLite database during folder scan ([8e56f8d](https://github.com/CarlosEvCode/game_link/commit/8e56f8daf9edd9b71850456a616168e55955520f))
* **ui:** show already injected badge in rom list and add a folder refresh button ([14d7f88](https://github.com/CarlosEvCode/game_link/commit/14d7f88970edfa84b00d3f2e96d7c2c9a5fc656f))
* **ui:** simplify already injected indicator to a subtle gray check circle icon ([1574988](https://github.com/CarlosEvCode/game_link/commit/15749882129e477783f32c3977b9408c887781a3))


### Bug Fixes

* **build:** import dart:typed_data to resolve ByteData and Uint8List undefined names ([a564429](https://github.com/CarlosEvCode/game_link/commit/a5644291e8cf8ed66d5cdb8fa9ed5317d789ac93))
* **injector:** slugify game slugs to avoid special characters/apostrophe issues in Lutris ([1ea3574](https://github.com/CarlosEvCode/game_link/commit/1ea35744ca51dee0af755f492dea8cc820dbba83))
* **metadata:** automatically check disk for existing media and set database flags correctly ([d5c8f21](https://github.com/CarlosEvCode/game_link/commit/d5c8f2152421a3cc4d7efc6130594dece42f36ff))
* **ui:** define isNoHashPlatform correctly and skip hashes for compressed/disc formats ([1338134](https://github.com/CarlosEvCode/game_link/commit/1338134907624bbd57188d7ba2fbddace32c1826))
* **visual-manager:** separate games by platform to avoid mixing games sharing the same runner ([da691c7](https://github.com/CarlosEvCode/game_link/commit/da691c7f4c037d83d679cfbb32d8ac7764e56543))


### Performance Improvements

* **psp:** optimize CSO index parser to read block offsets on-demand without memory allocation ([0f67a48](https://github.com/CarlosEvCode/game_link/commit/0f67a486ca4565fb20cdf76c9b1875ad5234261f))


### Reverts

* **ui:** remove already injected check indicator and database check ([eaa6438](https://github.com/CarlosEvCode/game_link/commit/eaa6438d4a1318ff05fcc010bcd1ee842eb841e8))

## [2.15.0](https://github.com/CarlosEvCode/game_link/compare/v2.14.0...v2.15.0) (2026-05-11)


### Features

* add RPM packaging support with Fedora Copr integration ([fa7020f](https://github.com/CarlosEvCode/game_link/commit/fa7020f74909f11a6050a721bbb6fcf3bbbf69fa))

## [2.14.0](https://github.com/CarlosEvCode/game_link/compare/v2.13.5...v2.14.0) (2026-05-11)


### Features

* add RPM packaging support with Fedora Copr integration ([ae118ac](https://github.com/CarlosEvCode/game_link/commit/ae118ac948741ccdcd60928561e93b911c0e305f))

## [2.13.5](https://github.com/CarlosEvCode/game_link/compare/v2.13.4...v2.13.5) (2026-05-11)


### Bug Fixes

* **appimage:** unify binary name to game_link and repair AppImage build ([4c6fd57](https://github.com/CarlosEvCode/game_link/commit/4c6fd574b6681bbc76519998c34a03e204c453ca))

## [2.13.4](https://github.com/CarlosEvCode/game_link/compare/v2.13.3...v2.13.4) (2026-05-11)


### Bug Fixes

* **debian:** fix binary permissions and .desktop Exec path ([7ea5342](https://github.com/CarlosEvCode/game_link/commit/7ea5342c27ca22c96054145c489b078026749864))

## [2.13.3](https://github.com/CarlosEvCode/game_link/compare/v2.13.2...v2.13.3) (2026-05-10)


### Bug Fixes

* **release:** fix dch existing file error and sync version 2.13.2 ([539f5b1](https://github.com/CarlosEvCode/game_link/commit/539f5b17abf26b7e1b4839b56cdc1e6bbddbf918))

## [2.13.2](https://github.com/CarlosEvCode/game_link/compare/v2.13.1...v2.13.2) (2026-05-10)


### Bug Fixes

* **release:** make debian build non-interactive and add build-essential ([d6966fd](https://github.com/CarlosEvCode/game_link/commit/d6966fde3554ee798be673fda17b822852e7dec2))

## [2.13.1](https://github.com/CarlosEvCode/game_link/compare/v2.13.0...v2.13.1) (2026-05-10)


### Bug Fixes

* **release:** fix debian build dependencies and sync version 2.13.0 ([ea7a79c](https://github.com/CarlosEvCode/game_link/commit/ea7a79ceb93b810a058de3240b2b15ccb5521a16))

## [2.13.0](https://github.com/CarlosEvCode/game_link/compare/v2.12.1...v2.13.0) (2026-05-10)


### Features

* add native Debian packaging and PPA support ([9878b51](https://github.com/CarlosEvCode/game_link/commit/9878b517a2cfc0c5b3e9686cc89bfeb9f4e8b1e6))

## [2.12.1](https://github.com/CarlosEvCode/game_link/compare/v2.12.0...v2.12.1) (2026-05-10)


### Bug Fixes

* standardize application ID and WM_CLASS for taskbar icon ([358f6aa](https://github.com/CarlosEvCode/game_link/commit/358f6aa6267583ceba37f426ba35b30c151157db))

## [2.12.0](https://github.com/CarlosEvCode/game_link/compare/v2.11.0...v2.12.0) (2026-05-10)


### Features

* automated asset checksum generation for releases ([e738205](https://github.com/CarlosEvCode/game_link/commit/e73820597b7c3cd637564072cd96202209537b23))

## [2.11.0](https://github.com/CarlosEvCode/game_link/compare/v2.10.0...v2.11.0) (2026-05-10)


### Features

* implement guided onboarding experience with interactive setup ([840b01c](https://github.com/CarlosEvCode/game_link/commit/840b01cfee0f1f7b4a2f5a94b303a9b11a4c930f))

## [2.10.0](https://github.com/CarlosEvCode/game_link/compare/v2.9.10...v2.10.0) (2026-05-10)


### Features

* enhance UX with options menu, About dialog, and tabbed configuration ([a23ca1c](https://github.com/CarlosEvCode/game_link/commit/a23ca1c58b8ff53b28f8a6f95e8d7c776910cf9b))

## [2.9.10](https://github.com/CarlosEvCode/game_link/compare/v2.9.9...v2.9.10) (2026-05-10)


### Bug Fixes

* **flatpak:** correct Exec command and add StartupWMClass for better desktop integration ([f4bfac8](https://github.com/CarlosEvCode/game_link/commit/f4bfac8d18c123df547576ba6e2a9a050c1942c1))

## [2.9.9](https://github.com/CarlosEvCode/game_link/compare/v2.9.8...v2.9.9) (2026-05-10)


### Bug Fixes

* resize application icon to 512x512 for Flatpak compliance ([ff358e4](https://github.com/CarlosEvCode/game_link/commit/ff358e4d3321416bb60efbae5631f3cfe4207aca))

## [2.9.8](https://github.com/CarlosEvCode/game_link/compare/v2.9.7...v2.9.8) (2026-05-10)


### Bug Fixes

* **ci:** upgrade packaging job to ubuntu-24.04 for better flatpak compatibility ([e9895bb](https://github.com/CarlosEvCode/game_link/commit/e9895bb1667e9b94b561882d944254e0607d752f))

## [2.9.7](https://github.com/CarlosEvCode/game_link/compare/v2.9.6...v2.9.7) (2026-05-10)


### Bug Fixes

* **ci:** bypass missing appstream-compose tool with --no-compose flag ([7725111](https://github.com/CarlosEvCode/game_link/commit/7725111a192e552353eb00d9edc0e1b150af31f1))

## [2.9.6](https://github.com/CarlosEvCode/game_link/compare/v2.9.5...v2.9.6) (2026-05-10)


### Bug Fixes

* **ci:** add libappstream-compose-dev and debug tools for flatpak build ([4da8f0e](https://github.com/CarlosEvCode/game_link/commit/4da8f0eec9063cb1ae9e37d910de39932c6cb288))

## [2.9.5](https://github.com/CarlosEvCode/game_link/compare/v2.9.4...v2.9.5) (2026-05-10)


### Bug Fixes

* **ci:** install appstream package for flatpak metadata validation ([c140c5f](https://github.com/CarlosEvCode/game_link/commit/c140c5fa275b3abea288ef6564ad959cb6b26863))

## [2.9.4](https://github.com/CarlosEvCode/game_link/compare/v2.9.3...v2.9.4) (2026-05-10)


### Bug Fixes

* **ci:** use --user flag in flatpak-builder to match remote scope ([31e5bc5](https://github.com/CarlosEvCode/game_link/commit/31e5bc546d058c896231e6d8442e16da7f2adcd0))

## [2.9.3](https://github.com/CarlosEvCode/game_link/compare/v2.9.2...v2.9.3) (2026-05-10)


### Bug Fixes

* **ci:** use --user flag for flatpak remote-add to avoid permission errors ([30a8d05](https://github.com/CarlosEvCode/game_link/commit/30a8d05010f5784f45e8ebc77265265d9d67f8e1))

## [2.9.2](https://github.com/CarlosEvCode/game_link/compare/v2.9.1...v2.9.2) (2026-05-10)


### Bug Fixes

* **ci:** remove non-existent perl package from dependencies ([60a8b31](https://github.com/CarlosEvCode/game_link/commit/60a8b31c431a50e3e340af0c62188bd3347da723))

## [2.9.1](https://github.com/CarlosEvCode/game_link/compare/v2.9.0...v2.9.1) (2026-05-10)


### Bug Fixes

* **ci:** correct package name typo in release workflow ([79ec0e5](https://github.com/CarlosEvCode/game_link/commit/79ec0e511949985ab71bf30f8028e93ebddf5dcb))

## [2.9.0](https://github.com/CarlosEvCode/game_link/compare/v2.8.1...v2.9.0) (2026-05-10)


### Features

* add automated Flatpak bundle generation to release workflow ([9d47a27](https://github.com/CarlosEvCode/game_link/commit/9d47a27b6a92bf3273a2719a19601e9db7c9b629))
* implement standardized Flatpak packaging and manifest ([27b68f9](https://github.com/CarlosEvCode/game_link/commit/27b68f907c3ca855b38c9008c2244c6728636787))

## [2.8.1](https://github.com/CarlosEvCode/game_link/compare/v2.8.0...v2.8.1) (2026-05-10)


### Bug Fixes

* standardize tarball directory structure for AUR compatibility ([566a2c4](https://github.com/CarlosEvCode/game_link/commit/566a2c431f7d423d3c1bf56f51f7d6ec6b909ac3))

## [2.8.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.7.2...v2.8.0) (2026-04-20)


### Features

* add Windows platform support for Visual Manager and implement selective injector visibility ([5c83690](https://github.com/CarlosEvCode/lutris_game_station/commit/5c8369081ac462dd322c5cec8a74a16ad0045a52))

## [2.7.2](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.7.1...v2.7.2) (2026-04-13)


### Bug Fixes

* force .zsync generation using explicit -u flag in appimagetool ([a16b272](https://github.com/CarlosEvCode/lutris_game_station/commit/a16b2722c6f6d07fbe09e2b090f56d4efd393aa8))

## [2.7.1](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.7.0...v2.7.1) (2026-04-13)


### Bug Fixes

* ensure .zsync generation and improve release asset pattern matching ([7fec381](https://github.com/CarlosEvCode/lutris_game_station/commit/7fec38110257ebd13ecd5188bfff4f585618f7ae))

## [2.7.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.6.0...v2.7.0) (2026-04-13)


### Features

* implement ZSync update information and cleanup release assets ([f2ce9a9](https://github.com/CarlosEvCode/lutris_game_station/commit/f2ce9a948f310075b1bb4e261e2a25ccc8812bdc))

## [2.6.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.5.1...v2.6.0) (2026-04-13)


### Features

* add GBA, PS Vita and enhance DS/Xbox with standalone runner support based on Lutris JSON definitions ([a04809c](https://github.com/CarlosEvCode/lutris_game_station/commit/a04809c5c41ce89658d29eca640564c161f794ab))
* add PSP and Dreamcast platforms with multi-emulator support ([2fc7a43](https://github.com/CarlosEvCode/lutris_game_station/commit/2fc7a4378856bf0d5a9a442000b9dd109fa283c8))
* implement multi-emulator architecture per platform and enhance visual manager compatibility ([c33974f](https://github.com/CarlosEvCode/lutris_game_station/commit/c33974fd6838ca9d4e483db413702072e7be11ce))

## [2.5.1](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.5.0...v2.5.1) (2026-04-13)


### Bug Fixes

* use static runtime in AppImage to remove libfuse2 dependency ([645f6b5](https://github.com/CarlosEvCode/lutris_game_station/commit/645f6b595dccd66b1ac3f9e894695456d3f8121e))

## [2.5.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.4.2...v2.5.0) (2026-04-12)


### Features

* show Steam export requirements dialog instead of hiding actions ([eeb4b84](https://github.com/CarlosEvCode/lutris_game_station/commit/eeb4b84e053351827e89ab70e3165d0bcb5a050c))

## [2.4.2](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.4.1...v2.4.2) (2026-04-12)


### Bug Fixes

* ensure libselinux portability in AppImage by removing manual deletion ([af22f2b](https://github.com/CarlosEvCode/lutris_game_station/commit/af22f2b15fbb27bf1cd5c9b39531c2294942521f))
* make Steam platform sync safe and deterministic ([63bb716](https://github.com/CarlosEvCode/lutris_game_station/commit/63bb716cadec386ea0452ab455e56407b4ee316c))

## [2.4.1](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.4.0...v2.4.1) (2026-03-21)


### Bug Fixes

* ensure libselinux portability in AppImage by removing manual deletion
* make Steam platform sync safe and deterministic ([8bd7c28](https://github.com/CarlosEvCode/lutris_game_station/commit/8bd7c28813a45464f6b7b4fbf86dc1c31d70ec5b))

## [2.4.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.3.0...v2.4.0) (2026-03-21)


### Features

* add Steam batch export actions with availability gating ([39aa5a1](https://github.com/CarlosEvCode/lutris_game_station/commit/39aa5a13f543ce79852058b0ba59ac9ade17662c))
* add Steam shortcut export with Lutris URI and artwork sync ([b5a0197](https://github.com/CarlosEvCode/lutris_game_station/commit/b5a01976eaab59bca8ecf2a1d5aa47ea75d96553))
* auto-create Steam simple collections by platform ([d616e7e](https://github.com/CarlosEvCode/lutris_game_station/commit/d616e7e0df102b5d378626536cb71415546aadc3))
* gate Steam export by runtime dependencies and document setup ([4c9f739](https://github.com/CarlosEvCode/lutris_game_station/commit/4c9f739621251ea8d787afadb4b9ca6837ba5df6))

## [2.3.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.2.0...v2.3.0) (2026-03-20)


### Features

* enhance visual manager UX with detailed game information screen ([7075254](https://github.com/CarlosEvCode/lutris_game_station/commit/7075254f737fe609845d996a4585dbbcefb2d508))
* improve detail correction flow and ROM source visibility ([e8afb5e](https://github.com/CarlosEvCode/lutris_game_station/commit/e8afb5ee652d7b1a56a696367b7248eb3e7461ae))
* optimize ScreenScraper API usage with intelligent caching ([aaa2274](https://github.com/CarlosEvCode/lutris_game_station/commit/aaa22742ef330dc649e494d3ad5b1b06173947d0))
* polish detail UX and sync visual manager platform context ([95ec5d7](https://github.com/CarlosEvCode/lutris_game_station/commit/95ec5d761d79d63a78c526b25ef4af51f80ef213))
* streamline detail actions with per-media edit shortcuts ([ba4cafd](https://github.com/CarlosEvCode/lutris_game_station/commit/ba4cafde853594fda5bba18d4f881aa2e531e2e6))


### Bug Fixes

* refresh media previews after apply and keep detail open ([ad72739](https://github.com/CarlosEvCode/lutris_game_station/commit/ad72739b2ab89e85d4b4bc4e10411976f71d4165))

## [2.2.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.1.1...v2.2.0) (2026-03-18)


### Features

* redesign visual manager for desktop workflow ([5335de9](https://github.com/CarlosEvCode/lutris_game_station/commit/5335de95c8f0eda66bccad99cddfcc7208a901bb))

## [2.1.1](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.1.0...v2.1.1) (2026-03-18)


### Bug Fixes

* embed developer credentials at compile time via --dart-define ([b145bee](https://github.com/CarlosEvCode/lutris_game_station/commit/b145bee69c60df79ba1c95796c6992b9043e6ba5))

## [2.1.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v2.0.0...v2.1.0) (2026-03-18)


### Features

* trigger build with .env secrets configuration ([ed3e37e](https://github.com/CarlosEvCode/lutris_game_station/commit/ed3e37e24c20e31cbe94377f4128af3f5a4311e9))

## [2.0.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.6.0...v2.0.0) (2026-03-17)


### ⚠ BREAKING CHANGES

* UI layout restructured from vertical scroll to 2-column desktop layout

### Features

* complete ScreenScraper API integration and desktop UI redesign ([4d2dbe7](https://github.com/CarlosEvCode/lutris_game_station/commit/4d2dbe7c77cb15c29cff861cd2a329e00d7c62df))

## [1.6.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.5.2...v1.6.0) (2026-03-17)


### Features

* añadir alternancia entre vista de cuadrícula y lista en el gestor visual ([f23bb05](https://github.com/CarlosEvCode/lutris_game_station/commit/f23bb052951cc88f473202e97d73de80d577b784))
* añadir selector interactivo entre Lutris Nativo y Flatpak ([35cd94a](https://github.com/CarlosEvCode/lutris_game_station/commit/35cd94a0fd59c8aff96080dd15a85261a7bc5da4))
* implementar filtrado de metadatos faltantes y sincronización con el disco ([62226b7](https://github.com/CarlosEvCode/lutris_game_station/commit/62226b77ac92b9f9636262e1dace54253ff6542e))
* implementar previsualización y selección manual de ROMs antes de la inyección ([4535a57](https://github.com/CarlosEvCode/lutris_game_station/commit/4535a578be0c6782a0a20c08ce505df49fe0c91a))
* implementar scroll infinito en el gestor visual para mejorar rendimiento ([f05ba94](https://github.com/CarlosEvCode/lutris_game_station/commit/f05ba9491fd712e13c465c3e8f9a3154de94975b))
* mejoras avanzadas en el inyector (edición de nombres, escaneo recursivo y perfiles de ruta) ([85053ed](https://github.com/CarlosEvCode/lutris_game_station/commit/85053ed635be1d91a0df9428fcf1521beb94f82f))


### Bug Fixes

* refrescar gestor visual automáticamente al cambiar modo de Lutris ([eb2cc14](https://github.com/CarlosEvCode/lutris_game_station/commit/eb2cc14475efa2d0b55744b7aa2bf74a2b0876ab))

## [1.5.2](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.5.1...v1.5.2) (2026-03-17)


### Bug Fixes

* asegurar permisos de ejecución del binario en el AppImage ([60c39c0](https://github.com/CarlosEvCode/lutris_game_station/commit/60c39c056ab03138e09d98119cca76f6f08ce380))

## [1.5.1](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.5.0...v1.5.1) (2026-03-17)


### Bug Fixes

* forzar DEPLOY_GTK_VERSION=3 para GitHub Actions ([a8f4668](https://github.com/CarlosEvCode/lutris_game_station/commit/a8f466882cafc9c56782266ebec79133f9e2fe29))

## [1.5.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.4.6...v1.5.0) (2026-03-17)


### Features

* implementar detección de ROMs por hash e integración con ScreenScraper ([fba1d0a](https://github.com/CarlosEvCode/lutris_game_station/commit/fba1d0a394d9e0fddd23ef2a992a3aef731cb38e))
* profesionalizar flujo de empaquetado Linux (AppImage, Tarball, Flatpak) ([00f3407](https://github.com/CarlosEvCode/lutris_game_station/commit/00f34077894aea1ec319f1fa89b759cb3c940f4c))

## [1.4.6](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.4.5...v1.4.6) (2026-03-15)


### Bug Fixes

* pulir integración con el host (cursor del mouse y limpieza de librerías base) y profesionalizar ID de aplicación ([a4f9de3](https://github.com/CarlosEvCode/lutris_game_station/commit/a4f9de3c05800cf8ad317e7da36056f47377f7f3))

## [1.4.5](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.4.4...v1.4.5) (2026-03-15)


### Bug Fixes

* añadir dpkg-dev a dependencias para compatibilidad con plugin GTK en contenedor ([e5e15e7](https://github.com/CarlosEvCode/lutris_game_station/commit/e5e15e746c9cadc68b89638c412fe8b4b87b362f))

## [1.4.4](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.4.3...v1.4.4) (2026-03-15)


### Bug Fixes

* corregir descarga y ejecución del plugin GTK para linuxdeploy ([993e973](https://github.com/CarlosEvCode/lutris_game_station/commit/993e9732f90d4eda8387d7738855570fe96dcc4d))

## [1.4.3](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.4.2...v1.4.3) (2026-03-15)


### Bug Fixes

* integrar plugin GTK y configurar variables de entorno para cargadores de imágenes y temas en AppImage ([ba4cd59](https://github.com/CarlosEvCode/lutris_game_station/commit/ba4cd59f8f61de36dc9dc267803e139651e031d4))

## [1.4.2](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.4.1...v1.4.2) (2026-03-15)


### Bug Fixes

* implementar estrategia maestro v6 con empaquetado manual mediante appimagetool y runtime local ([6c479a3](https://github.com/CarlosEvCode/lutris_game_station/commit/6c479a30a22842658d54f3feeb34c9ce3332ea55))

## [1.4.1](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.4.0...v1.4.1) (2026-03-15)


### Bug Fixes

* implementar estrategia maestra v5 con runtime local y LD_LIBRARY_PATH para linuxdeploy ([800db3b](https://github.com/CarlosEvCode/lutris_game_station/commit/800db3b820d88fe86ccdc29fa2d10ef89681f2ab))

## [1.4.0](https://github.com/CarlosEvCode/lutris_game_station/compare/v1.3.11...v1.4.0) (2026-03-15)


### Features

* mostrar ruta de configuración al guardar API Key para mayor transparencia ([c443527](https://github.com/CarlosEvCode/lutris_game_station/commit/c44352728d4ca006c830415e2ff20d919f51134f))
* persistencia de API Key en ~/.config/lutris_game_station/config.json ([c7163d4](https://github.com/CarlosEvCode/lutris_game_station/commit/c7163d479627ebd7ec4ae4e34f451e6dbab27ab9))
* Unificación y migración completa a Lutris Game Station ([4fd2f1a](https://github.com/CarlosEvCode/lutris_game_station/commit/4fd2f1a2371f6aa257aab8779227f1265b9082a9))


### Bug Fixes

* añadir jq al contenedor para compatibilidad con flutter-action ([89745c3](https://github.com/CarlosEvCode/lutris_game_station/commit/89745c3d1276073622bed6accaf2c89755e787da))
* añadir lld a dependencias para resolver error de linker en ubuntu 20.04 ([a0e3c2b](https://github.com/CarlosEvCode/lutris_game_station/commit/a0e3c2b2cf542bd4c96521acdbacd704eab07750))
* compilar AppImage dentro de contenedor Ubuntu 20.04 para máxima compatibilidad ([7fe3950](https://github.com/CarlosEvCode/lutris_game_station/commit/7fe39501096161a35e7ca074eefb0192943b1205))
* configurar git para confiar en todos los directorios dentro del contenedor ([0d2dcaf](https://github.com/CarlosEvCode/lutris_game_station/commit/0d2dcafa1077a8e86f3c8503a6a9b9674a5b5219))
* corregir descarga del plugin de Flutter para linuxdeploy usando curl y rama main ([c992d41](https://github.com/CarlosEvCode/lutris_game_station/commit/c992d419a9f53a12e782baf29e373cd98ec60826))
* corregir indentación YAML en el workflow de release ([8118f12](https://github.com/CarlosEvCode/lutris_game_station/commit/8118f12467614bbfee2b4c4b074f451a03a622cc))
* corregir título de la ventana principal de la aplicación ([0fa45a1](https://github.com/CarlosEvCode/lutris_game_station/commit/0fa45a1e26da44af6ef3db6b7beb50f2aafa6b8b))
* corregir URL de descarga del plugin y nombre de ejecutable para linuxdeploy ([611df07](https://github.com/CarlosEvCode/lutris_game_station/commit/611df07e9762e4e95042b3cc4361919a094f546d))
* empaquetado AppImage manual para evitar errores de red con el plugin de Flutter ([0581178](https://github.com/CarlosEvCode/lutris_game_station/commit/05811786eab74754c25afedf6aaffe804a0c5c87))
* establecer DEBIAN_FRONTEND=noninteractive para evitar bloqueos en el contenedor ([18ced8b](https://github.com/CarlosEvCode/lutris_game_station/commit/18ced8b7f0a126e1f6e117de5b93458af9ea6dd6))
* evitar duplicados de juegos por múltiples formatos o re-inyecciones ([a24919d](https://github.com/CarlosEvCode/lutris_game_station/commit/a24919d768c2d8c11460c41eff7901752ba2ad1e))
* implementar estrategia maestra v3 con patchelf y organización de librerías estándar para AppImage ([adb13d1](https://github.com/CarlosEvCode/lutris_game_station/commit/adb13d14abb53e6bc3d537eba8cf5e886014d16e))
* implementar estrategia maestra v4 respetando el bundle nativo de Flutter para evitar errores de AOT ELF path ([e736c0e](https://github.com/CarlosEvCode/lutris_game_station/commit/e736c0eb1869c4c78e0d786337ff43c2c9505343))
* implementar estrategia robusta v2 para AppImage con AppRun y LD_LIBRARY_PATH ([6782c06](https://github.com/CarlosEvCode/lutris_game_station/commit/6782c064e7c7d6ccf672c7a6cd49555ba0a76171))
* incrustar libsqlite3.so directamente en el bundle de la app para asegurar carga dinámica ([55edfca](https://github.com/CarlosEvCode/lutris_game_station/commit/55edfcab6585c3e68ac40f1af62701b21729833b))
* mantener bundle de Flutter íntegro y corregir enlace simbólico de sqlite3 en AppImage ([5a16923](https://github.com/CarlosEvCode/lutris_game_station/commit/5a16923cb917267d1cfa7adcc77268fd7f2c8839))
* redimensionar icono a 512x512 para cumplir validación de linuxdeploy ([e657974](https://github.com/CarlosEvCode/lutris_game_station/commit/e657974629ab6aacfdc872a115d01726e7ac8324))
* resolver carga de sqlite3 y mejorar estructura del AppImage para temas GTK ([c1a7fcb](https://github.com/CarlosEvCode/lutris_game_station/commit/c1a7fcba6a2e9751383cadf5331363829aa44394))
* revertir cambios en main.dart y aplicar solución de sqlite3 vía symlink en AppImage ([5ea92a5](https://github.com/CarlosEvCode/lutris_game_station/commit/5ea92a57cdfc69475c19626b2331a2be1ff9e50d))
