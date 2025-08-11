import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { exec } from 'child_process';

// nix-mox Extension for VS Code
export function activate(context: vscode.ExtensionContext) {
    console.log('nix-mox Nushell extension is now active!');

    // Register commands
    registerCommands(context);

    // Initialize providers
    initializeProviders(context);

    // Setup file watchers
    setupFileWatchers(context);

    // Show welcome message
    showWelcomeMessage();
}

function registerCommands(context: vscode.ExtensionContext) {
    // Run Script Command
    const runScript = vscode.commands.registerCommand('nix-mox.runScript', async (uri?: vscode.Uri) => {
        const scriptPath = uri?.fsPath || vscode.window.activeTextEditor?.document.fileName;
        if (!scriptPath || !scriptPath.endsWith('.nu')) {
            vscode.window.showErrorMessage('Please select a .nu file to run');
            return;
        }

        await runNushellScript(scriptPath);
    });

    // Test Script Command
    const testScript = vscode.commands.registerCommand('nix-mox.testScript', async (uri?: vscode.Uri) => {
        const scriptPath = uri?.fsPath || vscode.window.activeTextEditor?.document.fileName;
        if (!scriptPath) {
            vscode.window.showErrorMessage('No script file selected');
            return;
        }

        await runTests(scriptPath);
    });

    // Validate Script Security
    const validateScript = vscode.commands.registerCommand('nix-mox.validateScript', async (uri?: vscode.Uri) => {
        const scriptPath = uri?.fsPath || vscode.window.activeTextEditor?.document.fileName;
        if (!scriptPath) {
            vscode.window.showErrorMessage('No script file selected');
            return;
        }

        await validateSecurity(scriptPath);
    });

    // Show Metrics
    const showMetrics = vscode.commands.registerCommand('nix-mox.showMetrics', async () => {
        await showPerformanceMetrics();
    });

    // Generate Documentation
    const generateDocs = vscode.commands.registerCommand('nix-mox.generateDocs', async () => {
        await generateDocumentation();
    });

        // Setup Wizard
    const setupWizard = vscode.commands.registerCommand('nix-mox.setupWizard', async () => {
        await runSetupWizard();
    });

    // Format Document
    const formatDocument = vscode.commands.registerCommand('nix-mox.formatDocument', async () => {
        const editor = vscode.window.activeTextEditor;
        if (editor && editor.document.languageId === 'nushell') {
            await vscode.commands.executeCommand('editor.action.formatDocument');
        } else {
            vscode.window.showWarningMessage('Please open a Nushell file to format');
        }
    });

    // Register all commands
    context.subscriptions.push(
        runScript,
        testScript,
        validateScript,
        showMetrics,
        generateDocs,
        setupWizard,
        formatDocument
    );
}

function initializeProviders(context: vscode.ExtensionContext) {
    // Completion Provider
    const completionProvider = vscode.languages.registerCompletionItemProvider(
        'nushell',
        {
            provideCompletionItems(document: vscode.TextDocument, position: vscode.Position) {
                return getNixMoxCompletions(document, position);
            }
        },
        '.' // Trigger on dot
    );

    // Hover Provider
    const hoverProvider = vscode.languages.registerHoverProvider('nushell', {
        provideHover(document, position) {
            return getNixMoxHover(document, position);
        }
    });

    // Definition Provider
    const definitionProvider = vscode.languages.registerDefinitionProvider('nushell', {
        provideDefinition(document, position) {
            return getNixMoxDefinition(document, position);
        }
    });

    // Diagnostic Provider
    const diagnosticCollection = vscode.languages.createDiagnosticCollection('nix-mox');
    context.subscriptions.push(diagnosticCollection);

    // Update diagnostics on document changes
    vscode.workspace.onDidChangeTextDocument((event) => {
        if (event.document.languageId === 'nushell') {
            updateDiagnostics(event.document, diagnosticCollection);
        }
    });

    // Formatting Provider
    const formattingProvider = vscode.languages.registerDocumentFormattingEditProvider('nushell', {
        provideDocumentFormattingEdits(document: vscode.TextDocument): vscode.TextEdit[] {
            return formatNushellDocument(document);
        }
    });

    // Code Actions Provider
    const codeActionProvider = vscode.languages.registerCodeActionsProvider('nushell', {
        provideCodeActions(document, range, context) {
            return provideNushellCodeActions(document, range, context);
        }
    }, {
        providedCodeActionKinds: [
            vscode.CodeActionKind.QuickFix,
            vscode.CodeActionKind.Refactor
        ]
    });

    context.subscriptions.push(
        completionProvider,
        hoverProvider,
        definitionProvider,
        formattingProvider,
        codeActionProvider
    );
}

function setupFileWatchers(context: vscode.ExtensionContext) {
    // Watch for .nu file changes
    const watcher = vscode.workspace.createFileSystemWatcher('**/*.nu');

    watcher.onDidChange((uri) => {
        // Auto-validate on change if enabled
        const config = vscode.workspace.getConfiguration('nix-mox');
        if (config.get('securityValidation')) {
            validateSecurity(uri.fsPath);
        }
    });

    context.subscriptions.push(watcher);
}

async function runNushellScript(scriptPath: string) {
    const config = vscode.workspace.getConfiguration('nix-mox');
    const nushellPath = config.get('nushellPath', 'nu');

    const terminal = vscode.window.createTerminal({
        name: `nix-mox: ${path.basename(scriptPath)}`,
        cwd: path.dirname(scriptPath)
    });

    terminal.show();

    // Enable metrics if configured
    const metricsEnabled = config.get('enableMetrics', true);
    const envVars = metricsEnabled ? 'NIX_MOX_METRICS_ENABLED=true ' : '';

    terminal.sendText(`${envVars}${nushellPath} "${scriptPath}"`);
}

async function runTests(scriptPath: string) {
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!workspaceRoot) {
        vscode.window.showErrorMessage('No workspace folder found');
        return;
    }

    const terminal = vscode.window.createTerminal({
        name: 'nix-mox Tests',
        cwd: workspaceRoot
    });

    terminal.show();

    // Check if it's a test file or regular script
    if (scriptPath.includes('/tests/')) {
        terminal.sendText(`nu "${scriptPath}"`);
    } else {
        // Run the full test suite
        terminal.sendText('nu -c "source scripts/testing/run-tests.nu; run []"');
    }
}

async function validateSecurity(scriptPath: string) {
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!workspaceRoot) {
        return;
    }

    vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: "Validating script security...",
        cancellable: false
    }, async () => {
        return new Promise<void>((resolve) => {
            const securityScript = path.join(workspaceRoot, 'scripts/lib/security.nu');

            exec(`nu -c "use ${securityScript} *; validate_script_security '${scriptPath}'"`, (error, stdout, stderr) => {
                if (error) {
                    vscode.window.showErrorMessage(`Security validation failed: ${error.message}`);
                } else {
                    try {
                        const result = JSON.parse(stdout);
                        if (result.is_safe) {
                            vscode.window.showInformationMessage('✅ Script passed security validation');
                        } else {
                            const threats = result.threats.map((t: any) => t.description).join(', ');
                            vscode.window.showWarningMessage(`⚠️ Security issues found: ${threats}`);
                        }
                    } catch {
                        vscode.window.showInformationMessage('Security validation completed');
                    }
                }
                resolve();
            });
        });
    });
}

async function showPerformanceMetrics() {
    const panel = vscode.window.createWebviewPanel(
        'nixMoxMetrics',
        'nix-mox Performance Metrics',
        vscode.ViewColumn.One,
        {
            enableScripts: true,
            retainContextWhenHidden: true
        }
    );

    // Read metrics data
    const metricsPath = '/tmp/nix-mox-metrics.prom';
    let metricsData = 'No metrics data available';

    try {
        if (fs.existsSync(metricsPath)) {
            metricsData = fs.readFileSync(metricsPath, 'utf8');
        }
    } catch (error) {
        console.error('Failed to read metrics:', error);
    }

    panel.webview.html = getMetricsWebviewContent(metricsData);
}

async function generateDocumentation() {
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!workspaceRoot) {
        vscode.window.showErrorMessage('No workspace folder found');
        return;
    }

    vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: "Generating documentation...",
        cancellable: false
    }, async () => {
        const terminal = vscode.window.createTerminal({
            name: 'nix-mox Docs',
            cwd: workspaceRoot
        });

        terminal.show();
        terminal.sendText('nu scripts/analysis/generate-docs.nu');
    });
}

async function runSetupWizard() {
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!workspaceRoot) {
        vscode.window.showErrorMessage('No workspace folder found');
        return;
    }

    const terminal = vscode.window.createTerminal({
        name: 'nix-mox Setup Wizard',
        cwd: workspaceRoot
    });

    terminal.show();
    terminal.sendText('nu scripts/setup/unified-setup.nu');
}

function getNixMoxCompletions(document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
    const completions: vscode.CompletionItem[] = [];

    // nix-mox specific completions
    const nixMoxFunctions = [
        'detect_platform', 'validate_platform', 'get_platform_info',
        'log_info', 'log_warn', 'log_error', 'log_debug',
        'create_error', 'handle_script_error', 'suggest_recovery',
        'track_test', 'assert_true', 'assert_false', 'assert_equal',
        'validate_script_security', 'check_dangerous_patterns',
        'start_performance_monitor', 'end_performance_monitor',
        'load_config', 'save_config', 'merge_config', 'validate_config'
    ];

    nixMoxFunctions.forEach(func => {
        const completion = new vscode.CompletionItem(func, vscode.CompletionItemKind.Function);
        completion.documentation = new vscode.MarkdownString(`nix-mox function: \`${func}\``);
        completion.insertText = new vscode.SnippetString(`${func} $1`);
        completions.push(completion);
    });

    return completions;
}

function getNixMoxHover(document: vscode.TextDocument, position: vscode.Position): vscode.Hover | undefined {
    const range = document.getWordRangeAtPosition(position);
    const word = document.getText(range);

    // Provide hover information for nix-mox functions
    const hoverInfo: { [key: string]: string } = {
        'detect_platform': 'Detects the current platform (linux, darwin, windows)',
        'log_info': 'Logs an informational message with timestamp',
        'track_test': 'Records test execution results for coverage reporting',
        'validate_script_security': 'Validates script for security threats and dangerous patterns'
    };

    if (hoverInfo[word]) {
        return new vscode.Hover(new vscode.MarkdownString(`**nix-mox**: ${hoverInfo[word]}`));
    }

    return undefined;
}

function getNixMoxDefinition(document: vscode.TextDocument, position: vscode.Position): vscode.Location | undefined {
    // This would implement "Go to Definition" for nix-mox functions
    const range = document.getWordRangeAtPosition(position);
    const word = document.getText(range);

    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!workspaceRoot) return undefined;

    // Map functions to their source files
    const functionFiles: { [key: string]: string } = {
        'detect_platform': 'scripts/lib/platform.nu',
        'log_info': 'scripts/lib/logging.nu',
        'create_error': 'scripts/lib/error-handling.nu',
        'track_test': 'scripts/testing/lib/test-utils.nu'
    };

    const filePath = functionFiles[word];
    if (filePath) {
        const fullPath = path.join(workspaceRoot, filePath);
        if (fs.existsSync(fullPath)) {
            return new vscode.Location(vscode.Uri.file(fullPath), new vscode.Position(0, 0));
        }
    }

    return undefined;
}

function updateDiagnostics(document: vscode.TextDocument, collection: vscode.DiagnosticCollection) {
    const diagnostics: vscode.Diagnostic[] = [];
    const text = document.getText();

    // Check for common nix-mox issues
    const lines = text.split('\n');
    lines.forEach((line, index) => {
        // Check for trailing whitespace
        if (line.endsWith(' ') || line.endsWith('\t')) {
            const diagnostic = new vscode.Diagnostic(
                new vscode.Range(index, line.trimEnd().length, index, line.length),
                'Trailing whitespace detected',
                vscode.DiagnosticSeverity.Information
            );
            diagnostic.code = 'nix-mox-trailing-whitespace';
            diagnostics.push(diagnostic);
        }

        // Check for dangerous patterns
        if (line.includes('rm -rf /') || line.includes('sudo rm -rf')) {
            const diagnostic = new vscode.Diagnostic(
                new vscode.Range(index, 0, index, line.length),
                'Dangerous command detected: this could delete system files',
                vscode.DiagnosticSeverity.Error
            );
            diagnostic.code = 'nix-mox-security';
            diagnostics.push(diagnostic);
        }

        // Check for missing error handling
        if (line.includes('try {') && !text.includes('catch {')) {
            const diagnostic = new vscode.Diagnostic(
                new vscode.Range(index, 0, index, line.length),
                'Try block without catch - consider adding error handling',
                vscode.DiagnosticSeverity.Warning
            );
            diagnostic.code = 'nix-mox-missing-error-handling';
            diagnostics.push(diagnostic);
        }

        // Check for hardcoded paths
        if (line.includes('/home/') || line.includes('/root/')) {
            const diagnostic = new vscode.Diagnostic(
                new vscode.Range(index, 0, index, line.length),
                'Hardcoded path detected - consider using environment variables',
                vscode.DiagnosticSeverity.Warning
            );
            diagnostic.code = 'nix-mox-hardcoded-path';
            diagnostics.push(diagnostic);
        }

        // Check for TODO comments
        const todoMatch = line.match(/#\s*TODO/i);
        if (todoMatch) {
            const diagnostic = new vscode.Diagnostic(
                new vscode.Range(index, todoMatch.index || 0, index, line.length),
                'TODO comment found',
                vscode.DiagnosticSeverity.Information
            );
            diagnostic.code = 'nix-mox-todo';
            diagnostics.push(diagnostic);
        }

        // Check for FIXME comments
        const fixmeMatch = line.match(/#\s*FIXME/i);
        if (fixmeMatch) {
            const diagnostic = new vscode.Diagnostic(
                new vscode.Range(index, fixmeMatch.index || 0, index, line.length),
                'FIXME comment found - needs attention',
                vscode.DiagnosticSeverity.Warning
            );
            diagnostic.code = 'nix-mox-fixme';
            diagnostics.push(diagnostic);
        }
    });

    collection.set(document.uri, diagnostics);
}

function getMetricsWebviewContent(metricsData: string): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nix-mox Metrics</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #1e1e1e; color: #cccccc; }
        .header { border-bottom: 1px solid #333; padding-bottom: 10px; margin-bottom: 20px; }
        .metrics-container { background: #252526; padding: 15px; border-radius: 4px; margin-bottom: 20px; }
        .metric { margin-bottom: 10px; font-family: 'Courier New', monospace; font-size: 12px; }
        .metric-name { color: #4FC1FF; }
        .metric-value { color: #CE9178; }
        .metric-help { color: #6A9955; font-style: italic; }
        .refresh-btn { background: #0e639c; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; }
        .refresh-btn:hover { background: #1177bb; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 nix-mox Performance Metrics</h1>
        <button class="refresh-btn" onclick="location.reload()">Refresh</button>
    </div>

    <div class="metrics-container">
        <h3>Current Metrics</h3>
        <pre class="metric">${metricsData.split('\n').map(line => {
            if (line.startsWith('# HELP')) {
                return `<div class="metric-help">${line}</div>`;
            } else if (line.startsWith('# TYPE')) {
                return `<div class="metric">${line}</div>`;
            } else if (line.trim() && !line.startsWith('#')) {
                const parts = line.split(' ');
                return `<div class="metric"><span class="metric-name">${parts[0]}</span> <span class="metric-value">${parts[1]}</span></div>`;
            }
            return line;
        }).join('')}</pre>
    </div>

    <div class="metrics-container">
        <h3>Quick Stats</h3>
        <p>📊 Real-time performance monitoring for nix-mox scripts</p>
        <p>🔍 Security validation and threat detection</p>
        <p>⚡ Error tracking and recovery suggestions</p>
        <p>📈 Test coverage and execution metrics</p>
    </div>
</body>
</html>`;
}

function showWelcomeMessage() {
    const config = vscode.workspace.getConfiguration('nix-mox');
    const showWelcome = config.get('showWelcome', true);

    if (showWelcome) {
        vscode.window.showInformationMessage(
            '🚀 nix-mox extension activated! Use Ctrl+F5 to run Nu scripts.',
            'Run Setup Wizard',
            'Don\'t show again'
        ).then(selection => {
            if (selection === 'Run Setup Wizard') {
                vscode.commands.executeCommand('nix-mox.setupWizard');
            } else if (selection === 'Don\'t show again') {
                config.update('showWelcome', false, vscode.ConfigurationTarget.Global);
            }
        });
    }
}

// Formatting Provider Implementation
function formatNushellDocument(document: vscode.TextDocument): vscode.TextEdit[] {
    const edits: vscode.TextEdit[] = [];
    const text = document.getText();
    const lines = text.split('\n');

    lines.forEach((line, index) => {
        const trimmedLine = line.trimEnd();
        if (trimmedLine !== line) {
            // Remove trailing whitespace
            edits.push(
                vscode.TextEdit.replace(
                    new vscode.Range(index, trimmedLine.length, index, line.length),
                    ''
                )
            );
        }

        // Normalize indentation (convert tabs to spaces)
        if (line.startsWith('\t')) {
            const spacesCount = line.match(/^\t+/)?.[0].length || 0;
            const newIndentation = '    '.repeat(spacesCount);
            const contentAfterTabs = line.replace(/^\t+/, '');
            edits.push(
                vscode.TextEdit.replace(
                    new vscode.Range(index, 0, index, line.length),
                    newIndentation + contentAfterTabs
                )
            );
        }
    });

    return edits;
}

// Code Actions Provider Implementation
function provideNushellCodeActions(
    document: vscode.TextDocument,
    range: vscode.Range,
    context: vscode.CodeActionContext
): vscode.CodeAction[] {
    const actions: vscode.CodeAction[] = [];

    // Add quick fixes for diagnostics
    context.diagnostics.forEach(diagnostic => {
        if (diagnostic.code === 'nix-mox-trailing-whitespace') {
            const action = new vscode.CodeAction(
                'Remove trailing whitespace',
                vscode.CodeActionKind.QuickFix
            );
            action.diagnostics = [diagnostic];
            action.edit = new vscode.WorkspaceEdit();
            action.edit.replace(
                document.uri,
                diagnostic.range,
                document.getText(diagnostic.range).trimEnd()
            );
            actions.push(action);
        }

        if (diagnostic.code === 'nix-mox-missing-error-handling') {
            const action = new vscode.CodeAction(
                'Add error handling',
                vscode.CodeActionKind.QuickFix
            );
            action.diagnostics = [diagnostic];
            action.edit = new vscode.WorkspaceEdit();

            // Find the end of the try block and add catch
            const tryLine = diagnostic.range.start.line;
            const text = document.getText();
            const lines = text.split('\n');

            // Simple implementation - find the closing brace of the try block
            let braceCount = 0;
            let catchLine = tryLine;
            for (let i = tryLine; i < lines.length; i++) {
                const line = lines[i];
                if (line.includes('{')) braceCount++;
                if (line.includes('}')) {
                    braceCount--;
                    if (braceCount === 0) {
                        catchLine = i;
                        break;
                    }
                }
            }

            const catchBlock = '\n} catch {|err|\n    print $"Error: $err"\n}';
            action.edit.insert(
                document.uri,
                new vscode.Position(catchLine + 1, 0),
                catchBlock
            );
            actions.push(action);
        }
    });

    return actions;
}

export function deactivate() {
    console.log('nix-mox extension deactivated');
}
