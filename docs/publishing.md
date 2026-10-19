# Publishing

Canonical repository: https://github.com/clankercode/lsp-openplanet-neovim

Neovim packages and plugin managers install directly from this public Git repository. No npm package or marketplace account is required for the plugin. The separate language server is the existing `openplanet-lsp` npm/crates.io package; this project does not publish a competing server package.

Repository metadata should include `openplanet`, `trackmania`, `angelscript`, `lsp`, `language-server`, `neovim` and the upstream server as homepage. GitHub renders the README, screenshot, licenses and documentation directly; no separate Pages build is needed for installation or documentation.

Before a release, run unit and live tests, inspect a fresh real-editor screenshot, update verification versions and limits, commit, push, and confirm CI. Create a semver tag only when the maintainer wants a versioned release. Plugin managers can pin a reviewed commit or tag.

Registry status: no registry PR was submitted. nvim-lspconfig is an optional compatibility dependency, not a required registry for distribution. A future upstream configuration PR would need to preserve the selective `info.toml` root guard and provide standalone AngelScript filetype support; submit only after checking their current contribution policy. No additional account setup is needed to use this repository.
