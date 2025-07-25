use anyhow::Result;
use zed::{
    extensions::{Extension, ExtensionContext},
    language_server::{LanguageServerId, LanguageServerName},
    workspace::Workspace,
};

mod commands;
mod language_server;
mod snippets;
mod themes;

pub struct NixMoxExtension;

impl Extension for NixMoxExtension {
    fn name(&self) -> &str {
        "nix-mox"
    }

    fn version(&self) -> &str {
        "1.0.0"
    }

    fn activate(&self, cx: &mut ExtensionContext) -> Result<()> {
        // Register language server for Nushell
        cx.register_language_server(
            LanguageServerId::new("nushell"),
            LanguageServerName::new("nushell"),
            "nu",
            &["--lsp"],
        )?;

        // Register commands
        cx.register_command("nix-mox:run-script", commands::run_script)?;
        cx.register_command("nix-mox:test-script", commands::test_script)?;
        cx.register_command("nix-mox:validate-security", commands::validate_security)?;
        cx.register_command("nix-mox:show-metrics", commands::show_metrics)?;
        cx.register_command("nix-mox:generate-docs", commands::generate_docs)?;
        cx.register_command("nix-mox:setup-wizard", commands::setup_wizard)?;

        // Register themes
        cx.register_theme("nix-mox-dark", themes::dark_theme())?;
        cx.register_theme("nix-mox-light", themes::light_theme())?;

        // Register snippets
        cx.register_snippets("nushell", snippets::nix_mox_snippets())?;

        log::info!("nix-mox extension activated");
        Ok(())
    }

    fn deactivate(&self) -> Result<()> {
        log::info!("nix-mox extension deactivated");
        Ok(())
    }
}

fn main() -> Result<()> {
    env_logger::init();
    zed::run_extension(NixMoxExtension)
}
