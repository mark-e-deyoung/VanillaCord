# VanillaCord Minecraft Compatibility Report

No generated compatibility run has been committed yet.

Generate this file with:

```powershell
$env:GITHUB_TOKEN = (gh auth token).Trim()
.\scripts\Invoke-CompatibilityProbe.ps1 -UseDocker
```

GitHub Actions also uploads this path as the `minecraft-compatibility-report`
artifact and appends the report to the workflow summary.

