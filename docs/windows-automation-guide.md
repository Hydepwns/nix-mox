# Automated Steam + Rust Installation on Windows (NuShell)

This guide details how to automate the installation of Steam and prompt for Rust (by Facepunch Studios, appid 252490) on a Windows system using NuShell and the provided scripts from this repository.

This process allows you to prepare a Windows image that will automatically install Steam and set it up for Rust installation on first boot, making it easier to flash or deploy to new hardware or VMs.

---

### Prerequisites

* A Windows system (VM or bare metal).
* [Nushell](https://www.nushell.sh/) installed on the Windows system.

### 1. Obtain Automation Scripts

The necessary scripts (`install-steam-rust.nu`, `run-steam-rust.bat`, `InstallSteamRust.xml`) are bundled in a Nix package.
On your Nix-enabled machine (e.g., your Linux host), run:

```bash
nix build .#windows-automation-assets-sources
```

This will create a `result` directory (e.g., `./result/`) containing the three script files:

* `install-steam-rust.nu`
* `run-steam-rust.bat`
* `InstallSteamRust.xml`

Copy these three files from the `result/` directory to a single directory on your Windows system, for example, `C:\nix-mox-scripts\`. All three files should be in the same directory.

### 2. Install NuShell on Windows

If you don't have NuShell installed on your Windows system:

* **Recommended (using Chocolatey):**
    Open PowerShell as Administrator and run:

    ```powershell
    # Install Chocolatey if you don't have it
    Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Install Nushell
    choco install nushell -y
    ```

    This typically installs `nu.exe` and adds it to your system PATH. Verify this by opening a new Command Prompt or PowerShell window and typing `nu --version`.
* **Manual/Other Methods:** Alternatively, download NuShell from the [official Nushell releases page](https://github.com/nushell/nushell/releases), install it, and ensure `nu.exe` is in your system's PATH.

### 3. Configure and Run Automation

The `run-steam-rust.bat` script executes `install-steam-rust.nu`. The `.bat` script expects `install-steam-rust.nu` to be in the same directory.

* **Important: Configure `run-steam-rust.bat`**
    The provided `run-steam-rust.bat` script, by default, tries to run Nushell from `C:\Program Files\Nu\bin\nu.exe`.
  * If you installed Nushell via Chocolatey or to a different location *and `nu.exe` is in your system PATH*, you should **edit `run-steam-rust.bat`**. Change the line:

        ```batch
        "C:\Program Files\Nu\bin\nu.exe" "%~dp0install-steam-rust.nu" %*
        ```

        to:

        ```batch
        nu "%~dp0install-steam-rust.nu" %*
        ```

        This modification allows the script to use the `nu.exe` found in your system's PATH.
  * Alternatively, if `nu.exe` is not in your PATH but installed at a known location, you can update the hardcoded path in `run-steam-rust.bat` to that specific location.

### 4. Register the Scheduled Task

The `InstallSteamRust.xml` file is a Windows Task Scheduler definition designed to run `run-steam-rust.bat` at user logon.
To use it:

1. Ensure `run-steam-rust.bat` is configured correctly (as per the point above) and located in the same directory as `install-steam-rust.nu` and `InstallSteamRust.xml`. For example, all in `C:\nix-mox-scripts\`.
2. Open Task Scheduler on Windows.
3. In the "Actions" pane, click "Import Task...".
4. Browse to and select the `InstallSteamRust.xml` file you copied to your Windows machine.
5. The "Create Task" window will appear with settings pre-filled from the XML file. Go to the "Actions" tab.
6. Select the existing action (it should refer to `run-steam-rust.bat`) and click "Edit...".
7. In the "Program/script" field, ensure it correctly points to the **full path** of your `run-steam-rust.bat` file. For example, if you placed the scripts in `C:\nix-mox-scripts\`, this should be `C:\nix-mox-scripts\run-steam-rust.bat`. Adjust if necessary.
8. Click OK to save the action, and OK again to save the task.

### 5. First Logon Behavior

On the next user logon, an automated process will:

* Trigger the scheduled task (`run-steam-rust.bat`).
* The batch script will execute the NuShell script (`install-steam-rust.nu`).
* The NuShell script will download and silently install Steam.
* Steam will be started once to initialize (you may see the login prompt).
* The script will then inform you that Steam is installed and remind you to log in and install Rust (Facepunch, appid 252490) via the Steam client.

---

#### Optional: Remove the Task After First Run

To have the scheduled task delete itself after successfully running once, you can add the following towards the end of your `install-steam-rust.nu` script, before the final `exit` command:

```nu
log_info "Attempting to delete self-destructing scheduled task: InstallSteamRust"
try {
    run-external "schtasks.exe" "/Delete" "/TN" "InstallSteamRust" "/F"
    log_success "Scheduled task 'InstallSteamRust' deletion attempted."
} catch {
    log_warn "Could not delete scheduled task 'InstallSteamRust'. It might not exist or permissions are insufficient."
}
```

#### Optional: Full Headless Rust Install

For a fully automated Rust install (no user interaction), you can use SteamCMD and provide Steam credentials. See the comments in [`../scripts/windows/install-steam-rust.nu`](../scripts/windows/install-steam-rust.nu) for a template, but be aware of the security risks of storing credentials in scripts.
