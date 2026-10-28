# Forza Horizon 2 (Azimuth) on the Steam Deck

My setup for Forza Horizon 2 on a Steam Deck OLED through [Azimuth](https://almost-there-games.itch.io/azimuth)
and Proton. Handheld it shows **90 fps** at 1280x800 with car and scenery detail on High (45 real fps doubled with
Lossless Scaling frame generation). It also covers the mods I run, the Proton fixes I had to write for some of them,
and my ReShade presets.

Azimuth is closed source and the game files aren't redistributable, so this repo has no binaries from either. It
links to every mod and holds only my presets, configs, settings and the forks with the fixes.

## The short version

If you are stuck at 40-50 fps, do steps 1 and 2 before anything else.

1. **Use Azimuth 1.0.1** and a fresh save made on the Deck.
2. **Turn off xalia.** Add `PROTON_USE_XALIA=0` to the launch options (see below). This was my biggest single gain
   in Game Mode, with or without frame generation.
3. Optional: frame generation with lsfg-vk for 90 fps (handheld) or 60 fps (TV).
4. Steam's per-game Performance settings: refresh rate 90 Hz handheld, frame limit Off.

## 1. Azimuth 1.0.1 and a fresh save

Measured in desktop mode with MangoHud, same route, same car:

| Setup | Azimuth 0.9.10 | Azimuth 1.0.1 |
|---|---|---|
| Handheld, 1280x800 | 47.8 fps avg | 59-60 fps avg |

* **Saves copied over from a PC** have been reported to run much worse. Start a new one on the Deck.
* **The first launch after any change compiles shaders.** For a minute or two you can see very low fps. Let it
  finish and quit from the game's menu, so Azimuth writes its pipeline cache. The next launches are fast.
* **Docked:** set the game resolution in Steam to 1920x1080 (the game > Properties > Game resolution). Otherwise
  the game and ReShade render at your TV's 4K.

## 2. Turn off xalia (the big one)

Proton starts `xalia.exe`, an accessibility helper that lets a controller drive Windows dialogs. With Azimuth it
used about 25% of a CPU core plus extra `wineserver` load. The Deck shares its 15 W between CPU and GPU, so that
CPU time came out of the GPU's budget: in Game Mode the GPU sat at 650-1100 MHz instead of up to 1600 MHz.

What I measured on the same session, same settings, only xalia changed:

| | GPU clock | Real fps | On screen (frame gen x2) |
|---|---|---|---|
| xalia on (Proton default) | 650-1100 MHz | ~22 | ~45 |
| `PROTON_USE_XALIA=0` | 1100-1400 MHz | 45 | **90** |

Desktop mode wasn't affected as much, which is why my earlier desktop benchmarks looked fine while Game Mode didn't.

The only thing you lose: in the Azimuth launcher window you navigate with the touchscreen or the trackpads instead
of the D-pad. The game itself is unaffected.

You can check if it's running with `pgrep -a xalia` in a desktop terminal (or over SSH) while the game is open.

## 3. Game settings

Azimuth launcher, handheld:

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

1. In Steam: Lossless Scaling > Properties > Betas > select the **`lsfg-vk`** branch, and let it install. That
   branch ships `lsfg-vk.dll` in `steamapps/common/Lossless Scaling/`.
2. Download `lsfg-vk-2.0.0.tar.xz` from the [lsfg-vk releases](https://github.com/PancakeTAS/lsfg-vk/releases) and
   extract it into `~/.local`, so you end up with `~/.local/lib/liblsfg-vk-layer.so` and
   `~/.local/share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json`. No sudo needed and it
   survives SteamOS updates.
3. Copy [`lsfg-vk/conf.toml`](lsfg-vk/conf.toml) to `~/.config/lsfg-vk/conf.toml`. Fix the DLL path if your Steam
   library is on the SD card.
4. Launch options, handheld:

   ```
   PROTON_USE_XALIA=0 LSFGVK_PROFILE="FH2 Handheld" VKD3D_FRAME_RATE=45 WINEDLLOVERRIDES="winmm,dxgi,d3dcompiler_47=n,b" %command%
   ```

   For the TV, a second Steam shortcut with `LSFGVK_PROFILE="FH2 TV" VKD3D_FRAME_RATE=30`.

   * `LSFGVK_PROFILE` picks the profile from `conf.toml`. Without it the layer stays off, so other games aren't
     touched.
   * `VKD3D_FRAME_RATE` caps the real frame rate. Frame generation x2 then shows 90 (handheld) or 60 (TV). A
     steady capped base looks much better than an uncapped one that swings.
5. **Turn HDR off in the Azimuth launcher.** Frame generation with HDR gave me banding in the sky, flickering
   textures and worse fps. In SDR it's clean. Use the SDR ReShade preset below to get the punch back.
6. Steam's per-game Performance settings (`...` > battery icon > per-game profile): refresh rate **90 Hz**
   handheld (60 Hz on the TV), frame limit **Off**.

Steam's performance overlay in Game Mode counts the generated frames, so it should read 90. If it reads 45, frame
generation is working but the real rate is only ~22: go back to step 2.

Settings in `conf.toml` reload while the game runs, so you can try `multiplier = 3` or another `flow_scale` live.

## 5. ReShade

1. Install ReShade with DirectX 10/11/12 into the folder with `azimuth.exe` (as `dxgi.dll`).
2. Put the shaders in `reshade-shaders`, copy a preset next to `azimuth.exe` and select it in the overlay.
3. In `ReShade.ini` set `SkipLoadingDisabledEffects=1` and `PerformanceMode=1`, so unused effects aren't compiled.

MSAA makes the depth buffer unreadable to ReShade, so leave out effects that need depth (AO, SSR, TRAA, motion).

### SDR preset (with frame generation)

[`reshade/FH2 SDR.ini`](reshade/FH2%20SDR.ini). The game in SDR looks flatter than its HDR, so this brings back
some of the HDR look:

1. Deband
2. Levels (black 0, white 250)
3. [Blooming HDR](https://github.com/BlueSkyDefender/AstrayFX) (bloom 0.05/0.13, saturation 0.95)
4. [Local Contrast](https://github.com/Fubaxiusz/fubax-shaders) (limit 14)
5. Vibrance (0.02)
6. CAS sharpening (0.6)

Deband, Levels, Vibrance and CAS come with the standard
[reshade-shaders](https://github.com/crosire/reshade-shaders).

### HDR preset (without frame generation)

[`reshade/FH2 HDR.ini`](reshade/FH2%20HDR.ini). The game outputs HDR10, so the usual SDR effects (Levels,
Vibrance, LocalContrast) burn the image. This uses
[Lilium's HDR shaders](https://github.com/EndlesslyFlowering/ReShade_HDR_shaders), in this order:

1. Deband
2. lilium hdr black floor fix
3. lilium tone mapping
4. lilium hdr brightness adjustment
5. lilium rcas hdr (sharpening)
6. lilium film grain, at 90% of its default intensity

Without frame generation, with HDR on and xalia off, handheld holds about 60 fps.

## Proton

* **Proton:** Experimental.
* **Launch options** without frame generation (Extra Options, ReShade and the Mod Platform need their DLLs native):

  ```
  PROTON_USE_XALIA=0 WINEDLLOVERRIDES="winmm,dxgi,d3dcompiler_47=n,b" %command%
  ```

  The DualSense mod adds its own wrapper, see its README.

## Mods

| Mod | What it does | Where |
|---|---|---|
| [FH2 Extra Options](https://github.com/RokkuDayo/ForzaHorizon2_ExtraOptions) | Quality-of-life options, livery quality, plugin loader, autodrive (D-pad down) | upstream |
| [FH2 Mod Platform](https://github.com/Trinculo54/fh2-mod-platform) | Loader that the mods below use (`d3dcompiler_47.dll`) | upstream; [my Proton fix](https://github.com/consultoria-deta/fh2-mod-platform/tree/wine-relocated-game) ([PR #17](https://github.com/Trinculo54/fh2-mod-platform/pull/17)) |
| [Community Garage](https://github.com/qiangqiang101/CommunityGarage) | Share and download tunes, liveries and vinyl groups from the game's menus | upstream 1.1.3 (my Proton and 1.0.1 fixes are merged) |
| [FH2 DualSense](https://github.com/consultoria-deta/FH2-DualSense/tree/steam-deck/steamdeck) | Adaptive triggers, HD haptics and PlayStation button prompts | **my Steam Deck port** of [aminenrr/FH2-DualSense](https://github.com/aminenrr/FH2-DualSense) |
| [FH2 Universal Radio](https://github.com/Trinculo54/FH2-Universal-Radio) | Plays your Spotify / YouTube Music playlists on the Pulse radio station | upstream |
| [FH2 Achievements](https://github.com/Trinculo54/fh2-achievements) | Achievements | upstream |
| CustomBindings 2.2.0 | Your own controller layout in Settings > Controls | Mod Platform mod |
| FH2Patch + 25-car pack | Extra cars, NODIRT, AI_HIDE, SPGarage plugins | loaded through Extra Options' plugin loader |

The Universal Radio dashboard (`http://<deck ip>:8420`) only works from a device on the same network as the Deck
and while the game is running.

### Why the forks

* **Mod Platform under Proton.** Wine can't map the game at its preferred address, so the image is relocated.
  The platform compared absolute pointers with the file on disk and refused to load ("game's code isn't what this
  build expects"). The fork compares them relocation-aware. It also waits for Extra Options, which loads later
  under Wine, so both don't patch the same bytes at the same time.
* **Community Garage under Proton and on Azimuth 1.0.1.** Wine returned empty chunked responses as an error, so
  every request failed, and 1.0.1 moved the code the mod hooks. Both fixes are now upstream.
* **DualSense on Linux.** The original is a Windows app that talks to the controller with `hidapi` and plays the
  haptics as audio. Under Proton the game can't reach those devices, so the port splits it: a Mod Platform mod
  reads the rumble levels and the car's sound buses inside the game, and a small Python helper in SteamOS drives
  the triggers over `hidraw` and plays the haptics to the controller's `SpeakerHaptic` sink with PipeWire.
  Triggers work over Bluetooth or USB. **HD haptics need the USB cable** (a dock works). Your game audio stays
  where it was (TV, headphones).

### FH2Patch on Linux

FH2Patch's SPGarage plugin can't find the save and Mount folders under Proton on its own. Give it the paths in
`FH2_SPGarage.ini` as `Z:\` paths, for example:

```
SaveRoot=Z:\home\deck\<azimuth>\data\titles\1A96545B\saves
Mount=Z:\home\deck\<Forza Horizon 2>\Mount
```

The file is UTF-16; save it that way.

## Credits

Azimuth by Almost There Games. lsfg-vk by PancakeTAS, Lossless Scaling by THS. The mods and shaders by their
authors, linked above. My forks keep the original licenses.
