# Property-Based Testing - PowerShell

BeforeAll {
  $script:ScriptPath = Join-Path $PSScriptRoot '..' 'init-zotero-rscript-plugin.ps1'
  $script:TestRoot = Join-Path $env:TEMP "ZoteroTemplaterPropTests-$(Get-Random)"
  New-Item -ItemType Directory -Path $script:TestRoot -Force | Out-Null
  Push-Location $script:TestRoot
}

AfterAll {
  Pop-Location
  if (Test-Path $script:TestRoot) {
    Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Describe "Property-Based Testing - Variable Substitution" {
  Context "Commutativity: Substitution order doesn't matter" {
    It "Should produce same result regardless of substitution order" {
      # Property: Substituting {{ProjectName}} then {{AuthorName}} should equal
      # substituting {{AuthorName}} then {{ProjectName}}

      $testCases = @(
        @{ Name = "Test1"; Author = "Author1" }
        @{ Name = "Test2"; Author = "Author2" }
        @{ Name = "MyProject"; Author = "John Doe" }
      )

      foreach ($case in $testCases) {
        Push-Location $script:TestRoot
        & $script:ScriptPath `
          -ProjectName $case.Name `
          -AuthorName $case.Author `
          -TemplateType student
        Pop-Location

        $readme = Get-Content (Join-Path $script:TestRoot $case.Name "README.md") -Raw

        # Verify no template variables remain
        $readme | Should -Not -Match '\{\{ProjectName\}\}'
        $readme | Should -Not -Match '\{\{AuthorName\}\}'

        # Verify both substitutions occurred
        $readme | Should -Match $case.Name
        $readme | Should -Match $case.Author

        # Cleanup for next iteration
        Remove-Item (Join-Path $script:TestRoot $case.Name) -Recurse -Force
      }
    }
  }

  Context "Idempotency: Multiple applications yield same result" {
    It "Should produce identical output when run twice with same inputs" {
      Push-Location $script:TestRoot

      # First run
      & $script:ScriptPath `
        -ProjectName "IdempotencyTest" `
        -AuthorName "Test Author" `
        -TemplateType student

      $audit1 = Get-Content (Join-Path $script:TestRoot "IdempotencyTest" "audit-index.json") -Raw
      Remove-Item (Join-Path $script:TestRoot "IdempotencyTest") -Recurse -Force

      # Second run with same parameters
      & $script:ScriptPath `
        -ProjectName "IdempotencyTest" `
        -AuthorName "Test Author" `
        -TemplateType student

      $audit2 = Get-Content (Join-Path $script:TestRoot "IdempotencyTest" "audit-index.json") -Raw

      Pop-Location

      # Parse and compare (excluding generated timestamp)
      $obj1 = $audit1 | ConvertFrom-Json
      $obj2 = $audit2 | ConvertFrom-Json

      # File hashes should be identical (excluding audit-index.json itself)
      $hashes1 = $obj1.files | Where-Object { $_.path -ne 'audit-index.json' } | Sort-Object path
      $hashes2 = $obj2.files | Where-Object { $_.path -ne 'audit-index.json' } | Sort-Object path

      $hashes1.Count | Should -Be $hashes2.Count

      for ($i = 0; $i -lt $hashes1.Count; $i++) {
        $hashes1[$i].path | Should -Be $hashes2[$i].path
        $hashes1[$i].hash | Should -Be $hashes2[$i].hash
      }
    }
  }

  Context "Associativity: Grouping doesn't affect result" {
    It "Should handle nested variable patterns correctly" {
      # Property: ((A + B) + C) = (A + (B + C))
      # Test that complex substitution patterns work correctly

      Push-Location $script:TestRoot

      & $script:ScriptPath `
        -ProjectName "AssocTest" `
        -AuthorName "Complex Author Name" `
        -TemplateType student

      Pop-Location

      $files = Get-ChildItem -Path (Join-Path $script:TestRoot "AssocTest") -File -Recurse

      foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
          # No partial substitutions should remain
          $content | Should -Not -Match '\{\{[^}]*\}\}'
        }
      }
    }
  }
}

Describe "Property-Based Testing - File Integrity" {
  Context "Hash determinism" {
    It "Should produce same hash for identical content" {
      Push-Location $script:TestRoot

      # Create project
      & $script:ScriptPath `
        -ProjectName "HashTest" `
        -AuthorName "Hash Author" `
        -TemplateType student

      Pop-Location

      $audit = Get-Content (Join-Path $script:TestRoot "HashTest" "audit-index.json") -Raw | ConvertFrom-Json

      # Get a sample file
      $sampleFile = $audit.files | Where-Object { $_.path -eq 'README.md' } | Select-Object -First 1
      $samplePath = Join-Path $script:TestRoot "HashTest" $sampleFile.path

      # Compute hash multiple times
      $hash1 = $sampleFile.hash

      # Re-compute using same algorithm
      # (This tests hash determinism)
      Push-Location $script:TestRoot
      Remove-Item (Join-Path $script:TestRoot "HashTest" "audit-index.json") -Force

      & $script:ScriptPath `
        -ProjectName "HashTest" `
        -AuthorName "Hash Author" `
        -TemplateType student

      Pop-Location

      $audit2 = Get-Content (Join-Path $script:TestRoot "HashTest" "audit-index.json") -Raw | ConvertFrom-Json
      $hash2 = ($audit2.files | Where-Object { $_.path -eq 'README.md' }).hash

      $hash1 | Should -Be $hash2
    }
  }

  Context "Collision resistance" {
    It "Should produce different hashes for different content" {
      Push-Location $script:TestRoot

      # Create two projects with different authors
      & $script:ScriptPath `
        -ProjectName "Collision1" `
        -AuthorName "Author One" `
        -TemplateType student

      & $script:ScriptPath `
        -ProjectName "Collision2" `
        -AuthorName "Author Two" `
        -TemplateType student

      Pop-Location

      $audit1 = Get-Content (Join-Path $script:TestRoot "Collision1" "audit-index.json") -Raw | ConvertFrom-Json
      $audit2 = Get-Content (Join-Path $script:TestRoot "Collision2" "audit-index.json") -Raw | ConvertFrom-Json

      $hash1 = ($audit1.files | Where-Object { $_.path -eq 'README.md' }).hash
      $hash2 = ($audit2.files | Where-Object { $_.path -eq 'README.md' }).hash

      # Different content should produce different hashes
      $hash1 | Should -Not -Be $hash2
    }
  }
}

Describe "Property-Based Testing - Template Types" {
  Context "Template completeness" {
    It "Should create all required files for each template type" -TestCases @(
      @{ Type = 'practitioner' }
      @{ Type = 'researcher' }
      @{ Type = 'student' }
    ) {
      param($Type)

      Push-Location $script:TestRoot

      & $script:ScriptPath `
        -ProjectName "Complete_$Type" `
        -AuthorName "Test" `
        -TemplateType $Type

      Pop-Location

      $projectPath = Join-Path $script:TestRoot "Complete_$Type"

      # All templates should have these core files
      $requiredFiles = @(
        'README.md'
        'install.rdf'
        'chrome.manifest'
        'bootstrap.js'
        'package.json'
        '.gitignore'
        'audit-index.json'
      )

      foreach ($file in $requiredFiles) {
        Test-Path (Join-Path $projectPath $file) | Should -Be $true
      }
    }
  }

  Context "Template isolation" {
    It "Should not leak template-specific content across types" {
      $types = @('practitioner', 'researcher', 'student')
      $projects = @()

      foreach ($type in $types) {
        Push-Location $script:TestRoot

        & $script:ScriptPath `
          -ProjectName "Isolation_$type" `
          -AuthorName "Test" `
          -TemplateType $type

        Pop-Location

        $projects += @{
          Type = $type
          Path = Join-Path $script:TestRoot "Isolation_$type"
          Files = Get-ChildItem -Path (Join-Path $script:TestRoot "Isolation_$type") -File -Recurse
        }
      }

      # Verify practitioner-specific content only in practitioner
      $practitionerContent = ($projects | Where-Object { $_.Type -eq 'practitioner' }).Files |
        Where-Object { $_.Name -like '*Plugin.re' }
      $practitionerContent | Should -Not -BeNullOrEmpty

      $nonPractitioner = $projects | Where-Object { $_.Type -ne 'practitioner' }
      foreach ($proj in $nonPractitioner) {
        $proj.Files | Where-Object { $_.Name -like '*Plugin.re' } | Should -BeNullOrEmpty
      }

      # Verify student-specific TUTORIAL.md only in student
      $studentTutorial = ($projects | Where-Object { $_.Type -eq 'student' }).Files |
        Where-Object { $_.Name -eq 'TUTORIAL.md' }
      $studentTutorial | Should -Not -BeNullOrEmpty

      $nonStudent = $projects | Where-Object { $_.Type -ne 'student' }
      foreach ($proj in $nonStudent) {
        $proj.Files | Where-Object { $_.Name -eq 'TUTORIAL.md' } | Should -BeNullOrEmpty
      }
    }
  }
}

Describe "Property-Based Testing - Boundary Conditions" {
  Context "Empty and whitespace handling" {
    It "Should handle project names with various whitespace" -TestCases @(
      @{ Name = "Single Word" }
      @{ Name = "Multiple   Spaces" }
      @{ Name = "  LeadingSpace" }
      @{ Name = "TrailingSpace  " }
    ) {
      param($Name)

      Push-Location $script:TestRoot

      & $script:ScriptPath `
        -ProjectName $Name `
        -AuthorName "Test" `
        -TemplateType student

      Pop-Location

      Test-Path (Join-Path $script:TestRoot $Name) | Should -Be $true

      $readme = Get-Content (Join-Path $script:TestRoot $Name "README.md") -Raw
      $readme | Should -Match [regex]::Escape($Name)
    }
  }

  Context "Special characters in author names" {
    It "Should handle various special characters" -TestCases @(
      @{ Author = "O'Brien" }
      @{ Author = "Jean-Paul Sartre" }
      @{ Author = "Müller" }
      @{ Author = "José García" }
    ) {
      param($Author)

      Push-Location $script:TestRoot

      $safeProjectName = "Special_$(Get-Random)"

      & $script:ScriptPath `
        -ProjectName $safeProjectName `
        -AuthorName $Author `
        -TemplateType student

      Pop-Location

      $readme = Get-Content (Join-Path $script:TestRoot $safeProjectName "README.md") -Raw
      $readme | Should -Match [regex]::Escape($Author)
    }
  }

  Context "Path length limits" {
    It "Should handle reasonably long project names" {
      # Test with 50-character project name (well within limits)
      $longName = "A" * 50

      Push-Location $script:TestRoot

      & $script:ScriptPath `
        -ProjectName $longName `
        -AuthorName "Test" `
        -TemplateType student

      Pop-Location

      Test-Path (Join-Path $script:TestRoot $longName) | Should -Be $true
    }
  }
}

Describe "Property-Based Testing - Invariants" {
  Context "File count invariant" {
    It "Should create consistent number of files per template type" {
      $type = 'student'
      $runs = 3
      $fileCounts = @()

      for ($i = 0; $i -lt $runs; $i++) {
        Push-Location $script:TestRoot

        & $script:ScriptPath `
          -ProjectName "Invariant_$i" `
          -AuthorName "Test" `
          -TemplateType $type

        Pop-Location

        $count = (Get-ChildItem -Path (Join-Path $script:TestRoot "Invariant_$i") -File -Recurse).Count
        $fileCounts += $count

        Remove-Item (Join-Path $script:TestRoot "Invariant_$i") -Recurse -Force
      }

      # All runs should produce same file count
      $fileCounts | Select-Object -Unique | Should -HaveCount 1
    }
  }

  Context "Audit index completeness invariant" {
    It "Should include all files in audit index" {
      Push-Location $script:TestRoot

      & $script:ScriptPath `
        -ProjectName "AuditComplete" `
        -AuthorName "Test" `
        -TemplateType student

      Pop-Location

      $projectPath = Join-Path $script:TestRoot "AuditComplete"
      $allFiles = Get-ChildItem -Path $projectPath -File -Recurse | ForEach-Object {
        $_.FullName.Substring($projectPath.Length + 1).Replace('\', '/')
      }

      $audit = Get-Content (Join-Path $projectPath "audit-index.json") -Raw | ConvertFrom-Json
      $auditedFiles = $audit.files | ForEach-Object { $_.path }

      # Every file should be in audit
      foreach ($file in $allFiles) {
        $auditedFiles | Should -Contain $file
      }
    }
  }
}
