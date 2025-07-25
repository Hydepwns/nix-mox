use anyhow::Result;
use zed::language_server::{LanguageServerId, LanguageServerName};

pub struct NushellLanguageServer;

impl NushellLanguageServer {
    pub fn new() -> Self {
        Self
    }

    pub fn register(cx: &mut zed::extensions::ExtensionContext) -> Result<()> {
        cx.register_language_server(
            LanguageServerId::new("nushell"),
            LanguageServerName::new("nushell"),
            "nu",
            &["--lsp"],
        )?;

        Ok(())
    }
}

impl Default for NushellLanguageServer {
    fn default() -> Self {
        Self::new()
    }
}
