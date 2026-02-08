#lang racket

(require rackunit
         racket/file
         racket/path
         racket/system
         racket/date
         json)

;; Test utilities
(define (with-temp-dir proc)
  "Execute proc in a temporary directory, cleaning up afterwards"
  (define temp-dir (build-path (find-system-path 'temp-dir)
                                (format "racket-test-~a" (random 1000000))))
  (make-directory temp-dir)
  (define original-dir (current-directory))
  (dynamic-wind
    (λ () (current-directory temp-dir))
    proc
    (λ ()
      (current-directory original-dir)
      (when (directory-exists? temp-dir)
        (delete-directory/files temp-dir)))))

(define (run-scaffolder name author . flags)
  "Run the scaffolder with given parameters"
  (define script-path
    (build-path (current-directory) ".." "init-raczotbuild.rkt"))
  (apply system*
         (find-executable-path "racket")
         script-path
         "-n" name
         "-a" author
         flags))

(define (file-contains? path pattern)
  "Check if file contains pattern (string or regexp)"
  (define content (file->string path))
  (cond
    [(string? pattern) (string-contains? content pattern)]
    [(regexp? pattern) (regexp-match? pattern content)]
    [else (error "pattern must be string or regexp")]))

;; Test suites

(test-case "Basic Scaffolding - Project Creation"
  (with-temp-dir
   (λ ()
     (check-equal? (run-scaffolder "TestProject" "Test Author") 0
                   "Scaffolder should exit with code 0")

     (check-true (directory-exists? "TestProject")
                 "Project directory should be created")

     (check-true (file-exists? (build-path "TestProject" "README.md"))
                 "README.md should exist")

     (check-true (file-exists? (build-path "TestProject" "LICENSE"))
                 "LICENSE should exist")

     (check-true (file-exists? (build-path "TestProject" ".gitignore"))
                 ".gitignore should exist")

     (check-true (directory-exists? (build-path "TestProject" "raczotbuild"))
                 "raczotbuild directory should exist")

     (check-true (directory-exists? (build-path "TestProject" "templates"))
                 "templates directory should exist")

     (check-true (directory-exists? (build-path "TestProject" "tests"))
                 "tests directory should exist")

     (check-true (directory-exists? (build-path "TestProject" "examples"))
                 "examples directory should exist"))))

(test-case "Basic Scaffolding - File Content"
  (with-temp-dir
   (λ ()
     (run-scaffolder "ContentTest" "Content Author")

     (define readme-path (build-path "ContentTest" "README.md"))
     (check-true (file-contains? readme-path "ContentTest")
                 "README should contain project name")
     (check-true (file-contains? readme-path "Content Author")
                 "README should contain author name")

     (define license-path (build-path "ContentTest" "LICENSE"))
     (check-true (file-contains? license-path "Content Author")
                 "LICENSE should contain author name")
     (check-true (file-contains? license-path "MIT License")
                 "LICENSE should be MIT")
     (check-true (file-contains? license-path
                                  (number->string (date-year (current-date))))
                 "LICENSE should contain current year"))))

(test-case "Homoiconic Structure - raczotbuild Files"
  (with-temp-dir
   (λ ()
     (run-scaffolder "StructureTest" "Structure Author")

     (define info-path (build-path "StructureTest" "raczotbuild" "info.rkt"))
     (check-true (file-exists? info-path)
                 "info.rkt should exist")

     (check-true (file-contains? info-path "#lang setup/infotab")
                 "info.rkt should have correct lang")
     (check-true (file-contains? info-path "StructureTest")
                 "info.rkt should contain project name")
     (check-true (file-contains? info-path "Structure Author")
                 "info.rkt should contain author name")

     (define main-path (build-path "StructureTest" "raczotbuild" "main.rkt"))
     (check-true (file-exists? main-path)
                 "main.rkt should exist")

     (check-true (file-contains? main-path "#lang racket")
                 "main.rkt should have correct lang")
     (check-true (file-contains? main-path "(provide scaffold")
                 "main.rkt should provide scaffold function")
     (check-true (file-contains? main-path "create-audit")
                 "main.rkt should provide create-audit")
     (check-true (file-contains? main-path "verify-audit")
                 "main.rkt should provide verify-audit"))))

(test-case "Template Generation - JSON Templates"
  (with-temp-dir
   (λ ()
     (run-scaffolder "TemplateTest" "Template Author")

     (define template-path
       (build-path "TemplateTest" "templates" "practitioner.json"))
     (check-true (file-exists? template-path)
                 "practitioner.json template should exist")

     ;; Verify it's valid JSON
     (define template-data
       (call-with-input-file template-path
         (λ (in) (read-json in))))

     (check-true (hash? template-data)
                 "Template should be a JSON object")
     (check-true (hash-has-key? template-data 'version)
                 "Template should have version")
     (check-true (hash-has-key? template-data 'files)
                 "Template should have files")

     (define files (hash-ref template-data 'files))
     (check-true (hash-has-key? files "README.md")
                 "Template should include README.md")

     ;; Check for template variables
     (define readme-content (hash-ref files "README.md"))
     (check-true (string-contains? readme-content "{{ProjectName}}")
                 "Template should contain {{ProjectName}} variable")
     (check-true (string-contains? readme-content "{{AuthorName}}")
                 "Template should contain {{AuthorName}} variable"))))

(test-case "Git Integration - Basic Git Init"
  (with-temp-dir
   (λ ()
     (run-scaffolder "GitTest" "Git Author" "-g")

     (define git-dir (build-path "GitTest" ".git"))
     (check-true (directory-exists? git-dir)
                 "Git repository should be initialized")

     (parameterize ([current-directory "GitTest"])
       ;; Check git log
       (define-values (proc stdout stdin stderr)
         (subprocess #f #f #f (find-executable-path "git")
                    "log" "--oneline"))
       (subprocess-wait proc)
       (check-equal? (subprocess-status proc) 0
                     "Git log should succeed")

       ;; Read first commit message
       (define log-output (port->string stdout))
       (check-true (string-contains? log-output "GitTest")
                   "First commit should mention project name")))))

(test-case "Git Integration - GitHub Workflows"
  (with-temp-dir
   (λ ()
     (run-scaffolder "WorkflowTest" "Workflow Author" "-g")

     (define workflow-path
       (build-path "WorkflowTest" ".github" "workflows" "ci.yml"))
     (check-true (file-exists? workflow-path)
                 "CI workflow should be created")

     (check-true (file-contains? workflow-path "name: CI")
                 "Workflow should have correct name")
     (check-true (file-contains? workflow-path "racket")
                 "Workflow should mention racket")
     (check-true (file-contains? workflow-path "raco test")
                 "Workflow should run tests"))))

(test-case "Git Integration - .gitignore Content"
  (with-temp-dir
   (λ ()
     (run-scaffolder "IgnoreTest" "Ignore Author")

     (define gitignore-path (build-path "IgnoreTest" ".gitignore"))
     (check-true (file-exists? gitignore-path)
                 ".gitignore should exist")

     (check-true (file-contains? gitignore-path "_build/")
                 ".gitignore should ignore _build")
     (check-true (file-contains? gitignore-path "deps/")
                 ".gitignore should ignore deps")
     (check-true (file-contains? gitignore-path ".zo")
                 ".gitignore should ignore compiled files")
     (check-true (file-contains? gitignore-path "audit-index.json")
                 ".gitignore should ignore audit files"))))

(test-case "Git Integration - .gitattributes"
  (with-temp-dir
   (λ ()
     (run-scaffolder "AttribTest" "Attrib Author")

     (define gitattributes-path (build-path "AttribTest" ".gitattributes"))
     (check-true (file-exists? gitattributes-path)
                 ".gitattributes should exist")

     (check-true (file-contains? gitattributes-path ".rkt text")
                 ".gitattributes should mark .rkt as text")
     (check-true (file-contains? gitattributes-path ".json text")
                 ".gitattributes should mark .json as text"))))

(test-case "Tests Directory - Structure"
  (with-temp-dir
   (λ ()
     (run-scaffolder "TestStructure" "Test Author")

     (define test-file-path
       (build-path "TestStructure" "tests" "main-test.rkt"))
     (check-true (file-exists? test-file-path)
                 "Test file should be created")

     (check-true (file-contains? test-file-path "#lang racket")
                 "Test file should have correct lang")
     (check-true (file-contains? test-file-path "rackunit")
                 "Test file should require rackunit")
     (check-true (file-contains? test-file-path "TODO")
                 "Test file should have TODO for tests"))))

(test-case "Examples Directory - Structure"
  (with-temp-dir
   (λ ()
     (run-scaffolder "ExampleTest" "Example Author")

     (define example-path
       (build-path "ExampleTest" "examples" "run-scaffold.rkt"))
     (check-true (file-exists? example-path)
                 "Example file should be created")

     (check-true (file-contains? example-path "#lang racket")
                 "Example should have correct lang")
     (check-true (file-contains? example-path "(scaffold")
                 "Example should demonstrate scaffold function"))))

(test-case "Error Handling - Missing Required Arguments"
  (with-temp-dir
   (λ ()
     ;; This should fail because -a is required
     (define-values (proc stdout stdin stderr)
       (subprocess #f #f #f
                  (find-executable-path "racket")
                  (build-path (current-directory) ".." "init-raczotbuild.rkt")
                  "-n" "OnlyName"))
     (subprocess-wait proc)
     (check-not-equal? (subprocess-status proc) 0
                       "Should fail without author argument"))))

(test-case "Syntax Validation - Generated Racket Code"
  (with-temp-dir
   (λ ()
     (run-scaffolder "SyntaxTest" "Syntax Author")

     ;; Try to check the syntax of generated files
     (define info-path (build-path "SyntaxTest" "raczotbuild" "info.rkt"))
     (define-values (proc stdout stdin stderr)
       (subprocess #f #f #f
                  (find-executable-path "racket")
                  "-e" (format "(require ~s)" (path->string info-path))))
     (subprocess-wait proc)
     (check-equal? (subprocess-status proc) 0
                   "Generated info.rkt should have valid syntax")

     (define main-path (build-path "SyntaxTest" "raczotbuild" "main.rkt"))
     (define-values (proc2 stdout2 stdin2 stderr2)
       (subprocess #f #f #f
                  (find-executable-path "racket")
                  "-e" (format "(require ~s)" (path->string main-path))))
     (subprocess-wait proc2)
     (check-equal? (subprocess-status proc2) 0
                   "Generated main.rkt should have valid syntax"))))

(test-case "File Permissions - Executable Scripts"
  (when (not (eq? (system-type) 'windows))
    (with-temp-dir
     (λ ()
       (run-scaffolder "PermTest" "Perm Author")

       ;; Check that .rkt files are readable
       (define main-path (build-path "PermTest" "raczotbuild" "main.rkt"))
       (check-true (file-exists? main-path)
                   "File should exist")

       ;; Verify file is readable
       (check-not-exn
        (λ () (file->string main-path))
        "Generated files should be readable")))))

(test-case "Special Characters - Project Name with Spaces"
  (with-temp-dir
   (λ ()
     (run-scaffolder "My Project Name" "Special Author")

     (check-true (directory-exists? "My Project Name")
                 "Should handle spaces in project name")

     (define readme (build-path "My Project Name" "README.md"))
     (check-true (file-contains? readme "My Project Name")
                 "README should contain project name with spaces"))))

(test-case "Special Characters - Author Name with Quotes"
  (with-temp-dir
   (λ ()
     (run-scaffolder "QuoteTest" "O'Brien")

     (define license (build-path "QuoteTest" "LICENSE"))
     (check-true (file-contains? license "O'Brien")
                 "LICENSE should handle quotes in author name"))))

(test-case "Directory Structure - Complete Hierarchy"
  (with-temp-dir
   (λ ()
     (run-scaffolder "FullTest" "Full Author" "-g")

     (define expected-dirs
       '("raczotbuild"
         "templates"
         "tests"
         "examples"
         ".git"
         ".github"
         ".github/workflows"))

     (for ([dir expected-dirs])
       (check-true (directory-exists? (build-path "FullTest" dir))
                   (format "~a directory should exist" dir)))

     (define expected-files
       '("README.md"
         "LICENSE"
         ".gitignore"
         ".gitattributes"
         "raczotbuild/info.rkt"
         "raczotbuild/main.rkt"
         "templates/practitioner.json"
         "tests/main-test.rkt"
         "examples/run-scaffold.rkt"
         ".github/workflows/ci.yml"))

     (for ([file expected-files])
       (check-true (file-exists? (build-path "FullTest" file))
                   (format "~a file should exist" file))))))

(test-case "Template Variables - No Leftover Placeholders"
  (with-temp-dir
   (λ ()
     (run-scaffolder "VarTest" "Variable Author")

     ;; Check that no ~a placeholders remain in generated files
     ;; (these would indicate format strings that weren't expanded)
     (define readme (file->string (build-path "VarTest" "README.md")))
     (check-false (regexp-match? #rx"~a" readme)
                  "README should not contain format placeholders")

     (define license (file->string (build-path "VarTest" "LICENSE")))
     (check-false (regexp-match? #rx"~a" license)
                  "LICENSE should not contain format placeholders"))))

(test-case "Year Substitution - Current Year in LICENSE"
  (with-temp-dir
   (λ ()
     (run-scaffolder "YearTest" "Year Author")

     (define license (file->string (build-path "YearTest" "LICENSE")))
     (define current-year (number->string (date-year (current-date))))

     (check-true (string-contains? license current-year)
                 "LICENSE should contain current year"))))

;; Run all tests
(module+ main
  (displayln "Running Racket scaffolder tests...")
  (displayln "")
  (void))

;; Make tests runnable with 'raco test'
(module+ test
  (void))
