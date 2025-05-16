# Load required assemblies for GUI
Add-Type -AssemblyName PresentationFramework

# Load XAML UI from file
$xamlPath = ".\ADUserManagement.xaml"
[xml]$xaml = Get-Content $xamlPath
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

if ($window -eq $null) {
    Write-Error "Failed to load XAML. Please check the file path and ensure the XAML is valid."
    exit
}

# Assign UI elements to variables
$searchButton = $window.FindName('SearchButton')
$userNameTextBox = $window.FindName('UserNameTextBox')
$resultsDataGrid = $window.FindName('ResultsDataGrid')

# Find context menu items for adding event handlers
$unlockMenuItem = $window.FindName('UnlockAccountMenuItem')
$enableMenuItem = $window.FindName('EnableAccountMenuItem')
$disableMenuItem = $window.FindName('DisableAccountMenuItem')
$resetPwMenuItem = $window.FindName('ResetPasswordMenuItem')

if (-not $searchButton -or -not $userNameTextBox -or -not $resultsDataGrid -or -not $unlockMenuItem -or -not $enableMenuItem -or -not $disableMenuItem -or -not $resetPwMenuItem) {
    Write-Error "One or more UI elements could not be found. Please check the XAML file for missing or incorrect element names."
    exit
}

# Add an informational label to instruct users about right-click functionality
$instructionLabel = New-Object System.Windows.Controls.Label
$instructionLabel.Content = "Tip: Right-click on a user's name in the list to manage their account."
$instructionLabel.Margin = [System.Windows.Thickness]::new(10)
$instructionLabel.HorizontalAlignment = 'Center'

# Add the instruction label to the window (assuming $window.Content is a container that supports adding children)
$window.Content.Children.Insert(0, $instructionLabel)

# Event handler for search button click
$searchButton.Add_Click({
    $userName = $userNameTextBox.Text
    if ([string]::IsNullOrWhiteSpace($userName)) {
        [System.Windows.MessageBox]::Show("Please enter a user name.", "Input Required")
        return
    }

    try {
        # Set cursor to wait
        $window.Cursor = [System.Windows.Input.Cursors]::Wait

        # Perform the AD search
        Import-Module ActiveDirectory -ErrorAction Stop
        $results = @(Get-ADUser -Filter "Name -like '*$userName*'" -Property Enabled, LockedOut, PasswordExpired, PasswordLastSet, DisplayName, EmailAddress, Department |
                    Select-Object Name, SamAccountName, Enabled, LockedOut, PasswordExpired, @{Name="PasswordExpires"; Expression={($_.PasswordLastSet).AddDays(90)}}, DisplayName, EmailAddress, Department)

        # Check if results are empty
        if ($results.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No users found matching the name '$userName'.", "No Results")
        } else {
            # Display results in DataGrid
            $resultsDataGrid.ItemsSource = $results
        }

    } catch {
        [System.Windows.MessageBox]::Show("Failed to search AD: $($_.Exception.Message)", "Error")
    } finally {
        # Set cursor back to default
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

# Utility function to handle AD action on a selected user
function Invoke-ADUserAction {
    param (
        [string]$action,
        [string]$samAccountName
    )
    try {
        switch ($action) {
            'Unlock' { Unlock-ADAccount -Identity $samAccountName }
            'Enable' { Enable-ADAccount -Identity $samAccountName }
            'Disable' { Disable-ADAccount -Identity $samAccountName }
            'ResetPassword' {
                # Prompt for new password securely
                $securePassword = Read-Host "Enter new password" -AsSecureString
                Set-ADAccountPassword -Identity $samAccountName -NewPassword $securePassword -Reset -PassThru | Set-ADUser -ChangePasswordAtLogon $true
            }
        }
        [System.Windows.MessageBox]::Show("The action '$action' completed successfully.", "Success")
    } catch {
        [System.Windows.MessageBox]::Show("Failed to $action user: $($_.Exception.Message)", "Error")
    }
}

# Define event handlers for context menu items
$unlockMenuItem.Add_Click({
    $selectedUser = $resultsDataGrid.SelectedItem
    if ($selectedUser -eq $null) {
        [System.Windows.MessageBox]::Show("Please select a user from the list.", "Selection Required")
        return
    }
    Invoke-ADUserAction -action 'Unlock' -samAccountName $selectedUser.SamAccountName
})

$enableMenuItem.Add_Click({
    $selectedUser = $resultsDataGrid.SelectedItem
    if ($selectedUser -eq $null) {
        [System.Windows.MessageBox]::Show("Please select a user from the list.", "Selection Required")
        return
    }
    Invoke-ADUserAction -action 'Enable' -samAccountName $selectedUser.SamAccountName
})

$disableMenuItem.Add_Click({
    $selectedUser = $resultsDataGrid.SelectedItem
    if ($selectedUser -eq $null) {
        [System.Windows.MessageBox]::Show("Please select a user from the list.", "Selection Required")
        return
    }
    Invoke-ADUserAction -action 'Disable' -samAccountName $selectedUser.SamAccountName
})

$resetPwMenuItem.Add_Click({
    $selectedUser = $resultsDataGrid.SelectedItem
    if ($selectedUser -eq $null) {
        [System.Windows.MessageBox]::Show("Please select a user from the list.", "Selection Required")
        return
    }
    Invoke-ADUserAction -action 'ResetPassword' -samAccountName $selectedUser.SamAccountName
})

# Show the window
$window.ShowDialog() | Out-Null
