# Codec Terminal

A covert-radio themed setup for Claude Code and Windows Terminal on Windows.

## What's in it

| Piece | Files |
|---|---|
| Status line (model, weather, 5h / 7d usage bars, context %) | `codec/statusline.ps1`, `codec/weather.ps1` |
| Reply voice (Claude Code output style) | `output-styles/codec.md` |
| Silent on-screen alerts (Notification / Stop hooks) | `codec/alert.ps1` |
| Matrix-rain + faint Jolly Roger background shader | `codec/matrix.hlsl` |
| Exit sequence: rain fades, Jolly Roger falls, "OFFLINE" | `codec/outro.ps1`, `codec/offline.hlsl`, `codec/shader-swap.ps1`, `codec/demo.ps1` |
| Login gate before Claude starts (cosmetic, not real security) | `codec/login.ps1` |
| Startup banner | `codec/banner.ps1` |
| Old whale background image (unused) | `codec/whale.png` |
| Config snippets | `config/claude-settings.snippet.json`, `config/windows-terminal.snippet.json`, `config/Microsoft.PowerShell_profile.ps1` |

## Install

1. Copy `codec/` to `%USERPROFILE%\.claude\codec\` and `output-styles/codec.md` to `%USERPROFILE%\.claude\output-styles\`.
2. Merge `config/claude-settings.snippet.json` into `%USERPROFILE%\.claude\settings.json`.
3. Merge `config/windows-terminal.snippet.json` into Windows Terminal's `settings.json` (Settings → Open JSON file).
   Windows Terminal may not expand `%USERPROFILE%` in every field (e.g. `experimental.pixelShaderPath`), so replace it with your full path if needed.
4. Optional: add the `claude` wrapper from `config/Microsoft.PowerShell_profile.ps1` to your PowerShell profile so the outro plays on exit.

## Notes

- Windows Terminal only recompiles a shader when its `settings.json` changes; touch the file after editing a `.hlsl`.
- If the background gets stuck on the offline shader: `powershell -File %USERPROFILE%\.claude\codec\shader-swap.ps1 -To matrix`.
- `login.ps1` stores a salted PBKDF2 hash in `codec/login.dat` on first run. Delete that file to reset. It is excluded from this repo.
- Weather comes from wttr.in by IP and is cached locally (also excluded).
