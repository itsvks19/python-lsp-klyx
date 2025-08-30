use klyx::LanguageServerId;
use klyx_extension_api::{self as klyx, Result, serde_json::json, settings::LspSettings};

struct PythonLspExtension {}

impl klyx::Extension for PythonLspExtension {
    fn new() -> Self {
        Self {}
    }

    fn uninstall(&mut self) {
        // Default implementation does nothing.
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &klyx::Worktree,
    ) -> Result<klyx::Command> {
        match worktree.which("pylsp") {
            Some(path) => Ok(klyx::Command {
                command: path,
                args: vec!["-v".into()],
                env: vec![],
            }),
            None => Err("Unable to find pylsp from worktree".into()),
        }
    }

    fn language_server_initialization_options(
        &mut self,
        server_id: &LanguageServerId,
        worktree: &klyx::Worktree,
    ) -> Result<Option<klyx::serde_json::Value>> {
        let settings = LspSettings::for_worktree(server_id.as_ref(), worktree)
            .ok()
            .and_then(|lsp_settings| lsp_settings.initialization_options.clone())
            .unwrap_or_default();
        Ok(Some(settings))
    }

    fn language_server_workspace_configuration(
        &mut self,
        server_id: &LanguageServerId,
        worktree: &klyx::Worktree,
    ) -> Result<Option<klyx::serde_json::Value>> {
        let settings = LspSettings::for_worktree(server_id.as_ref(), worktree)
            .ok()
            .and_then(|lsp_settings| lsp_settings.settings.clone())
            .unwrap_or_default();

        // pylsp expects a top level `pylsp` key, so we'll wrap the settings
        let settings = json!({
            "pylsp": settings
        });

        Ok(Some(settings))
    }
}

klyx::register_extension!(PythonLspExtension);
