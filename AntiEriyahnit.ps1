$foundTasks = @()

# Get all tasks in all folders (including root \)
$allTasks = Get-ScheduledTask -ErrorAction SilentlyContinue

foreach ($task in $allTasks) {
    foreach ($action in $task.Actions) {
        $exe = $action.Execute
        if ($exe -like "*powershell*" -or $exe -like "*pwsh*") {
            $foundTasks += $task
            break
        }
    }
}

if ($foundTasks.Count -eq 0) {
    Write-Host "No Eriyahnit tasks found." -ForegroundColor Yellow
} else {
    foreach ($t in $foundTasks) {
        $taskName  = $t.TaskName
        $taskPath = $t.TaskPath

        Write-Host "Processing: $taskPath$taskName" -ForegroundColor Cyan

        # Stop if currently running
        try {
            Stop-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction SilentlyContinue
        } catch {}

        # Delete
        try {
            Unregister-ScheduledTask -TaskPath $taskPath -TaskName $taskName -Confirm:$false -ErrorAction Stop
            Write-Host "$taskName - Eriyahnit deleted." -ForegroundColor Green
        } catch {
            # If permission error, force delete with schtasks.exe
            $fullPath = "$taskPath$taskName" -replace "\\\\", "\"
            $result = schtasks /Delete /TN "$fullPath" /F 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$taskName - Eriyahnit deleted. (forced)" -ForegroundColor Green
            } else {
                Write-Host "$taskName - Could not be deleted: $result" -ForegroundColor Red
            }
        }
    }
}