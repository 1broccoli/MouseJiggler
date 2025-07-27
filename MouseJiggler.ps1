# MouseJiggler.ps1
# ----------------------------------------------------------
# How to run this script:
#
# 1. Open PowerShell (not ISE or VSCode).
#
# 2. Temporarily allow script execution for this session:
#    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#
# 3. Start the script in STA mode (required for UI):
#    powershell -ExecutionPolicy Bypass -STA -File "C:\****\MouseJiggler.ps1"
#
#    (Replace the path above **** if your script is saved elsewhere.)
#
# 4. To stop the script, close the UI window or press Ctrl+C in the PowerShell window.
# ----------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# Default settings
$global:idleSeconds = 300  # 5 minutes (default)
$jiggleRadius = 40
$jiggleSteps = 36

# Helper function to format seconds as Xm Ys
function Format-Time($seconds) {
    $totalSeconds = [int][math]::Floor($seconds)
    return "$totalSeconds s"
}

# Function to send Shift key press
function Send-ShiftKey {
    Add-Type -TypeDefinition @'
    using System;
    using System.Runtime.InteropServices;
    public class Keyboard {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    }
'@
    # 0x10 is the virtual-key code for Shift
    [Keyboard]::keybd_event(0x10,0,0,[UIntPtr]::Zero)
    Start-Sleep -Milliseconds 50
    [Keyboard]::keybd_event(0x10,0,2,[UIntPtr]::Zero)
}

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Mouse Jiggler 1.0"
$form.Size = New-Object System.Drawing.Size(320,220)
$form.TopMost = $true
$form.Opacity = 1.0

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10, 0)
$titleLabel.Size = New-Object System.Drawing.Size(290, 20)
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$titleLabel.Text = "Commence to Jiggling!"
$form.Controls.Add($titleLabel)

# Status bar: Idle time, Triggers, Uptime (all on one line)
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 25)
$statusLabel.Size = New-Object System.Drawing.Size(300, 20)
$statusLabel.Text = "Idle time: 0s   |   Triggers: 0   |   Uptime: 0s"
$form.Controls.Add($statusLabel)
$form.Controls.Add($statusLabel)

# Button style helper
function Set-Button-Highlight($btn1, $btn2, $btn3, $active) {
    $btn1.FlatStyle = 'Standard'
    $btn2.FlatStyle = 'Standard'
    $btn3.FlatStyle = 'Standard'
    $btn1.FlatAppearance.BorderSize = 1
    $btn2.FlatAppearance.BorderSize = 1
    $btn3.FlatAppearance.BorderSize = 1
    $btn1.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
    $btn2.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
    $btn3.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray

$btn30s = New-Object System.Windows.Forms.Button
# 3 Minutes Button
    $active.FlatAppearance.BorderSize = 3
    $active.FlatAppearance.BorderColor = [System.Drawing.Color]::LimeGreen
}

# 30 Seconds Button
$btn30s = New-Object System.Windows.Forms.Button
$btn30s.Text = "30 Seconds"
$btn30s.Location = New-Object System.Drawing.Point(10,70)
$btn30s.Size = New-Object System.Drawing.Size(90,30)
$form.Controls.Add($btn30s)

# 3 Minutes Button
$btn3m = New-Object System.Windows.Forms.Button
$btn3m.Text = "3 Minutes"
$btn3m.Location = New-Object System.Drawing.Point(110,70)
$btn3m.Size = New-Object System.Drawing.Size(90,30)
$form.Controls.Add($btn3m)

# 5 Minutes Button
$btn5m = New-Object System.Windows.Forms.Button
$btn5m.Text = "5 Minutes"
$btn5m.Location = New-Object System.Drawing.Point(210,70)
$btn5m.Size = New-Object System.Drawing.Size(90,30)
$form.Controls.Add($btn5m)

# Button click events to set idle time and highlight
$btn30s.Add_Click({
    $global:idleSeconds = 30
    Set-Button-Highlight $btn30s $btn3m $btn5m $btn30s
})
$btn3m.Add_Click({
    $global:idleSeconds = 180
    Set-Button-Highlight $btn30s $btn3m $btn5m $btn3m
})
$btn5m.Add_Click({
    $global:idleSeconds = 300
    Set-Button-Highlight $btn30s $btn3m $btn5m $btn5m
})

# Set default highlight to 5 Minutes at startup
Set-Button-Highlight $btn30s $btn3m $btn5m $btn5m

# Pattern selection ComboBox (below idle time buttons)
$patternLabel = New-Object System.Windows.Forms.Label
$patternLabel.Location = New-Object System.Drawing.Point(10, 110)
$patternLabel.Size = New-Object System.Drawing.Size(100, 20)
$patternLabel.Text = "Pattern:"
$form.Controls.Add($patternLabel)

$patternBox = New-Object System.Windows.Forms.ComboBox
$patternBox.Location = New-Object System.Drawing.Point(110, 110)
$patternBox.Size = New-Object System.Drawing.Size(100, 30)
$patternBox.DropDownStyle = 'DropDownList'
$patternBox.Items.AddRange(@("Circle","Wiggle","Heart"))
$patternBox.SelectedIndex = 0
$form.Controls.Add($patternBox)

# Transparency ComboBox and label (below radio buttons)
$transLabel = New-Object System.Windows.Forms.Label
$transLabel.Location = New-Object System.Drawing.Point(10, 140)
$transLabel.Size = New-Object System.Drawing.Size(100, 20)
$transLabel.Text = "Transparency:"
$form.Controls.Add($transLabel)

$transBox = New-Object System.Windows.Forms.ComboBox
$transBox.Location = New-Object System.Drawing.Point(110, 140)
$transBox.Size = New-Object System.Drawing.Size(100, 30)
$transBox.DropDownStyle = 'DropDownList'
$transBox.Items.AddRange(@("100%","90%","80%","70%","60%","50%"))
$transBox.SelectedIndex = 0
$form.Controls.Add($transBox)

# Transparency change event
$transBox.Add_SelectedIndexChanged({
    $percent = $transBox.SelectedItem.Replace('%','')
    $form.Opacity = [double]$percent / 100
})

# Idle detection logic
$global:lastMousePos = [System.Windows.Forms.Cursor]::Position
$global:idleTime = 0
$global:triggerCount = 0
$global:startTime = Get-Date

function Jiggle-Mouse {
    param($pattern)
    $center = [System.Windows.Forms.Cursor]::Position
    switch ($pattern) {
        'Circle' {
            for ($i=0; $i -lt $jiggleSteps; $i++) {
                $angle = 2 * [Math]::PI * $i / $jiggleSteps
                $x = [int]($center.X + $jiggleRadius * [Math]::Cos($angle))
                $y = [int]($center.Y + $jiggleRadius * [Math]::Sin($angle))
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
                Start-Sleep -Milliseconds 10
            }
        }
        'Cross' {
            for ($i = -$jiggleRadius; $i -le $jiggleRadius; $i = [int]($i + 2)) {
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($center.X + $i, $center.Y)
                Start-Sleep -Milliseconds 10
            }
            for ($i = -$jiggleRadius; $i -le $jiggleRadius; $i = [int]($i + 2)) {
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($center.X, $center.Y + $i)
                Start-Sleep -Milliseconds 10
            }
        }
        'X' {
            for ($i = -$jiggleRadius; $i -le $jiggleRadius; $i = [int]($i + 2)) {
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($center.X + $i, $center.Y + $i)
                Start-Sleep -Milliseconds 10
            }
            for ($i = -$jiggleRadius; $i -le $jiggleRadius; $i = [int]($i + 2)) {
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($center.X + $i, $center.Y - $i)
                Start-Sleep -Milliseconds 10
            }
        }
        'Diamond' {
            for ($i = 0; $i -le $jiggleRadius; $i = [int]($i + 2)) {
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($center.X, [int]($center.Y - $i))
                Start-Sleep -Milliseconds 10
            }
            for ($i = 0; $i -le $jiggleRadius; $i = [int]($i + 2)) {
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point([int]($center.X + $i), $center.Y)
                Start-Sleep -Milliseconds 10
            }
            for ($i = 0; $i -le $jiggleRadius; $i = [int]($i + 2)) {
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($center.X, [int]($center.Y + $i))
                Start-Sleep -Milliseconds 10
            }
            for ($i = 0; $i -le $jiggleRadius; $i = [int]($i + 2)) {
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point([int]($center.X - $i), $center.Y)
                Start-Sleep -Milliseconds 10
            }
        }
        'Wiggle' {
            for ($i=0; $i -lt 2*$jiggleSteps; $i++) {
                $x = [int]($center.X + $jiggleRadius * [Math]::Sin($i/2.0))
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $center.Y)
                Start-Sleep -Milliseconds 10
            }
        }
        'Heart' {
            for ($i=0; $i -lt $jiggleSteps; $i++) {
                $t = 2 * [Math]::PI * $i / $jiggleSteps
                $x = [int]($center.X + $jiggleRadius * 16 * [Math]::Pow([Math]::Sin($t),3)/17)
                $y = [int]($center.Y - $jiggleRadius * (13 * [Math]::Cos($t) - 5 * [Math]::Cos(2*$t) - 2 * [Math]::Cos(3*$t) - [Math]::Cos(4*$t))/17)
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
                Start-Sleep -Milliseconds 10
            }
        }
        default {
            # fallback to circle
            for ($i=0; $i -lt $jiggleSteps; $i++) {
                $angle = 2 * [Math]::PI * $i / $jiggleSteps
                $x = [int]($center.X + $jiggleRadius * [Math]::Cos($angle))
                $y = [int]($center.Y + $jiggleRadius * [Math]::Sin($angle))
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
                Start-Sleep -Milliseconds 10
            }
        }
    }
    [System.Windows.Forms.Cursor]::Position = $center
}
function Jiggle-Mouse {
    $pattern = $patternBox.SelectedItem
    $center = [System.Windows.Forms.Cursor]::Position
    switch ($pattern) {
        'Circle' {
            for ($i=0; $i -lt $jiggleSteps; $i++) {
                $angle = 2 * [Math]::PI * $i / $jiggleSteps
                $x = [int]($center.X + $jiggleRadius * [Math]::Cos($angle))
                $y = [int]($center.Y + $jiggleRadius * [Math]::Sin($angle))
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
                Start-Sleep -Milliseconds 10
            }
        }
        'Wiggle' {
            for ($i=0; $i -lt 2*$jiggleSteps; $i++) {
                $x = [int]($center.X + $jiggleRadius * [Math]::Sin($i/2.0))
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $center.Y)
                Start-Sleep -Milliseconds 10
            }
        }
        'Heart' {
            for ($i=0; $i -lt $jiggleSteps; $i++) {
                $t = 2 * [Math]::PI * $i / $jiggleSteps
                $x = [int]($center.X + $jiggleRadius * 16 * [Math]::Pow([Math]::Sin($t),3)/17)
                $y = [int]($center.Y - $jiggleRadius * (13 * [Math]::Cos($t) - 5 * [Math]::Cos(2*$t) - 2 * [Math]::Cos(3*$t) - [Math]::Cos(4*$t))/17)
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
                Start-Sleep -Milliseconds 10
            }
        }
        default {
            # fallback to circle
            for ($i=0; $i -lt $jiggleSteps; $i++) {
                $angle = 2 * [Math]::PI * $i / $jiggleSteps
                $x = [int]($center.X + $jiggleRadius * [Math]::Cos($angle))
                $y = [int]($center.Y + $jiggleRadius * [Math]::Sin($angle))
                [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
                Start-Sleep -Milliseconds 10
            }
        }
    }
    [System.Windows.Forms.Cursor]::Position = $center
}


$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    $currentPos = [System.Windows.Forms.Cursor]::Position
    if ($currentPos -eq $global:lastMousePos) {
        $global:idleTime += 0.1
    } else {
        $global:idleTime = 0
    }
    $statusLabel.Text = "Idle time: " + (Format-Time $global:idleTime) + "   |   Triggers: $($global:triggerCount)   |   Uptime: " + (Format-Time ((Get-Date) - $global:startTime).TotalSeconds)
    # Use integer comparison to avoid floating point rounding errors
    if ([int][math]::Floor($global:idleTime) -ge [int][math]::Floor([double]$global:idleSeconds)) {
        Jiggle-Mouse
        Send-ShiftKey
        $global:idleTime = 0
        $global:triggerCount++
    }
    $global:lastMousePos = $currentPos
})
$timer.Start()

[void]$form.ShowDialog()