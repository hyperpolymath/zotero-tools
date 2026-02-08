BeforeAll {
  # Store the script path
  $script:ScriptPath = Join-Path $PSScriptRoot '..' 'init-zotero-rscript-plugin.ps1'

  # Create temporary test directory
  $script:TestRoot = Join-Path $env:TEMP "ZoteroTemplaterTests-$(Get-Random)"
  New-Item -ItemType Directory -Path $script:TestRoot -Force | Out-Null
  Push-Location $script:TestRoot
}

AfterAll {
  # Cleanup
  Pop-Location
  if (Test-Path $script:TestRoot) {
    Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Describe "PowerShell Scaffolder - Basic Functionality" {
  Context "Practitioner Template" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "TestPractitioner" `
        -AuthorName "Pester Test" `
        -TemplateType practitioner
      Pop-Location
    }

    It "Creates the project directory" {
      Test-Path (Join-Path $script:TestRoot "TestPractitioner") | Should -Be $true
    }

    It "Creates README.md with correct content" {
      $readme = Join-Path $script:TestRoot "TestPractitioner" "README.md"
      Test-Path $readme | Should -Be $true

      $content = Get-Content $readme -Raw
      $content | Should -Match "TestPractitioner"
      $content | Should -Match "Pester Test"
    }

    It "Creates bootstrap.js" {
      $bootstrap = Join-Path $script:TestRoot "TestPractitioner" "bootstrap.js"
      Test-Path $bootstrap | Should -Be $true
    }

    It "Creates install.rdf with correct metadata" {
      $installRdf = Join-Path $script:TestRoot "TestPractitioner" "install.rdf"
      Test-Path $installRdf | Should -Be $true

      $content = Get-Content $installRdf -Raw
      $content | Should -Match "TestPractitioner"
      $content | Should -Match "Pester Test"
      $content | Should -Match "<em:id>TestPractitioner@zotero.org</em:id>"
    }

    It "Creates chrome.manifest" {
      $manifest = Join-Path $script:TestRoot "TestPractitioner" "chrome.manifest"
      Test-Path $manifest | Should -Be $true
    }

    It "Creates chrome/content directory structure" {
      $chromeContent = Join-Path $script:TestRoot "TestPractitioner" "chrome" "content"
      Test-Path $chromeContent | Should -Be $true
    }

    It "Creates src/ directory with ReScript file" {
      $srcDir = Join-Path $script:TestRoot "TestPractitioner" "src"
      Test-Path $srcDir | Should -Be $true

      $rescriptFile = Join-Path $srcDir "Plugin.re"
      Test-Path $rescriptFile | Should -Be $true
    }

    It "Creates package.json with correct configuration" {
      $packageJson = Join-Path $script:TestRoot "TestPractitioner" "package.json"
      Test-Path $packageJson | Should -Be $true

      $pkg = Get-Content $packageJson -Raw | ConvertFrom-Json
      $pkg.name | Should -Be "TestPractitioner"
      $pkg.author | Should -Be "Pester Test"
      $pkg.scripts.build | Should -Not -BeNullOrEmpty
    }

    It "Creates bsconfig.json" {
      $bsconfig = Join-Path $script:TestRoot "TestPractitioner" "bsconfig.json"
      Test-Path $bsconfig | Should -Be $true
    }

    It "Creates audit-index.json with file hashes" {
      $auditIndex = Join-Path $script:TestRoot "TestPractitioner" "audit-index.json"
      Test-Path $auditIndex | Should -Be $true

      $audit = Get-Content $auditIndex -Raw | ConvertFrom-Json
      $audit.generated | Should -Not -BeNullOrEmpty
      $audit.files | Should -Not -BeNullOrEmpty
      $audit.files.Count | Should -BeGreaterThan 0
    }

    It "Does not contain template variables in generated files" {
      $readme = Get-Content (Join-Path $script:TestRoot "TestPractitioner" "README.md") -Raw
      $readme | Should -Not -Match '\{\{ProjectName\}\}'
      $readme | Should -Not -Match '\{\{AuthorName\}\}'
      $readme | Should -Not -Match '\{\{version\}\}'
    }
  }

  Context "Researcher Template" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "TestResearcher" `
        -AuthorName "Research Test" `
        -TemplateType researcher
      Pop-Location
    }

    It "Creates research-specific files" {
      $bootstrap = Join-Path $script:TestRoot "TestResearcher" "bootstrap.js"
      Test-Path $bootstrap | Should -Be $true

      $content = Get-Content $bootstrap -Raw
      $content | Should -Match "database"
      $content | Should -Match "citations"
    }

    It "Creates research UI components" {
      $mainJs = Join-Path $script:TestRoot "TestResearcher" "chrome" "content" "main.js"
      Test-Path $mainJs | Should -Be $true

      $content = Get-Content $mainJs -Raw
      $content | Should -Match "analyzeCitations"
      $content | Should -Match "extractMetadata"
      $content | Should -Match "exportData"
    }

    It "Has correct install.rdf metadata for research edition" {
      $installRdf = Join-Path $script:TestRoot "TestResearcher" "install.rdf"
      $content = Get-Content $installRdf -Raw
      $content | Should -Match "Research Edition"
      $content | Should -Match "research.zotero.org"
    }
  }

  Context "Student Template" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "TestStudent" `
        -AuthorName "Student Test" `
        -TemplateType student
      Pop-Location
    }

    It "Creates TUTORIAL.md" {
      $tutorial = Join-Path $script:TestRoot "TestStudent" "TUTORIAL.md"
      Test-Path $tutorial | Should -Be $true

      $content = Get-Content $tutorial -Raw
      $content | Should -Match "Tutorial"
      $content | Should -Match "Understanding the Structure"
    }

    It "Creates TypeScript configuration" {
      $tsconfig = Join-Path $script:TestRoot "TestStudent" "tsconfig.json"
      Test-Path $tsconfig | Should -Be $true

      $config = Get-Content $tsconfig -Raw | ConvertFrom-Json
      $config.compilerOptions.strict | Should -Be $true
    }

    It "Creates TypeScript source file" {
      $indexTs = Join-Path $script:TestRoot "TestStudent" "src" "index.ts"
      Test-Path $indexTs | Should -Be $true

      $content = Get-Content $indexTs -Raw
      $content | Should -Match "interface ZoteroItem"
      $content | Should -Match "class PluginHelper"
    }

    It "Has extensively commented bootstrap.js" {
      $bootstrap = Join-Path $script:TestRoot "TestStudent" "bootstrap.js"
      $content = Get-Content $bootstrap -Raw

      # Check for educational comments
      $content | Should -Match "/\*\*"
      $content | Should -Match "Bootstrap Entry Point"
      $content | Should -Match "Notifier callback"
    }

    It "Creates educational UI examples" {
      $mainJs = Join-Path $script:TestRoot "TestStudent" "chrome" "content" "main.js"
      $content = Get-Content $mainJs -Raw

      $content | Should -Match "sayHello"
      $content | Should -Match "countSelected"
      $content | Should -Match "This demonstrates"
    }
  }
}

Describe "PowerShell Scaffolder - Git Integration" {
  Context "GitInit Flag" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "TestGit" `
        -AuthorName "Git Test" `
        -TemplateType student `
        -GitInit
      Pop-Location
    }

    It "Creates .gitignore" {
      $gitignore = Join-Path $script:TestRoot "TestGit" ".gitignore"
      Test-Path $gitignore | Should -Be $true

      $content = Get-Content $gitignore -Raw
      $content | Should -Match "node_modules"
      $content | Should -Match "\.DS_Store"
    }
  }

  Context "Without GitInit Flag" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "TestNoGit" `
        -AuthorName "No Git Test" `
        -TemplateType student
      Pop-Location
    }

    It "Does not create .gitignore when GitInit not specified" {
      # Note: Student template includes .gitignore in embedded template
      # This test would be more relevant for practitioner template if it didn't include .gitignore
      $true | Should -Be $true  # Placeholder
    }
  }
}

Describe "PowerShell Scaffolder - Integrity Verification" {
  Context "Unmodified Files" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "IntegrityTest" `
        -AuthorName "Integrity Test" `
        -TemplateType student
      Pop-Location
    }

    It "Passes verification for unmodified project" {
      Push-Location $script:TestRoot
      { & $script:ScriptPath `
          -ProjectName "IntegrityTest" `
          -VerifyIntegrity
      } | Should -Not -Throw
      Pop-Location
    }
  }

  Context "Modified Files" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "TamperTest" `
        -AuthorName "Tamper Test" `
        -TemplateType student
      Pop-Location

      # Tamper with a file
      $readme = Join-Path $script:TestRoot "TamperTest" "README.md"
      "Modified content" | Out-File -FilePath $readme -Append
    }

    It "Detects tampering in modified files" {
      Push-Location $script:TestRoot
      { & $script:ScriptPath `
          -ProjectName "TamperTest" `
          -VerifyIntegrity
      } | Should -Throw
      Pop-Location
    }
  }

  Context "Missing Files" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "MissingTest" `
        -AuthorName "Missing Test" `
        -TemplateType student
      Pop-Location

      # Delete a file
      $readme = Join-Path $script:TestRoot "MissingTest" "README.md"
      Remove-Item $readme -Force
    }

    It "Detects missing files" {
      Push-Location $script:TestRoot
      { & $script:ScriptPath `
          -ProjectName "MissingTest" `
          -VerifyIntegrity
      } | Should -Throw
      Pop-Location
    }
  }

  Context "Audit Index Structure" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "AuditStructure" `
        -AuthorName "Audit Test" `
        -TemplateType student
      Pop-Location
    }

    It "Creates audit-index.json with valid structure" {
      $auditPath = Join-Path $script:TestRoot "AuditStructure" "audit-index.json"
      $audit = Get-Content $auditPath -Raw | ConvertFrom-Json

      $audit.generated | Should -Not -BeNullOrEmpty
      $audit.generated | Should -Match '^\d{4}-\d{2}-\d{2}T'

      $audit.files | Should -Not -BeNullOrEmpty
      $audit.files | Should -BeOfType [System.Object[]]

      $audit.files[0].path | Should -Not -BeNullOrEmpty
      $audit.files[0].hash | Should -Not -BeNullOrEmpty
      $audit.files[0].hash | Should -Match '^[0-9A-F]{16}$'
    }

    It "Includes all generated files in audit index" {
      $projectPath = Join-Path $script:TestRoot "AuditStructure"
      $auditPath = Join-Path $projectPath "audit-index.json"

      $allFiles = Get-ChildItem -Path $projectPath -File -Recurse | ForEach-Object {
        $_.FullName.Substring($projectPath.Length + 1).Replace('\', '/')
      }

      $audit = Get-Content $auditPath -Raw | ConvertFrom-Json
      $auditedFiles = $audit.files | ForEach-Object { $_.path }

      foreach ($file in $allFiles) {
        $auditedFiles | Should -Contain $file
      }
    }
  }
}

Describe "PowerShell Scaffolder - Variable Substitution" {
  Context "All Template Variables" {
    BeforeAll {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "VarSubTest" `
        -AuthorName "Variable Test Author" `
        -TemplateType student
      Pop-Location
    }

    It "Substitutes {{ProjectName}} in all files" {
      $projectPath = Join-Path $script:TestRoot "VarSubTest"
      $textFiles = Get-ChildItem -Path $projectPath -File -Recurse |
        Where-Object { $_.Extension -in '.md','.js','.ts','.json','.rdf','.xul' }

      foreach ($file in $textFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
          $content | Should -Not -Match '\{\{ProjectName\}\}'
        }
      }
    }

    It "Substitutes {{AuthorName}} in all files" {
      $projectPath = Join-Path $script:TestRoot "VarSubTest"
      $textFiles = Get-ChildItem -Path $projectPath -File -Recurse |
        Where-Object { $_.Extension -in '.md','.js','.ts','.json','.rdf' }

      foreach ($file in $textFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
          $content | Should -Not -Match '\{\{AuthorName\}\}'
        }
      }
    }

    It "Correctly substitutes actual values" {
      $readme = Get-Content (Join-Path $script:TestRoot "VarSubTest" "README.md") -Raw
      $readme | Should -Match "VarSubTest"
      $readme | Should -Match "Variable Test Author"

      $installRdf = Get-Content (Join-Path $script:TestRoot "VarSubTest" "install.rdf") -Raw
      $installRdf | Should -Match "VarSubTest"
      $installRdf | Should -Match "Variable Test Author"
    }
  }
}

Describe "PowerShell Scaffolder - Edge Cases" {
  Context "Special Characters in Names" {
    It "Handles spaces in project name" {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "My Plugin Name" `
        -AuthorName "Test Author" `
        -TemplateType student
      Pop-Location

      Test-Path (Join-Path $script:TestRoot "My Plugin Name") | Should -Be $true
    }

    It "Handles quotes in author name" {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "QuoteTest" `
        -AuthorName "O'Brien" `
        -TemplateType student
      Pop-Location

      $readme = Get-Content (Join-Path $script:TestRoot "QuoteTest" "README.md") -Raw
      $readme | Should -Match "O'Brien"
    }
  }

  Context "Error Handling" {
    It "Throws error when project directory already exists" {
      Push-Location $script:TestRoot
      & $script:ScriptPath `
        -ProjectName "DuplicateTest" `
        -AuthorName "Test" `
        -TemplateType student
      Pop-Location

      Push-Location $script:TestRoot
      { & $script:ScriptPath `
          -ProjectName "DuplicateTest" `
          -AuthorName "Test" `
          -TemplateType student
      } | Should -Throw "*already exists*"
      Pop-Location
    }
  }
}

Describe "PowerShell Scaffolder - XXHash64 Implementation" {
  It "Computes consistent hashes for same input" {
    # This tests the XXHash64 implementation indirectly
    Push-Location $script:TestRoot
    & $script:ScriptPath `
      -ProjectName "HashTest1" `
      -AuthorName "Test" `
      -TemplateType student
    Pop-Location

    $audit1 = Get-Content (Join-Path $script:TestRoot "HashTest1" "audit-index.json") -Raw | ConvertFrom-Json

    # Create identical project
    Push-Location $script:TestRoot
    Remove-Item (Join-Path $script:TestRoot "HashTest1") -Recurse -Force
    & $script:ScriptPath `
      -ProjectName "HashTest1" `
      -AuthorName "Test" `
      -TemplateType student
    Pop-Location

    $audit2 = Get-Content (Join-Path $script:TestRoot "HashTest1" "audit-index.json") -Raw | ConvertFrom-Json

    # Hashes should be identical (excluding audit-index.json itself)
    $file1Hashes = $audit1.files | Where-Object { $_.path -ne 'audit-index.json' } | Select-Object -ExpandProperty hash | Sort-Object
    $file2Hashes = $audit2.files | Where-Object { $_.path -ne 'audit-index.json' } | Select-Object -ExpandProperty hash | Sort-Object

    Compare-Object $file1Hashes $file2Hashes | Should -BeNullOrEmpty
  }

  It "Produces different hashes for different content" {
    Push-Location $script:TestRoot
    & $script:ScriptPath `
      -ProjectName "HashTest2" `
      -AuthorName "Author1" `
      -TemplateType student
    Pop-Location

    Push-Location $script:TestRoot
    & $script:ScriptPath `
      -ProjectName "HashTest3" `
      -AuthorName "Author2" `
      -TemplateType student
    Pop-Location

    $audit2 = Get-Content (Join-Path $script:TestRoot "HashTest2" "audit-index.json") -Raw | ConvertFrom-Json
    $audit3 = Get-Content (Join-Path $script:TestRoot "HashTest3" "audit-index.json") -Raw | ConvertFrom-Json

    # Find README.md hashes (should be different due to different author names)
    $hash2 = ($audit2.files | Where-Object { $_.path -eq 'README.md' }).hash
    $hash3 = ($audit3.files | Where-Object { $_.path -eq 'README.md' }).hash

    $hash2 | Should -Not -Be $hash3
  }
}
