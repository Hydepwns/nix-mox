use anyhow::Result;
use zed::{workspace::Workspace, CommandContext};

pub fn run_script(cx: &mut CommandContext) -> Result<()> {
    let workspace = cx.workspace();
    let active_buffer = workspace.active_buffer()?;

    if let Some(path) = active_buffer.path() {
        if path.extension().and_then(|s| s.to_str()) == Some("nu") {
            // Execute the Nushell script
            let output = std::process::Command::new("nu")
                .arg(path)
                .output()?;

            if output.status.success() {
                cx.show_message("Script executed successfully");
            } else {
                cx.show_error(&format!(
                    "Script execution failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                ));
            }
        } else {
            cx.show_error("Current file is not a Nushell script");
        }
    } else {
        cx.show_error("No active file");
    }

    Ok(())
}

pub fn test_script(cx: &mut CommandContext) -> Result<()> {
    let workspace = cx.workspace();
    let active_buffer = workspace.active_buffer()?;

    if let Some(path) = active_buffer.path() {
        if path.extension().and_then(|s| s.to_str()) == Some("nu") {
            // Run tests for the script
            let output = std::process::Command::new("nu")
                .arg("scripts/tests/unit/comprehensive-config-tests.nu")
                .output()?;

            if output.status.success() {
                cx.show_message("Tests passed successfully");
            } else {
                cx.show_error(&format!(
                    "Tests failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                ));
            }
        } else {
            cx.show_error("Current file is not a Nushell script");
        }
    } else {
        cx.show_error("No active file");
    }

    Ok(())
}

pub fn validate_security(cx: &mut CommandContext) -> Result<()> {
    let workspace = cx.workspace();
    let active_buffer = workspace.active_buffer()?;

    if let Some(path) = active_buffer.path() {
        if path.extension().and_then(|s| s.to_str()) == Some("nu") {
            // Run security validation
            let output = std::process::Command::new("nu")
                .arg("scripts/core/security-validation.nu")
                .arg(path)
                .output()?;

            if output.status.success() {
                cx.show_message("Security validation passed");
            } else {
                cx.show_error(&format!(
                    "Security validation failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                ));
            }
        } else {
            cx.show_error("Current file is not a Nushell script");
        }
    } else {
        cx.show_error("No active file");
    }

    Ok(())
}

pub fn show_metrics(cx: &mut CommandContext) -> Result<()> {
    // Show nix-mox performance metrics
    let output = std::process::Command::new("nu")
        .arg("scripts/tools/size-dashboard.nu")
        .output()?;

    if output.status.success() {
        cx.show_message(&format!(
            "Metrics:\n{}",
            String::from_utf8_lossy(&output.stdout)
        ));
    } else {
        cx.show_error(&format!(
            "Failed to get metrics: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(())
}

pub fn generate_docs(cx: &mut CommandContext) -> Result<()> {
    // Generate nix-mox documentation
    let output = std::process::Command::new("nu")
        .arg("scripts/tools/generate-docs.nu")
        .output()?;

    if output.status.success() {
        cx.show_message("Documentation generated successfully");
    } else {
        cx.show_error(&format!(
            "Failed to generate documentation: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(())
}

pub fn setup_wizard(cx: &mut CommandContext) -> Result<()> {
    // Launch nix-mox setup wizard
    let output = std::process::Command::new("nu")
        .arg("scripts/core/setup.nu")
        .output()?;

    if output.status.success() {
        cx.show_message("Setup wizard completed successfully");
    } else {
        cx.show_error(&format!(
            "Setup wizard failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(())
}
