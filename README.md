# Forza Horizon 2 (Azimuth) on the Steam Deck

My setup for Forza Horizon 2 on a Steam Deck OLED through [Azimuth](https://almost-there-games.itch.io/azimuth)
and Proton: a steady 60 fps handheld at 1280x800 with HDR, and a steady 30 fps docked at 1080p. It includes the
mods I run, the Proton fixes I had to write for some of them, and my HDR ReShade preset.

Azimuth is closed source and the game files aren't redistributable, so this repo has no binaries from either. It
links to every mod and holds only my preset, the settings, and the forks with the fixes.

## Performance

Measured in desktop mode with MangoHud, same route, same car, Deck OLED:

| Setup | Azimuth 0.9.10 | Azimuth 1.0.1 |
|---|---|---|
| Handheld, 1280x800, settings below | 47.8 fps avg | 59-60 fps avg |

**Use Azimuth 1.0.1.** It's the biggest single gain. If you aren't hitting 60 on 1.0.1, check these first:

* **Start a fresh save on the Deck.** Saves copied over from a PC have been reported to run much worse.
* **The first launch after any change compiles shaders.** For a minute or two you can see 1 fps. Let it finish
  and close the game cleanly (from the menu), so Azimuth writes its pipeline cache. The next launches are fast.
* **Docked, set the game resolution in Steam to 1920x1080.** Steam > the game > Properties > Game resolution.
  Otherwise the game renders at your TV's 4K and ReShade processes 4K too.
* **ReShade:** set `SkipLoadingDisabledEffects=1` in `ReShade.ini`, so effects you don't use aren't compiled.

## Game settings

Azimuth launcher and in-game options:

| | Handheld (Deck OLED) | Docked (TV) |
|---|---|---|
| Resolution | 1280x800 | 1920x1080 |
| Frame rate | 60 | 30 (locked, very stable) |
| HDR | On | On |
| MSAA | 4x | 4x |
| Texture detail | High | High |
| Car detail | High | High |

Extra Options: enhanced liveries, livery MSAA 2x.

Docked at 1080p, MSAA 2x and normal car detail give about 5 fps more, but not a steady 60.

## Proton

* **Proton:** Experimental.
* **Launch options** (Extra Options, ReShade and the Mod Platform all need their DLLs loaded native):

  ```
  WINEDLLOVERRIDES="winmm,dxgi,d3dcompiler_47=n,b" %command%
  ```

  The DualSense mod adds its own wrapper, see its README.

## Mods

| Mod | What it does | Where |
|---|---|---|
| [FH2 Extra Options](https://github.com/RokkuDayo/ForzaHorizon2_ExtraOptions) | Quality-of-life options, livery quality, plugin loader, autodrive (D-pad down) | upstream |
| [FH2 Mod Platform](https://github.com/Trinculo54/fh2-mod-platform) | Loader that the mods below use (`d3dcompiler_47.dll`) | upstream; [my Proton fix](https://github.com/consultoria-deta/fh2-mod-platform/tree/wine-relocated-game) ([PR #17](https://github.com/Trinculo54/fh2-mod-platform/pull/17)) |
| [Community Garage](https://github.com/qiangqiang101/CommunityGarage) | Share and download tunes, liveries and vinyl groups from the game's menus | upstream 1.1.2+ (my Proton and 1.0.1 fixes are merged) |
| [FH2 DualSense](https://github.com/consultoria-deta/FH2-DualSense/tree/steam-deck/steamdeck) | Adaptive triggers, HD haptics and PlayStation button prompts | **my Steam Deck port** of [aminenrr/FH2-DualSense](https://github.com/aminenrr/FH2-DualSense) |
| [FH2 Universal Radio](https://github.com/Trinculo54/FH2-Universal-Radio) | Plays your Spotify / YouTube Music playlists on the Pulse radio station | upstream |
| [FH2 Achievements](https://github.com/Trinculo54/fh2-achievements) | Achievements | upstream |
| CustomBindings 2.2.0 | Your own controller layout in Settings > Controls | Mod Platform mod |
| FH2Patch + 25-car pack | Extra cars, NODIRT, AI_HIDE, SPGarage plugins | loaded through Extra Options' plugin loader |

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

## ReShade (HDR)

The game outputs HDR10, so the usual SDR effects (Levels, Vibrance, LocalContrast, AmbientLight) burn the image.
I use [Lilium's HDR shaders](https://github.com/EndlesslyFlowering/ReShade_HDR_shaders), in this order:

1. Deband
2. lilium hdr black floor fix
3. lilium tone mapping
4. lilium hdr brightness adjustment
5. lilium rcas hdr (sharpening)
6. lilium film grain, at 90% of its default intensity

The preset is [`reshade/FH2 HDR.ini`](reshade/FH2%20HDR.ini); values it doesn't list are the shader defaults.
I use the same preset handheld and docked. MSAA makes the depth buffer unreadable to ReShade, so leave out
effects that need depth (AO, SSR, TRAA, motion effects).

1. Install ReShade with DirectX 10/11/12 into the folder with `azimuth.exe` (as `dxgi.dll`).
2. Put the Lilium `Shaders` and `Textures` folders in `reshade-shaders`.
3. Copy the preset next to `azimuth.exe` and select it in the overlay.

## Credits

Azimuth by Almost There Games. The mods by their authors, linked above. My forks keep the original licenses.
