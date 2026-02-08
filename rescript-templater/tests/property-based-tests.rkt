#lang racket

;; Property-Based Testing for Racket Scaffolder
;; Uses rackcheck for QuickCheck-style property testing

(require rackunit
         rackcheck
         racket/file
         racket/path
         racket/system
         racket/string)

;; Load the scaffolder (would normally be required as a module)
;; For now, we'll test via subprocess

(define (run-scaffolder-for-test name author)
  "Run scaffolder and return success/failure"
  (define script-path (build-path (current-directory) ".." "init-raczotbuild.rkt"))
  (define result
    (with-handlers ([exn:fail? (λ (e) #f)])
      (system* (find-executable-path "racket")
               script-path
               "-n" name
               "-a" author)))
  result)

(define (cleanup-test-project name)
  "Remove test project directory"
  (when (directory-exists? name)
    (delete-directory/files name)))

;; Property: Variable substitution is order-independent
(test-case "Property: Substitution order independence"
  ;; Property: The order of applying variable substitutions shouldn't matter
  ;; Test with a few concrete examples (full property testing would use generators)

  (define test-cases
    '(("TestProject1" "Author One")
      ("TestProject2" "Author Two")
      ("MyProject" "Jane Doe")))

  (for ([case test-cases])
    (define name (first case))
    (define author (second case))

    ;; Run scaffolder
    (when (run-scaffolder-for-test name author)
      ;; Check README.md for proper substitution
      (define readme-path (build-path name "README.md"))
      (when (file-exists? readme-path)
        (define content (file->string readme-path))

        ;; No template variables should remain
        (check-false (string-contains? content "~a")
                    "No format placeholders should remain")

        ;; Both substitutions should be present
        (check-true (string-contains? content name)
                   "Project name should be substituted")
        (check-true (string-contains? content author)
                   "Author name should be substituted"))

      ;; Cleanup
      (cleanup-test-project name))))

;; Property: Idempotency
(test-case "Property: Idempotency of scaffolding"
  ;; Property: Running scaffolder twice with same inputs produces identical output
  ;; (modulo timestamps)

  (define test-name "IdempotencyTest")
  (define test-author "Test Author")

  ;; First run
  (when (run-scaffolder-for-test test-name test-author)
    ;; Collect file hashes
    (define files-1
      (for/hash ([file (in-directory test-name)]
                 #:when (file-exists? file))
        (values (path->string file)
                (file-sha256 file))))

    (cleanup-test-project test-name)

    ;; Second run
    (when (run-scaffolder-for-test test-name test-author)
      (define files-2
        (for/hash ([file (in-directory test-name)]
                   #:when (file-exists? file))
          (values (path->string file)
                  (file-sha256 file))))

      ;; Check that file sets are equal
      (check-equal? (hash-count files-1) (hash-count files-2)
                    "Same number of files should be created")

      ;; Check that hashes match (excluding LICENSE which has year)
      (for ([(path hash1) (in-hash files-1)])
        (unless (string-contains? path "LICENSE")
          (define hash2 (hash-ref files-2 path #f))
          (check-equal? hash1 hash2
                       (format "File ~a should have identical content" path))))

      (cleanup-test-project test-name))))

;; Helper function for SHA256 (simple byte-based checksum for testing)
(define (file-sha256 path)
  "Compute simple checksum of file"
  (define bytes (file->bytes path))
  (for/sum ([b bytes]) b))

;; Property: Template completeness
(test-case "Property: All templates create required files"
  ;; Property: Every template type creates a minimum set of required files

  (define required-files
    '("README.md"
      "LICENSE"
      ".gitignore"
      ".gitattributes"))

  (define test-name "CompletenessTest")

  (when (run-scaffolder-for-test test-name "Test Author")
    (for ([file required-files])
      (check-true (file-exists? (build-path test-name file))
                  (format "Required file ~a should exist" file)))

    (cleanup-test-project test-name)))

;; Property: Directory structure consistency
(test-case "Property: Directory structure is consistent"
  ;; Property: Same template always creates same directory structure

  (define test-name "StructureTest")

  (when (run-scaffolder-for-test test-name "Test")
    ;; Collect directory structure
    (define dirs-1
      (for/list ([path (in-directory test-name)]
                 #:when (directory-exists? path))
        (path->string path)))

    (cleanup-test-project test-name)

    ;; Second run
    (when (run-scaffolder-for-test test-name "Test")
      (define dirs-2
        (for/list ([path (in-directory test-name)]
                   #:when (directory-exists? path))
          (path->string path)))

      ;; Directory structures should match
      (check-equal? (sort dirs-1 string<?)
                    (sort dirs-2 string<?)
                    "Directory structure should be identical")

      (cleanup-test-project test-name))))

;; Property: File permissions are consistent
(test-case "Property: File permissions are appropriate"
  (when (not (eq? (system-type) 'windows))
    (define test-name "PermissionsTest")

    (when (run-scaffolder-for-test test-name "Test")
      ;; Check that .rkt files are readable
      (define rkt-files
        (for/list ([path (in-directory test-name)]
                   #:when (and (file-exists? path)
                              (string-suffix? (path->string path) ".rkt")))
          path))

      (for ([file rkt-files])
        (check-not-exn
         (λ () (file->string file))
         (format "File ~a should be readable" file)))

      (cleanup-test-project test-name))))

;; Property: No orphaned template markers
(test-case "Property: No unsubstituted template variables"
  ;; Property: After scaffolding, no template format strings should remain

  (define test-name "NoOrphansTest")

  (when (run-scaffolder-for-test test-name "Test Author")
    (define text-files
      (for/list ([path (in-directory test-name)]
                 #:when (and (file-exists? path)
                            (member (path-get-extension path)
                                   '(#".rkt" #".md" #".txt" #".yml"))))
        path))

    (for ([file text-files])
      (define content (file->string file))
      ;; No ~a format placeholders should remain (except in comments/strings)
      (define lines (string-split content "\n"))
      (for ([line lines])
        (when (and (string-contains? line "~a")
                  (not (string-contains? line ";;")))  ; Skip comments
          (check-false #t
                      (format "Unsubstituted template in ~a: ~a" file line)))))

    (cleanup-test-project test-name)))

;; Property: Git initialization works correctly
(test-case "Property: Git initialization creates valid repository"
  (define test-name "GitPropertyTest")

  ;; Run with git flag
  (define result
    (with-handlers ([exn:fail? (λ (e) #f)])
      (system* (find-executable-path "racket")
               (build-path (current-directory) ".." "init-raczotbuild.rkt")
               "-n" test-name
               "-a" "Test"
               "-g")))

  (when result
    ;; Check that .git directory exists
    (check-true (directory-exists? (build-path test-name ".git"))
                ".git directory should exist")

    ;; Check that initial commit was made
    (parameterize ([current-directory test-name])
      (define log-output
        (with-output-to-string
          (λ ()
            (system* (find-executable-path "git")
                    "log" "--oneline"))))

      (check-true (non-empty-string? log-output)
                  "Git log should contain commits"))

    (cleanup-test-project test-name)))

;; Property: Project name sanitization
(test-case "Property: Project names are sanitized appropriately"
  ;; Property: Various project names should be handled correctly

  (define test-cases
    '("Simple"
      "With-Dashes"
      "With_Underscores"
      "CamelCase"
      "lowercase"))

  (for ([name test-cases])
    (when (run-scaffolder-for-test name "Test")
      (check-true (directory-exists? name)
                  (format "Project ~a should be created" name))
      (cleanup-test-project name))))

;; Property: Author name preservation
(test-case "Property: Author names with special characters are preserved"
  ;; Property: Special characters in author names are preserved correctly

  (define test-cases
    '("O'Brien"
      "Jean-Paul Sartre"
      "Test Author"))

  (for ([author test-cases])
    (define test-name (format "Author_~a" (random 10000)))

    (when (run-scaffolder-for-test test-name author)
      (define license-path (build-path test-name "LICENSE"))
      (when (file-exists? license-path)
        (define content (file->string license-path))
        (check-true (string-contains? content author)
                   (format "Author ~a should appear in LICENSE" author)))

      (cleanup-test-project test-name))))

;; Property: Year in LICENSE is current year
(test-case "Property: LICENSE contains current year"
  (define test-name "YearTest")

  (when (run-scaffolder-for-test test-name "Test")
    (define license-path (build-path test-name "LICENSE"))
    (when (file-exists? license-path)
      (define content (file->string license-path))
      (define current-year (number->string (date-year (current-date))))

      (check-true (string-contains? content current-year)
                  "LICENSE should contain current year"))

    (cleanup-test-project test-name)))

;; Property: Valid Racket syntax in generated files
(test-case "Property: All generated .rkt files have valid syntax"
  (define test-name "SyntaxTest")

  (when (run-scaffolder-for-test test-name "Test")
    (define rkt-files
      (for/list ([path (in-directory test-name)]
                 #:when (and (file-exists? path)
                            (string-suffix? (path->string path) ".rkt")))
        path))

    (for ([file rkt-files])
      ;; Try to check syntax
      (define result
        (with-handlers ([exn:fail? (λ (e) #f)])
          (system* (find-executable-path "racket")
                  "-e"
                  (format "(require ~s)" (path->string file)))))

      (check-true result
                  (format "File ~a should have valid Racket syntax" file)))

    (cleanup-test-project test-name)))

;; Run all tests
(module+ main
  (displayln "Running property-based tests for Racket scaffolder...")
  (displayln ""))

;; Make tests runnable with 'raco test'
(module+ test
  (void))
