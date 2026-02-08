#lang info

;; Package information for Racket package catalog
;; https://pkgs.racket-lang.org/

;; Basic package metadata
(define collection "zotero-rescript-templater")
(define version "0.2.0")

;; Package description
(define pkg-desc
  "Comprehensive scaffolding system for creating Zotero plugins with type-safe, memory-safe, and offline-first architecture")

;; Long description for package catalog
(define pkg-authors
  '("Zotero ReScript Templater Contributors"))

;; Dependencies
(define deps
  '("base"           ; Racket base library
    "rackunit-lib"   ; Testing framework
    "rackcheck"))    ; Property-based testing (QuickCheck for Racket)

;; Build dependencies (for development and testing)
(define build-deps
  '("scribble-lib"   ; Documentation
    "racket-doc"     ; Racket documentation
    "rackunit-doc")) ; Testing documentation

;; Test dependencies
(define test-omit-paths
  '("examples"       ; Example output directories
    "Demo*"))        ; Demo scaffolded projects

;; Scribblings (documentation)
;; Note: Add when Scribble documentation is created
;; (define scribblings
;;   '(("scribblings/zotero-rescript-templater.scrbl" ())))

;; License
(define license 'AGPL-3.0-only)

;; Categories for package catalog
(define categories
  '(devtools
    metaprogramming
    tools))

;; Links
(define project-homepage
  "https://github.com/Hyperpolymath/zotero-rescript-templater")

(define bug-tracker
  "https://github.com/Hyperpolymath/zotero-rescript-templater/issues")

(define repository
  "https://github.com/Hyperpolymath/zotero-rescript-templater.git")

;; Compile omit paths (don't compile these)
(define compile-omit-paths
  '("tests"          ; Test files
    "examples"       ; Examples
    "Demo*"          ; Demo projects
    ".github"        ; GitHub configuration
    ".well-known"))  ; .well-known directory

;; Module suffix for automatic module discovery
;; (define module-suffix ".rkt")

;; Version compatibility
(define racket-launcher-libraries
  '("init-raczotbuild.rkt"))

(define racket-launcher-names
  '("raczotbuild"))

;; Additional metadata for RSR compliance
(define rsr-compliance "platinum")
(define rsr-score "91%")

;; TPCF governance model
(define governance "TPCF")
(define contribution-model "tri-perimeter")

;; Package tags/keywords for discovery
(define tags
  '(zotero
    plugin
    scaffolding
    code-generation
    rescript
    typescript
    template
    rsr
    tpcf
    offline-first
    type-safety
    memory-safety
    ci-cd
    testing
    research
    academia
    cross-platform))

;; Distribution settings
(define dist-name "zotero-rescript-templater")
(define dist-desc "Zotero plugin scaffolder with RSR framework compliance")

;; Package can be installed via:
;;   raco pkg install zotero-rescript-templater
;; Or from git:
;;   raco pkg install git://github.com/Hyperpolymath/zotero-rescript-templater

;; Post-installation message
(define install-platform
  'all) ; Works on all platforms: Windows, Linux, macOS

;; Package update strategy
(define update-implies
  '()) ; No implied updates

;; Package conflicts (none known)
(define conflicts
  '())

;; Package provides
(define provides
  '("zotero-rescript-templater"))

;; Installation notes
;; ==================
;;
;; After installation, the scaffolder can be used via:
;;
;;   racket -l zotero-rescript-templater/init-raczotbuild.rkt -n ProjectName -a "Author Name" [-g]
;;
;; Or if racket-launcher is configured:
;;
;;   raczotbuild -n ProjectName -a "Author Name" [-g]
;;
;; For detailed usage, see:
;;   https://github.com/Hyperpolymath/zotero-rescript-templater/blob/main/README.md
;;
;; To run tests:
;;   raco test tests/
;;
;; To verify property-based tests:
;;   racket tests/property-based-tests.rkt
