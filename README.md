# Forza Horizon 2 and 3 on the Steam Deck

My setup for the PC versions of Forza Horizon 2 and Forza Horizon 3 on a Steam Deck OLED with Proton. Handheld, FH2
shows **90 fps** at 1280x800 with car and scenery detail on High (45 real fps doubled with Lossless Scaling frame
generation). It also covers the mods I run, the Proton fixes I had to write for some of them, my frame generation
values and my ReShade presets.

This repo used to be `fh2-steam-deck`. GitHub redirects the old URL and old clones keep working; to update a clone's
remote, run `git remote set-url origin https://github.com/consultoria-deta/fh-steam-deck.git`.

The game files and the PC runtime that runs them aren't redistributable, so this repo has no binaries from either.
It links to every mod and holds only my presets, configs, settings and the forks with the fixes.

> **Disclaimer.** Everything here is unofficial and unsupported. Mods change how the game runs; you install and run
> them at your own risk and responsibility. **Don't report mod problems to the game's or the runtime's authors**:
> they don't support mods. Report them to the mod's own repo, or open an issue here if it's about this guide.

## The short version

If you are stuck at 40-50 fps, do steps 1 and 2 before anything else.

1. **Use runtime version 1.0.1** and a fresh save made on the Deck.
2. **Turn off xalia.** Add `PROTON_USE_XALIA=0` to the launch options (see below). This was my biggest single gain
   in Game Mode, with or without frame generation.
3. Optional: frame generation with lsfg-vk: FH2 handheld 45 -> 90 fps, everything else 30 -> 60 fps.
4. Steam's per-game Performance settings: refresh rate 90 Hz handheld, frame limit Off.

## 1. Runtime 1.0.1 and a fresh save

Measured in desktop mode with MangoHud, same route, same car:

| Setup | Runtime 0.9.10 | Runtime 1.0.1 |
|---|---|---|
| FH2 handheld, 1280x800 | 47.8 fps avg | 59-60 fps avg |

* **Saves copied over from a PC** have been reported to run much worse. Start a new one on the Deck.
* **The first launch after any change compiles shaders.** For a minute or two you can see very low fps. Let it
  finish and quit from the game's menu, so the runtime writes its pipeline cache. The next launches are fast.
* **Docked:** set the game resolution in Steam to 1920x1080 (the game > Properties > Game resolution). Otherwise
  the game and ReShade render at your TV's 4K.

## 2. Turn off xalia (the big one)

Proton starts `xalia.exe`, an accessibility helper that lets a controller drive Windows dialogs. Here it used about
25% of a CPU core plus extra `wineserver` load. The Deck shares its 15 W between CPU and GPU, so that CPU time came
out of the GPU's budget: in Game Mode the GPU sat at 650-1100 MHz instead of up to 1600 MHz.

What I measured on the same session, same settings, only xalia changed (FH2 handheld):

| | GPU clock | Real fps | On screen (frame gen x2) |
|---|---|---|---|
| xalia on (Proton default) | 650-1100 MHz | ~22 | ~45 |
| `PROTON_USE_XALIA=0` | 1100-1400 MHz | 45 | **90** |

Desktop mode wasn't affected as much, which is why my earlier desktop benchmarks looked fine while Game Mode didn't.

The only thing you lose: in the runtime's launcher window you navigate with the touchscreen or the trackpads instead
of the D-pad. The game itself is unaffected.

You can check if it's running with `pgrep -a xalia` in a desktop terminal (or over SSH) while the game is open.

## 3. Game settings

FH2, launcher settings, handheld:

| Setting | Value |
|---|---|
| Resolution | 1280x800 (`800`) |
| Antialiasing | MSAA 2x |
| Car detail | High |
| Scenery detail | High |
| Shadow detail | Default |
| Particles | Low |
| Motion blur | Off |
| Texture filtering | 16x |
| Frame rate | 60 |
| VSync | On |
| HDR | **Off** with frame generation, On without it |

With these the GPU runs at 99-100%, so there is no headroom left. **Don't use MSAA 4x handheld**: real fps drops
to 27-34 in heavy areas. If you need a bit more room, scenery detail is the first thing to lower.

Docked (TV, 1080p): MSAA 2x, Default graphics, 30 real fps doubled to 60.

Extra Options: enhanced liveries, livery MSAA 2x.

## 4. Frame generation (optional): lsfg-vk

[lsfg-vk](https://github.com/PancakeTAS/lsfg-vk) runs Lossless Scaling's frame generation as a Vulkan layer on
Linux. No Decky plugin needed. You need to own
[Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/) on Steam, since lsfg-vk uses its DLL.

### My values

| Launcher | Real fps (`VKD3D_FRAME_RATE`) | On screen | lsfg-vk profile |
|---|---|---|---|
| FH2 handheld | 45 | 90 | `Forza Handheld`: x2, `flow_scale` 0.75, performance mode |
| FH2 TV | 30 | 60 | `Forza TV`: x2, `flow_scale` 1.0, quality mode |
| FH3 handheld | 30 | 60 | `Forza Handheld` |
| FH3 TV | 30 | 60 | `Forza TV` |

All four run in **SDR** (HDR off in the launcher) with the SDR ReShade preset, and all four with
`PROTON_USE_XALIA=0`.

### Setup

1. In Steam: Lossless Scaling > Properties > Betas > select the **`lsfg-vk`** branch, and let it install. That
   branch ships `lsfg-vk.dll` in `steamapps/common/Lossless Scaling/`.
2. Download `lsfg-vk-2.0.0.tar.xz` from the [lsfg-vk releases](https://github.com/PancakeTAS/lsfg-vk/releases) and
   extract it into `~/.local`, so you end up with `~/.local/lib/liblsfg-vk-layer.so` and
   `~/.local/share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json`. No sudo needed and it
   survives SteamOS updates.
3. Copy [`lsfg-vk/conf.toml`](lsfg-vk/conf.toml) to `~/.config/lsfg-vk/conf.toml`. Fix the DLL path if your Steam
   library is on the SD card.
4. Launch options. Either use the wrapper in [`scripts/`](scripts/), which reads the table above from
   [`scripts/forza-fg.conf`](scripts/forza-fg.conf):

   ```
   WINEDLLOVERRIDES="winmm,dxgi,d3dcompiler_47=n,b" /home/deck/fh-steam-deck/scripts/forza-fg.sh fh2 handheld %command%
   ```

   or set the variables by hand, FH2 handheld:

   ```
   PROTON_USE_XALIA=0 LSFGVK_PROFILE="Forza Handheld" VKD3D_FRAME_RATE=45 WINEDLLOVERRIDES="winmm,dxgi,d3dcompiler_47=n,b" %command%
   ```

   For the TV, a second Steam shortcut with `LSFGVK_PROFILE="Forza TV" VKD3D_FRAME_RATE=30`. FH3 uses 30 in both.

   * `LSFGVK_PROFILE` picks the profile from `conf.toml`. Without it the layer stays off, so other games aren't
     touched.
   * `VKD3D_FRAME_RATE` caps the real frame rate. Frame generation x2 then shows 90 (FH2 handheld) or 60. A
     steady capped base looks much better than an uncapped one that swings.
5. **Turn HDR off in the game's launcher.** Frame generation with HDR gave me banding in the sky, flickering
   textures and worse fps. In SDR it's clean. Use the SDR ReShade preset below to get the punch back.
6. Steam's per-game Performance settings (`...` > battery icon > per-game profile): refresh rate **90 Hz**
   handheld (60 Hz on the TV), frame limit **Off**.

Steam's performance overlay in Game Mode counts the generated frames, so it should read 90. If it reads 45, frame
generation is working but the real rate is only ~22: go back to step 2.

Settings in `conf.toml` reload while the game runs, so you can try `multiplier = 3` or another `flow_scale` live.

## 5. ReShade

> **Note.** We're not shader experts; we just liked how this looks on the Deck. If you have a better preset,
> please tell us: issues and PRs are welcome.
>
> **Nota.** No somos expertos en shaders; simplemente nos gustó cómo se ve en el Deck. Si tienes un mejor preset,
> por favor avísanos: issues y PRs son bienvenidos.

1. Install ReShade with DirectX 10/11/12 into the folder with the runtime's executable (as `dxgi.dll`).
2. Put the shaders in `reshade-shaders` and copy a preset next to the executable.
3. In `ReShade.ini`, under `[GENERAL]`:

   ```ini
   EffectSearchPaths=.\reshade-shaders\Shaders\**
   TextureSearchPaths=.\reshade-shaders\Textures\**
   PresetPath=.\Forza SDR.ini
   SkipLoadingDisabledEffects=1
   PerformanceMode=1
   ```

   The `**` makes ReShade search subfolders. Without it, shader packs that install into their own subfolder
   (LumeniteFX, iMMERSE and so on) and their textures are silently skipped.
4. **Use Microsoft's `d3dcompiler_47.dll` in the Proton prefix.** Wine's builtin compiler (vkd3d-shader) fails on
   some effects with `E5017 Unhandled attribute 'fastopt'`, which ReShade generates for `[loop]`. Install the
   Microsoft DLL into `pfx/drive_c/windows/system32/`, for example with `winetricks d3dcompiler_47` or by copying
   the same file winetricks downloads. A Proton update can put the builtin back; reinstall it if the errors return.

MSAA makes the depth buffer unreadable to ReShade, so leave out effects that need depth (AO, SSR, TRAA, motion).

### SDR preset (with frame generation), FH2 and FH3

* FH2: [`reshade/FH2/Forza SDR.ini`](reshade/FH2/Forza%20SDR.ini)
* FH3: [`reshade/FH3/Forza SDR.ini`](reshade/FH3/Forza%20SDR.ini)

The games in SDR look flatter than in HDR, so this brings back some of the HDR look:

1. Deband
2. Levels (black 0, white 250)
3. [Blooming HDR](https://github.com/BlueSkyDefender/AstrayFX): bloom intensity 0.08/0.20, saturation 0.95
4. [Local Contrast](https://github.com/Fubaxiusz/fubax-shaders) (limit 14)
5. Vibrance (0.02)
6. CAS sharpening (0.6)

Both games use the same file; the two copies are identical. Deband, Levels, Vibrance and CAS come with the standard
[reshade-shaders](https://github.com/crosire/reshade-shaders).

### HDR preset (without frame generation), FH2

[`reshade/FH2/FH2 HDR.ini`](reshade/FH2/FH2%20HDR.ini). The game outputs HDR10, so the usual SDR effects (Levels,
Vibrance, LocalContrast) burn the image. This uses
[Lilium's HDR shaders](https://github.com/EndlesslyFlowering/ReShade_HDR_shaders), in this order:

1. Deband
2. lilium hdr black floor fix
3. lilium tone mapping
4. lilium hdr brightness adjustment
5. lilium rcas hdr (sharpening)
6. lilium film grain, at 90% of its default intensity

Without frame generation, with HDR on and xalia off, FH2 handheld holds about 60 fps.

## Proton

* **Proton:** Experimental.
* **Launch options** without frame generation (Extra Options, ReShade and the Mod Platform need their DLLs native):

  ```
  PROTON_USE_XALIA=0 WINEDLLOVERRIDES="winmm,dxgi,d3dcompiler_47=n,b" %command%
  ```

  The DualSense mod adds its own wrapper, see below.

## Mods (FH2)

| Mod | What it does | Where |
|---|---|---|
| [FH2 Extra Options](https://github.com/RokkuDayo/ForzaHorizon2_ExtraOptions) | Quality-of-life options, livery quality, plugin loader, autodrive (D-pad down) | upstream |
| [FH2 Mod Platform](https://github.com/Trinculo54/fh2-mod-platform) | Loader that the mods below use (`d3dcompiler_47.dll`) | upstream; [my Proton fix](https://github.com/consultoria-deta/fh2-mod-platform/tree/wine-relocated-game) ([PR #17](https://github.com/Trinculo54/fh2-mod-platform/pull/17)) |
| [Community Garage](https://github.com/qiangqiang101/CommunityGarage) | Share and download tunes, liveries and vinyl groups from the game's menus | upstream (my Proton fixes are merged); see the crash note below |
| [FH2 DualSense](https://github.com/consultoria-deta/FH2-DualSense/tree/steam-deck/steamdeck) | Adaptive triggers, HD haptics and PlayStation button prompts | **my Steam Deck port** of [aminenrr/FH2-DualSense](https://github.com/aminenrr/FH2-DualSense) |
| [FH2 Universal Radio](https://github.com/Trinculo54/FH2-Universal-Radio) | Plays your Spotify / YouTube Music playlists on the Pulse radio station | upstream; optional native Linux helper below (tested in FH2 and FH3) |
| [FH2 Achievements](https://github.com/Trinculo54/fh2-achievements) | Achievements | upstream |
| CustomBindings 2.2.0 | Your own controller layout in Settings > Controls | Mod Platform mod |
| FH2Patch + 25-car pack | Extra cars, NODIRT, AI_HIDE, SPGarage plugins | loaded through Extra Options' plugin loader |

The Universal Radio dashboard (`http://<deck ip>:8420`) only works from a device on the same network as the Deck
and while the game is running.

### Community Garage: crash with livery textures on runtime 1.0.1

Symptom: the game stops with `CreatePlacementTexture2D ... 4096x4096` when it loads a car with a custom livery,
after a fast travel, or at the end of a championship. Community Garage puts the game on the online path that
renders livery "texture streams", which the runtime can't create. The mod's built-in workaround skipped that step
only on runtime 0.9.10, so on 1.0.1 the crash came back.

Fix: force the workaround in `communitygarage/server.ini` (the section name comes from the mod, not from this
guide):

```ini
[azimuth]
skip_livery_texture_streams=1
```

The visible cost is that layered liveries of Drivatars and other players don't show their texture streams. Tunes
are unaffected. Newer Community Garage releases (1.1.5 and later) turn the workaround on for every runtime version;
I haven't tested 1.1.5 on the Deck yet (it also moves its loader to `DWrite.dll`). **Status: confirmed on the
Deck with runtime 1.0.1: with the skip on, long sessions with liveries, fast travel and championships no longer stop.**

### FH2 Universal Radio: native Linux helper (optional)

**Status: working in game in FH2 and FH3 on the Deck.** Under Proton, every YouTube Music track starts
`yt-dlp.exe` twice and `ffmpeg.exe` once as Windows processes, and the audio crosses Wine pipes (wineserver). I
wrote an optional helper that runs the native Linux yt-dlp and ffmpeg instead and streams over a loopback socket.
It's prepared as a contribution to the radio's repo and isn't merged yet; until it is, you need a build of the radio
with the `[native]` section.

Setup:

1. Native binaries under your home folder (Proton's container can't see `/usr/local` or `/opt`):
   the helper plus a small `helper.sh` wrapper, yt-dlp from `yt-dlp_linux.zip` plus `deno` in the same folder, and
   a **PIE, dynamically linked** ffmpeg such as the
   [BtbN Linux builds](https://github.com/BtbN/FFmpeg-Builds/releases) (`ffmpeg-master-latest-linux64-gpl`).
   Proton's sandbox kills non-PIE static binaries (exit code 159), so the usual "static ffmpeg" builds don't work,
   and the helper itself is launched through the wrapper:

   ```sh
   #!/bin/sh
   exec /home/deck/fh2-radio-native/fh2-radio-native-helper.pie "$@"
   ```

2. In `fh2-radio/config.toml` (FH3: `fh3-radio/config.toml`):

   ```toml
   [native]
   enabled = true
   helper  = '/home/deck/fh2-radio-native/helper.sh'
   yt_dlp  = '/home/deck/fh2-radio-native/yt-dlp/yt-dlp_linux'
   ffmpeg  = '/home/deck/fh2-radio-native/ffmpeg-master-latest-linux64-gpl/bin/ffmpeg'
   ```

3. Fallback: if a path is missing or the helper doesn't answer, the radio logs why and uses the `.exe` path as
   before. `bridge.log` says `[native] helper up on 127.0.0.1:...` when the helper is in use, and
   `[yt] pipe started via native helper` for each track.

### DualSense on the Deck

The original is a Windows app that talks to the controller with `hidapi` and plays the haptics as audio. Under
Proton the game can't reach those devices, so the port splits it: a Mod Platform mod reads the rumble levels and
the car's sound buses inside the game and shares them through `/dev/shm/fh2-dualsense.shm`, and a small Python
helper in SteamOS (standard library only) drives the triggers over `hidraw` and plays the haptics to the
controller's `SpeakerHaptic` sink with PipeWire.

* Triggers work over Bluetooth or USB. **HD haptics need the USB cable** (a dock works). Your game audio stays
  where it was (TV, headphones).
* Install and launch options:
  [steamdeck/README.md](https://github.com/consultoria-deta/FH2-DualSense/blob/steam-deck/steamdeck/README.md) in
  the fork, release
  [v1.0.0-steamdeck](https://github.com/consultoria-deta/FH2-DualSense/releases/tag/v1.0.0-steamdeck).
* If you use the `scripts/forza-fg.sh` wrapper, set `DUALSENSE_HELPER` in `forza-fg.conf` and it starts the
  helper for you.

### Why the forks

* **Mod Platform under Proton.** Wine can't map the game at its preferred address, so the image is relocated.
  The platform compared absolute pointers with the file on disk and refused to load ("game's code isn't what this
  build expects"). The fork compares them relocation-aware. It also waits for Extra Options, which loads later
  under Wine, so both don't patch the same bytes at the same time.
* **Community Garage under Proton and on runtime 1.0.1.** Wine returned empty chunked responses as an error, so
  every request failed, and 1.0.1 moved the code the mod hooks. Both fixes are now upstream.
* **DualSense on Linux.** See above.

### FH2Patch on Linux

FH2Patch's SPGarage plugin can't find the save and Mount folders under Proton on its own. Give it the paths in
`FH2_SPGarage.ini` as `Z:\` paths, for example:

```
SaveRoot=Z:\home\deck\<runtime folder>\data\titles\1A96545B\saves
Mount=Z:\home\deck\<Forza Horizon 2>\Mount
```

The file is UTF-16; save it that way.

## Forza Horizon 3

Work in progress. What runs on my Deck today, all through Proton Experimental with the same xalia and frame
generation settings as FH2 (30 -> 60 fps, SDR, [`reshade/FH3/Forza SDR.ini`](reshade/FH3/Forza%20SDR.ini)):

* **DualSense:** triggers and haptics work in game, with the same `/dev/shm` channel and the same Python helper as
  FH2. The FH3 port isn't published yet.
* **Radio:** FH3 Universal Radio (my port of the FH2 radio) works in game through the normal `.exe` path.
  **Radio nativa FH3: en prueba** (the native Linux helper for FH3 is not yet tested in game).
* Extra Options port and the mod loader for FH3: not published yet.

More once these are tested and published.

## Credits

lsfg-vk by PancakeTAS, Lossless Scaling by THS. The mods and shaders by their authors, linked above. My forks keep
the original licenses.
