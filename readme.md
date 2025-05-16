# AD User Management GUI Tool

_"We don't need no stinking badges!"_

![PowerShell](https://img.shields.io/badge/language-PowerShell-5391FE?logo=powershell&logoColor=white)

![PowerShell Lint](https://github.com/jason-adams-eng/ADUserGUI/actions/workflows/lint.yml/badge.svg)

![Markdown Lint](https://github.com/jason-adams-eng/ADUserGUI/actions/workflows/mdlint.yml/badge.svg)

This PowerShell-based GUI tool provides an interface for searching and managing Active Directory user accounts. It uses a XAML-based UI for a user-friendly experience and integrates with the ActiveDirectory module to perform actions like:

- Searching for users by name
- Unlocking user accounts
- Enabling/disabling accounts
- Forcing password resets with secure prompts

## Files

- `ADUserManagement.ps1` — Main PowerShell script that drives the GUI.
- `ADUserManagement.xaml` — XAML UI definition file.

## Requirements

- Windows PowerShell
- ActiveDirectory module (comes with RSAT tools)
- GUI-capable system (WPF support)
- Proper domain connectivity and permissions

## Notes

- Script requires administrative privileges and domain permissions.
- Password reset functionality prompts securely for input and flags user to reset at next login.

## Getting Started

1. Ensure RSAT and ActiveDirectory module are installed.
2. Clone this repository or copy the files to a working directory.
3. Launch PowerShell and run the script:

   ```powershell
   .\ADUserManagement.ps1
   ```
