# Verification receipt

Verified 2026-10-19 on Linux x86_64. No server source changes or builds were required. The demo is a minimal Openplanet plugin authored in this repository, with an intentionally unused `laps` variable. It is not copied from another plugin; its source, screenshot and metadata use this repository's dual license. Nothing was staged into a running game.

## Executed checks

- Neovim **0.12.6**, system executable; published **openplanet-lsp 0.8.0** from PATH: **23 unit checks and 7 live editor checks passed**.
- Neovim **0.11.5**, official Linux release unpacked under `/tmp`: **23 unit checks and 7 live editor checks passed**, native `vim.lsp.config` / `enable` path.
- Neovim **0.10.4**, official Linux release unpacked under `/tmp`, **nvim-lspconfig v1.8.0** at `cb33dea610b7eff240985be9f6fe219920e630ef`: **23 unit checks and 7 live editor checks passed**, real legacy path.
- `npm install --prefix /tmp/openplanet-neovim-npm openplanet-lsp@0.8.0` installed the package. Setting `OPENPLANET_LSP` to its `node_modules/.bin/openplanet-lsp` passed all **7 live checks on 0.12.6**. npm reported its optional postinstall check blocked by local install-script policy; the platform binary package still installed and worked. No global npm state changed.
- `docs/assets/neovim.png`: real Neovim **0.12.6**, kitty, private Xvfb display, **1360×480 PNG**, verified with Pillow. Private terminal/display processes were terminated by the capture script.

The native `vim.lsp.enable("openplanet")`-only entrypoint was also smoke-tested on 0.12.6 and attached the shipped `lsp/openplanet.lua` configuration successfully.

Unit tests verify `.as` detection and syntax, stdio arguments, no injected initialization defaults, nearest plugin roots and parent workspace markers, standalone-file fallback, equal-priority mixed root markers, exact `info.toml` matching, rejection of unrelated TOML/Lua files, explicit executable override validation, and non-mutating options. The first red run reproduced Neovim identifying `.as` as `atlas`; the implementation changed it to `angelscript`.

Live tests launch the actual server through Neovim and assert attachment, the real `unused-declaration` diagnostic, hover content, completion containing the local `greeting` symbol, shared source/manifest client, preserved TOML filetype, and no attachment to an existing `other.toml`, including after legacy `:LspStart` installs its cached-root callback. These are actual JSON-RPC responses, not an emulated server. Versioned raw response receipts are in [receipts/](receipts/); `screenshot.json` records the diagnostic shown in the screenshot.

## Reproduce

From the repository root, with Neovim and the published server installed:

```sh
bash scripts/test.sh
nvim --headless -u NONE -l tests/live.lua
```

For a binary outside PATH:

```sh
OPENPLANET_LSP=/absolute/path/to/openplanet-lsp nvim --headless -u NONE -l tests/live.lua
```

For the legacy stack:

```sh
LSPCONFIG_PATH=/path/to/nvim-lspconfig-v1.8.0 /path/to/nvim-0.10.4 --headless -u NONE -l tests/live.lua
```

Live runs write `artifacts/live.json`. The tests inspect the shipped demo without saving edits. To capture the editor on Linux, install kitty, Xvfb, ImageMagick's `import`, and Python 3, then:

```sh
python3 scripts/capture.py
```

This runs real Neovim in kitty, waits for the real LSP diagnostic, opens Neovim's diagnostic float, and captures the private X display. It writes the PNG and `artifacts/screenshot-evidence.json`; no HTML rendering or simulated editor content is involved.

## Visual review

The first capture put the diagnostic float over the last source line. A second capture moved it beneath all seven source lines and reduced empty vertical space. Full-frame and diagnostic-crop inspection passed: the full diagnostic text, source and statusline are legible with no clipping. The diagnostic float begins at editor row 9, column 4 with a maximum width of 90 cells, fitting a 1360×480 terminal at 15pt; the statusline is below the float. Independent source/geometry review is recorded in `review.md` when completed.

## Exact limits

- `textDocument/definition` returned no location for the demo's local variable with server 0.8.0 on these runs. The integration forwards navigation requests, but this receipt **does not claim successful go-to-definition**.
- A first test expected a string-to-int assignment diagnostic; 0.8.0 instead only returned an unused-variable diagnostic. The fixture now deliberately tests that supported diagnostic. No claim is made for type-mismatch checking.
- Completion and hover were checked through real Neovim LSP requests. Completion-menu UI acceptance, completion plugins, rename, formatting, semantic tokens and inlay hints were not exercised.
- Windows, macOS, ARM, Neovim 0.10.0–0.10.3 and 0.11.0–0.11.4 were not run. CI covers Linux 0.10.4, 0.11.5 and stable.
- No game/plugin runtime test was done; the screenshot is the editor, not Trackmania. No fixture type database is bundled or enabled.
- The server may auto-detect machine-local Openplanet data. Portable live assertions deliberately use only local declarations and builtin syntax; full game-API coverage depends on user-installed data.
- Plugin-manager UI flows were documented, not driven interactively. The repository was loaded directly into Neovim's runtimepath for the tests.
- Hosted CI status is recorded separately; a local pass is not evidence that GitHub Actions passed.
