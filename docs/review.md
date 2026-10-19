# Review record

Independent T3-native Codex review of `f5fa5e1`, 2026-10-19, identified:

1. **Legacy cached root bypass.** nvim-lspconfig v1.8.0 `:LspStart` installs a BufReadPost callback passing a cached root to its manager. That path skipped our root guard. Reproduced red using an existing `other.toml` and real `:LspStart`, then fixed by guarding only the Openplanet manager's `try_add` entrypoint and recomputing each eligible file's root. This also avoids attaching nested plugins to a parent root. Seven real editor checks now pass on 0.10.4 with this path exercised.
2. **Marker precedence differs by Neovim version.** Reproduced red on 0.12.6 for a nearer `.openplanet-lsp.toml` beneath a parent `info.toml`. Replaced version-sensitive list semantics with explicit nearest-ancestor traversal. The 23-case configuration suite passes on 0.10.4, 0.11.5 and 0.12.6.
3. **Missing verification file in review checkpoint.** Added `verification.md` and durable raw JSON response receipts before publishing.

Visual review: independent source/geometry PASS on the final screenshot. It is 1360×480, approximately 12×28-pixel terminal cells. The bordered diagnostic float spans approximately (50,254) to (1154,394), below all seven source lines and above the statusline at y≈422. Full-frame and diagnostic-crop vision inspection also PASS: complete diagnostic, source and statusline remain readable without overlap or clipping. The initial capture's source overlap was corrected before this review.

Second review result will be added before publication. The coordinator may perform a further independent review.
