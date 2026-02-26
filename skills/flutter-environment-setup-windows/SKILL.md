---
name: "flutter-environment-setup-windows"
description: "Set up a Windows environment for Flutter development"
metadata:
  urls:
    - "https://docs.flutter.dev/install"
    - "https://docs.flutter.dev/install/add-to-path"
    - "https://docs.flutter.dev/install/manual"
    - "https://docs.flutter.dev/install/troubleshoot"
    - "https://docs.flutter.dev/platform-integration/windows/building"
    - "https://docs.flutter.dev/platform-integration/windows/setup"
    - "https://docs.flutter.dev/tools/vs-code"
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Thu, 26 Feb 2026 23:17:09 GMT"

---
# Flutter Windows Setup and Troubleshooting

## Goal
Configures a Windows environment to support Flutter development by injecting the Flutter SDK `bin` directory into the user's `PATH` environment variable. Validates the configuration using CLI tools and automatically resolves common execution policy, path resolution, and permission errors associated with the Windows Flutter toolchain.

## Instructions

1. **Determine SDK Location**
   **STOP AND ASK THE USER:** "Please provide the absolute path to the directory where you extracted the Flutter SDK (e.g., `C:\src\flutter` or `%USERPROFILE%\develop\flutter`)."

2. **Validate Target Directory**
   Evaluate the user-provided path. If the path targets a protected system directory requiring elevated privileges (e.g., `C:\Program Files\`), instruct the user to relocate the SDK to a user-writable directory before proceeding.

3. **Inject Flutter into User PATH**
   Execute the following PowerShell script to append the Flutter `bin` directory to the User `Path` environment variable safely. Replace `<USER_PROVIDED_PATH>` with the validated path from Step 1.

   ```powershell
   $flutterBin = "<USER_PROVIDED_PATH>\bin"
   $oldPath = [Environment]::GetEnvironmentVariable("Path", "User")

   if ($oldPath -notmatch [regex]::Escape($flutterBin)) {
       $newPath = $oldPath + ";" + $flutterBin
       [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
       Write-Host "Successfully added $flutterBin to User PATH."
   } else {
       Write-Host "Flutter bin is already present in User PATH."
   }
   ```

4. **Apply Environment Changes**
   Instruct the user to close and reopen all active command prompts, PowerShell sessions, and IDEs to inherit the updated `PATH` variables.

5. **Validate Setup**
   Execute the following commands in a new terminal session to verify the toolchain:
   ```powershell
   flutter --version
   dart --version
   ```

6. **Decision Logic: Troubleshooting Validation Failures**
   If Step 5 fails, apply the following decision tree based on the specific error output:

   *   **Condition A:** Output contains `'flutter' is not recognized as an internal or external command`.
       *   *Action:* The `PATH` variable did not update correctly or the terminal session was not restarted. Re-run Step 3 and explicitly verify the registry value.
   *   **Condition B:** Output contains `Invoke-Expression : You cannot call a method on a null-valued expression`.
       *   *Action:* The `SystemRoot` variable is missing or PowerShell execution policies are blocking the script. Execute the following remediation script as Administrator:
           ```powershell
           # Verify and set SystemRoot
           if (-not $env:SystemRoot) {
               [Environment]::SetEnvironmentVariable("SystemRoot", "C:\Windows", "Machine")
               $env:SystemRoot = "C:\Windows"
           }
           # Adjust Execution Policy for the current user
           Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
           ```
   *   **Condition C:** Output contains `The Flutter SDK is installed in a protected folder and may not function correctly`.
       *   *Action:* The SDK is in an elevated directory. **STOP AND ASK THE USER:** "The Flutter SDK is in a protected folder. Please move it to a user-writable location like `C:\src\flutter`, then provide the new path."

## Constraints
*   Do not modify the Machine/System `PATH` variable; strictly target the `User` scope to avoid requiring persistent elevated privileges.
*   Do not proceed with `PATH` injection if the user provides a path containing `C:\Program Files\` or `C:\Windows\`.
*   Always enforce a terminal restart (or environment refresh) between modifying the `PATH` and validating the `flutter` command.
*   Assume the user is operating on a standard Windows 10/11 environment using PowerShell as the primary shell interface.
