#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate speckit plan.md and tasks.md for all OSAI spec directories.
#>

[CmdletBinding()]
param(
    [string[]]$SpecFilter,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repoRoot = "C:\workspace\code\osai"
$specsDir = Join-Path $repoRoot "specs"
$commonScript = Join-Path $repoRoot ".specify/scripts/powershell/common.ps1"
if (Test-Path $commonScript) { . $commonScript }

$techStack = @{}
function Add-Stack($num, $lang, $deps, $storage, $test, $platform) {
    $techStack[$num] = @{ lang = $lang; deps = $deps; storage = $storage; test = $test; platform = $platform }
}

Add-Stack "000" "Markdown" "N/A" "N/A" "Manual review" "docs"
Add-Stack "001" "TypeScript" "@osai/protocol SDK" "N/A" "vitest + json-schema" "library"
Add-Stack "002" "Rust + TypeScript" "rusqlite, refinery, umzug" "SQLite (rusqlite)" "cargo test + vitest" "library"
Add-Stack "003" "TypeScript + Rust" "pnpm, Tauri, cargo, sentry" "N/A" "vitest + cargo test" "infrastructure"
Add-Stack "004" "TypeScript" "protobuf or zod for schema" "N/A" "vitest" "library"
Add-Stack "005" "TypeScript (Node.js)" "commander, @osai/protocol" "@osai/storage" "vitest" "CLI"
Add-Stack "006" "TypeScript + Rust" "chrome.runtime, native messaging host" "N/A" "vitest + manual" "browser extension"
Add-Stack "007" "TypeScript" "vscode API, @osai/protocol" "N/A" "vitest" "VS Code extension"
Add-Stack "008" "Rust" "notify crate" "N/A" "cargo test" "Rust crate (in-process)"
Add-Stack "009" "Rust" "platform-specific APIs" "N/A" "cargo test" "Rust crate (in-process)"
Add-Stack "010" "Rust + TypeScript (React)" "Tauri, tray crates" "N/A" "cargo test + vitest" "Tauri app (tray)"
Add-Stack "011" "TypeScript (Node.js)" "transformers.js, @osai/storage" "@osai/storage" "vitest" "sidecar service"
Add-Stack "012" "TypeScript (Node.js)" "compromise NLP" "@osai/storage" "vitest" "sidecar service"
Add-Stack "013" "TypeScript (Node.js)" "keyword dictionaries, ML classifier" "@osai/storage" "vitest" "sidecar service"
Add-Stack "014" "TypeScript (Node.js)" "graph library (e.g., graphlib)" "@osai/storage" "vitest" "sidecar service"
Add-Stack "015" "TypeScript (Node.js)" "clustering algorithms" "@osai/storage" "vitest" "sidecar service"
Add-Stack "016" "TypeScript (Node.js)" "activity analysis" "@osai/storage" "vitest" "sidecar service"
Add-Stack "017" "TypeScript (Node.js)" "embeddings, graph traversal" "@osai/storage" "vitest" "sidecar service"
Add-Stack "018" "TypeScript (React)" "React, Tailwind, @osai/ui" "@osai/storage" "vitest + @testing-library/react" "webview component"
Add-Stack "019" "TypeScript (React)" "React, Tailwind, @osai/ui" "@osai/storage" "vitest + @testing-library/react" "webview component"
Add-Stack "020" "TypeScript (React)" "React, D3-force, @osai/ui" "@osai/storage" "vitest + @testing-library/react" "webview component"
Add-Stack "021" "TypeScript (React)" "React, Tailwind, @osai/ui, streaming" "@osai/storage/chats" "vitest + @testing-library/react" "webview component"
Add-Stack "022" "TypeScript (React)" "React, Tailwind, @osai/ui" "@osai/storage/chats" "vitest + @testing-library/react" "webview component"
Add-Stack "023" "TypeScript (React)" "React, Tailwind, @osai/ui" "@osai/storage (event log)" "vitest + @testing-library/react" "webview component"
Add-Stack "024" "TypeScript (React)" "React, Tailwind, @osai/ui" "@osai/storage" "vitest + @testing-library/react" "webview component"
Add-Stack "025" "TypeScript (Node.js)" "@modelcontextprotocol/sdk" "@osai/storage" "vitest" "sidecar service"
Add-Stack "026" "TypeScript (Node.js)" "LLM provider (spec 062), @osai/knowledge" "@osai/storage" "vitest" "agent (sidecar)"
Add-Stack "027" "TypeScript (Node.js)" "LLM provider (spec 062), @osai/knowledge" "@osai/storage" "vitest" "agent (sidecar)"
Add-Stack "028" "TypeScript (Node.js)" "LLM provider (spec 062), web search API" "@osai/storage" "vitest" "agent (sidecar)"
Add-Stack "029" "TypeScript (Node.js)" "LLM provider (spec 062), recommendation engine" "@osai/storage" "vitest" "agent (sidecar)"
Add-Stack "030" "TypeScript (Node.js)" "LLM provider (spec 062), scheduler, event-goal matcher" "@osai/storage" "vitest" "agent (sidecar)"
Add-Stack "031" "TypeScript (Node.js)" "cron scheduler, agent runtime" "@osai/storage" "vitest" "agent infrastructure"
Add-Stack "032" "TypeScript (Node.js)" "sandboxing, permission system" "@osai/storage" "vitest" "agent infrastructure"
Add-Stack "033" "TypeScript (Node.js)" "marketplace API, package manager" "@osai/storage" "vitest" "agent infrastructure"
Add-Stack "034" "TypeScript (Node.js)" "CRDT library, sync protocol" "@osai/storage" "vitest" "sidecar service"
Add-Stack "035" "TypeScript (Node.js)" "WebSocket, sync relay" "Cloud DB" "vitest" "cloud service"
Add-Stack "036" "TypeScript (Node.js)" "cloud storage SDK (S3/R2)" "Cloud storage" "vitest" "cloud service"
Add-Stack "037" "TypeScript (Node.js)" "auth library (NextAuth, Clerk)" "Cloud DB" "vitest" "cloud service"
Add-Stack "038" "TypeScript (React)" "Next.js, Tailwind" "Cloud API" "vitest + Playwright" "web app"
Add-Stack "039" "TypeScript (Node.js)" "stripe, billing system" "Cloud DB" "vitest" "cloud service"
Add-Stack "040" "TypeScript (Node.js)" "crypto library (libsodium)" "Encrypted" "vitest" "library"
Add-Stack "041" "Python" "aiohttp, pydantic" "SDK (no local)" "pytest" "SDK"
Add-Stack "042" "Rust" "tokio, serde" "SDK (no local)" "cargo test" "SDK"
Add-Stack "043" "Go" "net/http, protobuf" "SDK (no local)" "go test" "SDK"
Add-Stack "044" "TypeScript (Node.js)" "VLC/mpv/Plex/Jellyfin/Spotify APIs" "N/A" "vitest" "connector (sidecar)"
Add-Stack "045" "TypeScript (Node.js)" "pdf.js, OS window APIs" "N/A" "vitest" "connector (sidecar)"
Add-Stack "046" "TypeScript (Node.js)" "OAuth, GitHub/Slack/Notion/Linear/Google APIs" "N/A" "vitest" "connector (sidecar)"
Add-Stack "047" "TypeScript (React Native)" "React Native, cloud API" "Cloud API + local cache" "vitest + Detox" "mobile app"
Add-Stack "048" "Markdown / TypeScript" "N/A" "N/A" "Manual review" "docs"
Add-Stack "049" "TypeScript (Next.js)" "Next.js, MDX, Tailwind" "Cloud CMS" "Playwright" "web app"
Add-Stack "050" "TypeScript (Node.js + React)" "WebSocket, CRDT" "Cloud DB" "vitest + Playwright" "cloud feature"
Add-Stack "051" "TypeScript (Node.js)" "graph DB (Neo4j or similar)" "Cloud Graph DB" "vitest" "cloud feature"
Add-Stack "052" "TypeScript (Node.js)" "RBAC library (Casbin)" "Cloud DB" "vitest" "cloud feature"
Add-Stack "053" "TypeScript (Node.js)" "audit logging library" "Cloud DB (append-only)" "vitest" "cloud feature"
Add-Stack "054" "TypeScript (React)" "Next.js, charts library" "Cloud API" "vitest + Playwright" "web app"
Add-Stack "055" "TypeScript (Node.js)" "SAML/OAuth libraries (Passport.js)" "Cloud DB" "vitest" "cloud feature"
Add-Stack "056" "TypeScript + Docker" "Docker Compose, Terraform" "Self-hosted infra" "integration" "infrastructure"
Add-Stack "057" "TypeScript (Node.js + React)" "charts library, event analytics" "Cloud DB (analytics)" "vitest + Playwright" "cloud feature"
Add-Stack "058" "N/A" "N/A" "N/A" "N/A" "documentation"
Add-Stack "059" "TypeScript (React)" "Tailwind CSS, lucide-react, Inter font" "N/A" "Storybook + vitest" "component library"
Add-Stack "060" "Rust + TypeScript" "Tauri updater, GitHub Releases API" "N/A" "integration + manual" "infrastructure"
Add-Stack "061" "TypeScript (React)" "React, @osai/ui" "localStorage" "vitest + @testing-library/react" "webview component"
Add-Stack "062" "TypeScript (Node.js)" "OpenAI SDK, Anthropic SDK, Ollama API, transformers.js" "SQLite (llm_usage) + OS keychain" "vitest" "sidecar service"
Add-Stack "063" "TypeScript (React) + Rust" "React, @osai/ui, IPC (named pipe)" "@osai/storage (connector_config table)" "vitest + cargo test" "webview component + Rust core"
Add-Stack "064" "TypeScript (Node.js)" "@osai/protocol, @osai/storage, LLM provider (spec 062)" "@osai/storage (event log, suggestions)" "vitest + integration" "sidecar service"

$specDirs = Get-ChildItem -Path $specsDir -Directory | Sort-Object Name
if ($SpecFilter) {
    $specDirs = $specDirs | Where-Object {
        $m = [regex]::Match($_.Name, "^\d+")
        $m.Success -and $m.Value -in $SpecFilter
    }
}

Write-Output "Generating speckit artifacts for $($specDirs.Count) specs..."
Write-Output ""

$totalPlans = 0
$totalTasks = 0

foreach ($dir in $specDirs) {
    $dirName = $dir.Name
    $specNum = if ($dirName -match "^(\d+)") { $matches[1] } else { "000" }
    $specPath = Join-Path $dir.FullName "spec.md"
    $planPath = Join-Path $dir.FullName "plan.md"
    $tasksPath = Join-Path $dir.FullName "tasks.md"

    if (-not (Test-Path $specPath)) {
        Write-Output "WARN: No spec.md in $dirName"
        continue
    }
    if ($DryRun) {
        Write-Output "[DRY RUN] $dirName ($specNum)"
        continue
    }

    $b = "**"
    $h3 = "###"
    $h4 = "####"
    $bullet = "*"
    $sep = "---"
    $bT = '```'
    $bO = '('
    $bC = ')'

    try {
        $specContent = Get-Content -Raw $specPath
        $specLines = Get-Content $specPath

        $featureName = "Spec $specNum"
        if ($specContent -match "# Feature Specification: (.+)") {
            $featureName = $matches[1].Trim()
        }

        $ts = $techStack[$specNum]
        if (-not $ts) {
            $ts = @{ lang = "TBD"; deps = "TBD"; storage = "TBD"; test = "TBD"; platform = "TBD" }
        }

        $stories = @()
        $currentTitle = ""
        $currentPriority = ""
        foreach ($line in $specLines) {
            if ($line -match "$h3 User Story (\d+) - (.+) $bO Priority: (P\d+)$bC") {
                if ($currentTitle) { $stories += @{ title = $currentTitle; priority = $currentPriority } }
                $currentTitle = $matches[2].Trim()
                $currentPriority = $matches[3]
            } elseif ($line -match "$h3 User Story (\d+) - (.+)") {
                if ($currentTitle) { $stories += @{ title = $currentTitle; priority = $currentPriority } }
                $currentTitle = $matches[2].Trim()
                $currentPriority = "P3"
            }
        }
        if ($currentTitle) { $stories += @{ title = $currentTitle; priority = $currentPriority } }
        if ($stories.Count -eq 0) { $stories += @{ title = "Implement $featureName"; priority = "P1" } }

        $acceptCount = 0
        foreach ($line in $specLines) {
            if ($line -match '^\d+\.\s+$bT$bTGiven$bT$bT') { $acceptCount++ }
        }

        $frCount = 0
        foreach ($line in $specLines) {
            if ($line -match '^-\s+$bT$bTFR-\d+$bT$bT') { $frCount++ }
        }

        $platformLabel = $ts.platform
        $projType = ""
        $sourceDir = ""

        if ($platformLabel -match "^webview") { $projType = "UI component" }
        elseif ($platformLabel -match "^sidecar") { $projType = "background service" }
        elseif ($platformLabel -match "^agent") { $projType = "background agent" }
        elseif ($platformLabel -match "^cloud") { $projType = "cloud service" }
        elseif ($platformLabel -eq "SDK") { $projType = "SDK library" }
        elseif ($platformLabel -match "^connector") { $projType = "capture connector" }
        elseif ($platformLabel -eq "library") { $projType = "library" }
        elseif ($platformLabel -eq "CLI") { $projType = "CLI tool" }
        elseif ($platformLabel -eq "infrastructure") { $projType = "infrastructure" }
        elseif ($platformLabel -eq "docs") { $projType = "documentation" }
        elseif ($platformLabel -match "^web app") { $projType = "web application" }
        elseif ($platformLabel -match "^mobile") { $projType = "mobile application" }
        elseif ($platformLabel -match "^browser") { $projType = "browser extension" }
        elseif ($platformLabel -match "^VS Code") { $projType = "VS Code extension" }
        elseif ($platformLabel -match "^Tauri") { $projType = "Tauri application" }
        elseif ($platformLabel -match "^Rust crate") { $projType = "Rust crate" }
        else { $projType = $platformLabel }

        if ($platformLabel -match "^webview") { $sourceDir = "ui/... (TBD by implementation)" }
        elseif ($platformLabel -match "^sidecar") { $sourceDir = "services/..." }
        elseif ($platformLabel -match "^agent") { $sourceDir = "agents/..." }
        elseif ($platformLabel -match "^cloud") { $sourceDir = "cloud/..." }
        elseif ($platformLabel -eq "SDK") { $sourceDir = "sdks/..." }
        elseif ($platformLabel -match "^connector") { $sourceDir = "connectors/..." }
        elseif ($platformLabel -eq "library") { $sourceDir = "packages/..." }
        elseif ($platformLabel -eq "CLI") { $sourceDir = "packages/cli/..." }
        elseif ($platformLabel -eq "infrastructure") { $sourceDir = "N/A (infrastructure/config)" }
        elseif ($platformLabel -eq "docs") { $sourceDir = "N/A (documentation)" }
        elseif ($platformLabel -match "^web app") { $sourceDir = "apps/web/..." }
        elseif ($platformLabel -match "^mobile") { $sourceDir = "apps/mobile/..." }
        elseif ($platformLabel -match "^browser") { $sourceDir = "connectors/browser/..." }
        elseif ($platformLabel -match "^VS Code") { $sourceDir = "connectors/vscode/..." }
        elseif ($platformLabel -match "^Tauri") { $sourceDir = "apps/desktop/..." }
        elseif ($platformLabel -match "^Rust crate") { $sourceDir = "crates/osai-core/..." }
        else { $sourceDir = "packages/..." }

        # Build plan lines
        $lines = @()
        $lines += "# Implementation Plan: $featureName"
        $lines += ""
        $lines += "Branch: $dirName | Date: $(Get-Date -Format 'yyyy-MM-dd') | Spec: spec.md"
        $lines += ""
        $lines += "Input: Feature specification from specs/$dirName/spec.md"
        $lines += ""
        $lines += "## Summary"
        $lines += ""
        $lines += "Implement the $featureName feature as specified. This spec covers $frCount functional requirements across $($stories.Count) user stories with $acceptCount acceptance scenarios."
        $lines += ""
        $lines += "## Technical Context"
        $lines += ""
        $lines += "${b}Language/Version${b}: $($ts.lang)"
        $lines += ""
        $lines += "${b}Primary Dependencies${b}: $($ts.deps)"
        $lines += ""
        $lines += "${b}Storage${b}: $($ts.storage)"
        $lines += ""
        $lines += "${b}Testing${b}: $($ts.test)"
        $lines += ""
        $lines += "${b}Target Platform${b}: $($ts.platform)"
        $lines += ""
        $lines += "${b}Project Type${b}: $projType"
        $lines += ""
        $lines += "## Constitution Check"
        $lines += ""
        $lines += "Gate: Must pass before implementation."
        $lines += ""
        $lines += "- Follow OSAI coding conventions (TypeScript: functional components, Tailwind, vitest; Rust: rusqlite, refinery, cargo test)"
        $lines += "- No comments in code unless logic is non-obvious"
        $lines += "- No emojis in files"
        $lines += "- Coverage gate: 90% Rust core, 80% webview/sidecars"
        $lines += "- Branch naming: $dirName"
        $lines += ""
        $lines += "## Project Structure"
        $lines += ""
        $lines += "${h3}Documentation (this feature)"
        $lines += ""
        $lines += "${bT}text"
        $lines += "specs/$dirName/"
        $lines += " spec.md              # Feature specification"
        $lines += " plan.md              # This file"
        $lines += " tasks.md             # Task breakdown"
        $lines += "${bT}"
        $lines += ""
        $lines += "${h3}Source Code (repository root)"
        $lines += ""
        $lines += "${bT}text"
        $lines += "$sourceDir"
        $lines += "${bT}"
        $lines += ""
        $lines += "## User Stories"
        $lines += ""
        for ($i = 0; $i -lt $stories.Count; $i++) {
            $s = $stories[$i]
            $lines += "- ${b}US$($i+1) ($($s.priority))${b}: $($s.title)"
        }
        $lines += ""

        [System.IO.File]::WriteAllText($planPath, ($lines -join "`r`n"), [System.Text.UTF8Encoding]::new($false))
        Write-Output "  [OK] $dirName - plan.md generated ($($stories.Count) stories, $frCount FRs)"
        $totalPlans++

        # Build tasks lines
        $tlines = @()
        $tlines += "# Tasks: $featureName"
        $tlines += ""
        $tlines += "Input: Design documents from specs/$dirName/"
        $tlines += ""
        $tlines += "Prerequisites: spec.md"
        $tlines += "Tests: Tests are OPTIONAL - only include if explicitly requested."
        $tlines += "Organization: Tasks are grouped by user story."
        $tlines += ""
        $tlines += "## Format: [ID] [P] [Story] Description"
        $tlines += ""
        $tlines += "- [P]: Can run in parallel"
        $tlines += "- [Story]: Which user story this task belongs to (e.g., US1, US2)"
        $tlines += "- Include exact file paths in descriptions"
        $tlines += ""
        $tlines += "## Phase 1: Setup (Shared Infrastructure)"
        $tlines += ""
        $tlines += "- [ ] T001 [P] Create feature directory structure per OSAI monorepo layout"
        $tlines += "- [ ] T002 [P] Add package.json / Cargo.toml with dependencies: $($ts.deps)"
        $tlines += "- [ ] T003 Configure build scripts and CI integration in .github/workflows/ci.yml"
        $tlines += ""
        $tlines += "$sep"
        $tlines += ""
        $tlines += "## Phase 2: Foundational (Blocking Prerequisites)"
        $tlines += ""
        $tlines += "- [ ] T004 Define data types and interfaces based on spec Key Entities"
        $tlines += "- [ ] T005 [P] Set up test framework ($($ts.test))"
        $tlines += "- [ ] T006 [P] Implement base classes and shared utilities"
        $tlines += ""
        $tlines += "Checkpoint: Foundation ready - user story implementation can begin"
        $tlines += ""

        $taskId = 7
        $phaseNum = 3
        for ($i = 0; $i -lt $stories.Count; $i++) {
            $s = $stories[$i]
            $storyNum = $i + 1
            $storyLabel = "US$storyNum"

            $tlines += "$sep"
            $tlines += ""
            $tlines += "## Phase ${phaseNum}: User Story $storyNum - $($s.title) (Priority: $($s.priority))"
            $tlines += ""
            $tlines += "Goal: $($s.title)"
            $tlines += ""
            $tlines += "Independent Test: Verify acceptance scenarios from spec.md for this story"
            $tlines += ""
            $tlines += "${h3}Implementation for User Story $storyNum"
            $tlines += ""

            $tlines += "- [ ] T$("{0:D3}" -f $taskId) [$storyLabel] Implement core logic for $($s.title)"
            $taskId++
            $tlines += "- [ ] T$("{0:D3}" -f $taskId) [P] [$storyLabel] Write unit tests for $($s.title)"
            $taskId++
            $tlines += "- [ ] T$("{0:D3}" -f $taskId) [$storyLabel] Integrate $($s.title) with existing OSAI infrastructure"
            $taskId++

            if ($s.priority -eq "P1") {
                $tlines += "- [ ] T$("{0:D3}" -f $taskId) [$storyLabel] Validate acceptance scenarios for $($s.title)"
                $taskId++
                $tlines += ""
                $tlines += "Checkpoint: $storyLabel (P1) functional and independently testable"
            } else {
                $tlines += ""
                $tlines += "Checkpoint: $storyLabel functional"
            }
            $tlines += ""
            $phaseNum++
        }

        $tlines += "$sep"
        $tlines += ""
        $tlines += "## Phase ${phaseNum}: Polish and Cross-Cutting Concerns"
        $tlines += ""
        $tlines += "- [ ] T$("{0:D3}" -f $taskId) [P] Document API and usage patterns in docs/"
        $taskId++
        $tlines += "- [ ] T$("{0:D3}" -f $taskId) Code cleanup and refactoring"
        $taskId++
        $tlines += "- [ ] T$("{0:D3}" -f $taskId) [P] Additional integration tests"
        $taskId++
        $tlines += "- [ ] T$("{0:D3}" -f $taskId) Run end-to-end validation per spec Success Criteria"
        $taskId++
        $tlines += ""
        $tlines += "$sep"
        $tlines += ""
        $tlines += "## Dependencies and Execution Order"
        $tlines += ""
        $tlines += "- Setup (Phase 1): No dependencies - can start immediately"
        $tlines += "- Foundational (Phase 2): Depends on Setup completion - BLOCKS all user stories"
        $tlines += "- User Stories (Phase 3+): All depend on Foundational phase completion"
        $tlines += "- Polish (Final Phase): Depends on all desired user stories being complete"
        $tlines += ""
        $tlines += "${h3}User Story Dependencies"
        for ($i = 0; $i -lt $stories.Count; $i++) {
            $s = $stories[$i]
            $tlines += "- User Story $($i+1) ($($s.priority)): $($s.title) - can start after Foundational (Phase 2)"
        }
        $tlines += ""
        $tlines += "${h3}Implementation Strategy"
        $tlines += "1. Complete Phase 1: Setup"
        $tlines += "2. Complete Phase 2: Foundational"
        $tlines += "3. Implement user stories in priority order (P1 first, then P2, then P3)"
        $tlines += "4. Each story should be independently testable"
        $tlines += "5. Polish after all stories are complete"

        [System.IO.File]::WriteAllText($tasksPath, ($tlines -join "`r`n"), [System.Text.UTF8Encoding]::new($false))
        Write-Output "  [OK] $dirName - tasks.md generated ($($stories.Count) stories, ~$($taskId-1) tasks)"
        $totalTasks++

    } catch {
        Write-Output "  [ERR] $dirName - $($_.Exception.Message)"
    }
}

Write-Output ""
Write-Output "=== Summary ==="
Write-Output "Plans generated: $totalPlans"
Write-Output "Tasks generated: $totalTasks"

# Verify speckit compatibility
Write-Output ""
Write-Output "=== Speckit Verification ==="
foreach ($dir in $specDirs) {
    $planExists = Test-Path (Join-Path $dir.FullName "plan.md")
    $tasksExists = Test-Path (Join-Path $dir.FullName "tasks.md")
    $specExists = Test-Path (Join-Path $dir.FullName "spec.md")
    if ($planExists -and $tasksExists -and $specExists) {
        $env:SPECIFY_FEATURE_DIRECTORY = $dir.FullName
        $result = & (Join-Path $repoRoot ".specify/scripts/powershell/check-prerequisites.ps1") -Json 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "  [OK] $($dir.Name) - speckit-ready"
        } else {
            Write-Output "  [WARN] $($dir.Name) - speckit check failed (check-prerequisites may need specifc config)"
        }
    }
}
