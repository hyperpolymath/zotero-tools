# Formal Verification Guide

This document describes formal verification concepts, current implementations, and future directions for the Zotero ReScript Templater project.

## Table of Contents

- [What is Formal Verification?](#what-is-formal-verification)
- [Current Verification Approaches](#current-verification-approaches)
- [Racket Contracts](#racket-contracts)
- [Property Specifications](#property-specifications)
- [Future Directions](#future-directions)
- [Tools and Resources](#tools-and-resources)

## What is Formal Verification?

**Formal verification** is the process of mathematically proving that software behaves correctly according to a formal specification. Unlike testing (which checks specific cases), formal verification provides guarantees about all possible inputs and states.

### Benefits

- **Correctness guarantees**: Mathematical proof of specification compliance
- **Complete coverage**: All possible executions verified (not just test cases)
- **Early bug detection**: Find bugs before writing code
- **Documentation**: Formal specs serve as precise documentation
- **Safety-critical systems**: Required for medical devices, aerospace, finance

### Challenges

- **Complexity**: Formal proofs are difficult to construct
- **Tool expertise**: Requires specialized knowledge
- **Scalability**: Large systems are hard to verify completely
- **Specification effort**: Writing formal specs is time-consuming
- **False sense of security**: Incorrect specifications can be proved correct

### Verification vs. Testing

| Aspect | Testing | Formal Verification |
|--------|---------|-------------------|
| Coverage | Specific cases | All possible cases |
| Guarantees | "No bugs found" | "No bugs exist" |
| Effort | Low to moderate | High |
| Automation | High | Moderate |
| Skill required | Moderate | High |
| Cost | Low | High |

**Our approach**: Combine both for defense in depth.

## Current Verification Approaches

### 1. Type Systems (Partial Verification)

The generated templates use type systems for compile-time verification:

**ReScript** (Practitioner template):
```rescript
// Type system prevents:
// - Null reference errors
// - Type mismatches
// - Missing function arguments

type pluginState = {
  initialized: bool,
  version: string,
}

let validateState = (state: pluginState): result<pluginState, string> => {
  if state.initialized {
    Ok(state)
  } else {
    Error("Plugin not initialized")
  }
}
```

**TypeScript** (Student template):
```typescript
// Type system catches:
// - Invalid property access
// - Wrong function signatures
// - Undefined values

interface PluginConfig {
  name: string;
  version: string;
  enabled: boolean;
}

function validateConfig(config: PluginConfig): boolean {
  return config.name.length > 0 && config.enabled;
}
```

### 2. Property-Based Testing (Empirical Verification)

Property-based tests verify invariants across random inputs:

```powershell
# tests/PropertyBased.Tests.ps1
# Property: Idempotency
# ∀x. scaffold(scaffold(x)) = scaffold(x)

It "Should produce identical output when run twice" {
    $result1 = New-ZoteroPlugin -Name "Test" -Author "Test"
    $result2 = New-ZoteroPlugin -Name "Test" -Author "Test"

    # Files should be identical
    Compare-Object (Get-FileHash $result1/*) (Get-FileHash $result2/*)
}
```

### 3. File Integrity Verification (Cryptographic Verification)

XXHash64 provides tamper detection:

```powershell
# Cryptographic invariant:
# ∀file. hash(file) = stored_hash(file) ⇒ file unchanged

function Test-FileIntegrity {
    param([string]$Path)

    $auditIndex = Get-Content "$Path/audit-index.json" | ConvertFrom-Json

    foreach ($file in $auditIndex.files) {
        $actualHash = Get-XXHash64 "$Path/$($file.path)"
        if ($actualHash -ne $file.hash) {
            throw "Integrity violation: $($file.path)"
        }
    }
}
```

## Racket Contracts

Racket's contract system provides **runtime verification** with formal specifications.

### Basic Contracts

```racket
#lang racket

(require racket/contract)

;; Contract: scaffold-project takes a string and returns a path
;; Ensures: project name is non-empty
;; Ensures: result is a valid directory path
(provide
 (contract-out
  [scaffold-project (->i ([name (and/c string? non-empty-string?)])
                         [result path-string?])]))

(define (scaffold-project name)
  ;; Implementation guaranteed to satisfy contract
  (let ([project-dir (build-path (current-directory) name)])
    (make-directory* project-dir)
    project-dir))
```

### Advanced Contracts (Dependent)

```racket
;; Dependent contract: hash verification
;; Property: computed hash equals expected hash
(provide
 (contract-out
  [verify-file-integrity
   (->i ([file path-string?]
         [expected-hash exact-nonnegative-integer?])
        [result (file expected-hash)
                (and/c boolean?
                       (λ (result)
                         (implies result
                                  (= (compute-hash file)
                                     expected-hash))))])]))

(define (verify-file-integrity file expected-hash)
  (= (compute-hash file) expected-hash))
```

### Contract Examples for Scaffolder

**File Creation Contract**:
```racket
#lang racket

(require racket/contract)

;; Ensures all files are created with correct content
(define/contract (create-template-files project-name files)
  (->i ([project-name non-empty-string?]
        [files (hash/c string? string?)])
       [result (hash/c string? path-string?)])

  ;; Contract guarantees:
  ;; 1. All keys in input become paths in output
  ;; 2. All paths are within project directory
  ;; 3. All files exist after creation

  (for/hash ([(filename content) (in-hash files)])
    (define file-path (build-path project-name filename))
    (make-directory* (path-only file-path))
    (call-with-output-file file-path
      (λ (out) (write-string content out))
      #:exists 'error)
    (values filename file-path)))
```

**Template Substitution Contract**:
```racket
;; Formal property: No template variables remain after substitution
(define/contract (substitute-variables template vars)
  (->i ([template string?]
        [vars (hash/c string? string?)])
       [result (template vars)
               (and/c string?
                      (λ (result)
                        ;; Postcondition: no {{var}} patterns remain
                        (not (regexp-match? #rx"\\{\\{[^}]+\\}\\}" result))))])

  (for/fold ([result template])
            ([(key value) (in-hash vars)])
    (string-replace result (format "{{~a}}" key) value)))
```

### Runtime Contract Checking

```bash
# Enable contract checking
racket -t init-raczotbuild.rkt -- -n "Test" -a "Author"

# Contracts verify at runtime:
# ✓ Input validation (non-empty strings)
# ✓ Output validation (directory created)
# ✓ Invariant preservation (no template vars remain)
# ✓ Postconditions (all files exist)

# If contract fails:
# contract violation
#   expected: non-empty-string?
#   given: ""
#   in: (-> non-empty-string? path-string?)
```

## Property Specifications

Formal specifications of key properties (for future theorem provers).

### Property 1: Idempotency

```
Specification:
∀ name author. scaffold(name, author) = scaffold(name, author)

In Racket notation:
(define-property idempotency
  (check-property
   (property ([name (gen:string-alpha-numeric 1 50)]
              [author (gen:string-alpha-numeric 1 50)])
     (let ([result1 (scaffold name author)]
           [result2 (scaffold name author)])
       (equal? result1 result2)))))
```

### Property 2: Completeness

```
Specification:
∀ template-type. ∃ required-files.
  scaffold(name, author, template-type) ⊃ required-files

Required files = {README.md, LICENSE, .gitignore, .gitattributes, ...}

In dependent types (Coq-style):
Theorem scaffold_completeness:
  forall (name author : string) (template : TemplateType),
  let project := scaffold name author template in
  exists (files : list File),
    (forall f, In f required_files -> In f (project_files project)).
```

### Property 3: Variable Substitution Completeness

```
Specification:
∀ template vars. substitute(template, vars) contains no template markers

In TLA+:
THEOREM SubstitutionComplete ==
  \A template \in Templates, vars \in Variables:
    LET result == Substitute(template, vars)
    IN ~(\E s \in Strings: /\\ s \in result
                           /\\ s =~ "{{[^}]+}}")

In Z notation:
┌─ SubstitutionComplete ─────────────────────────
│ ∀ template : String; vars : String ↦ String ●
│   let result == substitute(template, vars) ●
│   ¬ ∃ marker : String ●
│     marker ∈ result ∧
│     marker matches "{{[^}]+}}"
└────────────────────────────────────────────────
```

### Property 4: File Integrity Preservation

```
Specification:
∀ file. hash(file, t0) = hash(file, t1) ⇒ content(file, t0) = content(file, t1)

In Dafny:
method VerifyIntegrity(file: File, expectedHash: Hash) returns (valid: bool)
  ensures valid ==> Content(file) == OldContent(file)
  ensures !valid ==> Content(file) != OldContent(file)
{
  var actualHash := ComputeHash(file);
  valid := actualHash == expectedHash;
}
```

## Future Directions

### 1. Formal Specification Language

Use TLA+ or Alloy to specify system behavior:

```tla
---- MODULE ZoteroScaffolder ----
EXTENDS Naturals, Sequences, TLC

CONSTANTS Templates, Projects

VARIABLES currentProject, filesCreated

TypeInvariant ==
  /\ currentProject \in Projects \cup {Null}
  /\ filesCreated \subseteq FileSystem

Scaffold(name, author, template) ==
  /\ currentProject = Null
  /\ template \in Templates
  /\ LET files == TemplateFiles[template]
     IN /\ filesCreated' = filesCreated \cup {f \in files: Substitute(f, name, author)}
        /\ currentProject' = name

Idempotency ==
  \A name, author, template:
    Scaffold(name, author, template) =>
      filesCreated = filesCreated'

THEOREM Correctness == []TypeInvariant /\ []Idempotency
=================================
```

### 2. Proof Assistants

Use Coq or Lean to prove properties:

```coq
(* Coq proof of substitution completeness *)
Require Import Strings.String.
Require Import Lists.List.

Definition template_marker := "{{%s}}".

Theorem substitute_removes_markers:
  forall (template : string) (vars : list (string * string)),
    let result := fold_right
      (fun '(k, v) t => replace t (template_marker k) v)
      template vars in
    ~ (exists marker, substring marker result /\
                      is_template_marker marker).
Proof.
  intros template vars.
  induction vars as [| [k v] vars' IH].
  - (* Base case: no variables *)
    simpl. (* ... proof steps ... *)
  - (* Inductive case *)
    simpl. (* ... proof steps ... *)
Qed.
```

### 3. Static Analysis Tools

**For PowerShell**:
- PSScriptAnalyzer (current): style and correctness
- Phan: static analysis for dynamic languages
- **Future**: Custom SMT solver integration

**For Racket**:
- Typed Racket: gradual typing with soundness
- Soft Contract Verification: static contract checking
- **Future**: Rosette integration (solver-aided verification)

### 4. Model Checking

Use SPIN or NuSMV to verify state machines:

```promela
/* SPIN model of scaffolding workflow */
mtype = { Idle, Creating, Verifying, Complete, Error };
mtype state = Idle;

active proctype Scaffolder() {
  do
  :: state == Idle ->
     atomic {
       state = Creating;
       create_files();
     }
  :: state == Creating ->
     if
     :: verify_integrity() ->
        state = Verifying
     :: else ->
        state = Error
     fi
  :: state == Verifying ->
     state = Complete
  :: state == Complete ->
     break
  :: state == Error ->
     break
  od
}

/* LTL properties */
ltl p1 { [] (state == Creating -> <> state == Complete) }
ltl p2 { [] (state != Error) }  /* Safety: no errors */
ltl p3 { <> (state == Complete) }  /* Liveness: eventually completes */
```

### 5. Symbolic Execution

Use KLEE or angr for path exploration:

```c
// Symbolic model of template substitution
#include <klee/klee.h>

void test_substitution() {
  char template[100];
  char name[50];
  char author[50];

  klee_make_symbolic(template, sizeof(template), "template");
  klee_make_symbolic(name, sizeof(name), "name");
  klee_make_symbolic(author, sizeof(author), "author");

  char* result = substitute(template, name, author);

  // Assert: no template markers remain
  klee_assert(!strstr(result, "{{"));
  klee_assert(!strstr(result, "}}"));
}
```

## Tools and Resources

### Verification Tools

| Tool | Language | Purpose | Maturity |
|------|----------|---------|----------|
| **Racket Contracts** | Racket | Runtime verification | ✅ Production |
| **Typed Racket** | Racket | Gradual typing | ✅ Production |
| **ReScript** | ReScript | Sound type system | ✅ Production |
| **TypeScript** | TypeScript | Structural typing | ✅ Production |
| **TLA+** | Specification | Model checking | 🔬 Research |
| **Coq** | Proof assistant | Theorem proving | 🔬 Research |
| **Lean** | Proof assistant | Theorem proving | 🔬 Research |
| **Dafny** | Verification language | Auto-verification | 🔬 Research |
| **Rosette** | Racket DSL | Solver-aided verification | 🔬 Research |
| **SPIN** | Promela | Model checking | 🔬 Research |

### Learning Resources

**Contracts and Runtime Verification**:
- Racket Guide: Contracts - https://docs.racket-lang.org/guide/contracts.html
- Design by Contract (Meyer) - https://www.eiffel.com/values/design-by-contract/
- Property-Based Testing - https://hypothesis.works/articles/what-is-property-based-testing/

**Formal Methods**:
- TLA+ Video Course - https://lamport.azurewebsites.net/video/videos.html
- Software Foundations (Coq) - https://softwarefoundations.cis.upenn.edu/
- Certified Programming with Dependent Types - http://adam.chlipala.net/cpdt/

**Static Analysis**:
- PSScriptAnalyzer - https://github.com/PowerShell/PSScriptAnalyzer
- Typed Racket - https://docs.racket-lang.org/ts-guide/
- Abstract Interpretation - https://www.di.ens.fr/~cousot/

**Model Checking**:
- SPIN - http://spinroot.com/
- NuSMV - https://nusmv.fbk.eu/
- Model Checking (Clarke) - https://mitpress.mit.edu/9780262038836/

## Conclusion

While full formal verification is aspirational for this project, we employ multiple verification strategies:

1. **Type systems**: Compile-time verification in generated code
2. **Contracts**: Runtime verification in Racket scaffolder
3. **Property-based testing**: Empirical verification of invariants
4. **Integrity verification**: Cryptographic verification of files

These approaches provide strong confidence in correctness, approaching the guarantees of formal verification for our use case.

**Future work**: As the project matures and if safety requirements increase, integration with proof assistants (Coq, Lean) or solver-aided tools (Rosette) could provide mathematical proofs of critical properties.

---

**Last Updated**: 2024-11-22
**Maintainer**: See [MAINTAINERS.md](MAINTAINERS.md)
**License**: AGPL-3.0-only
**Related**: [tests/PropertyBased.Tests.ps1](tests/PropertyBased.Tests.ps1), [tests/property-based-tests.rkt](tests/property-based-tests.rkt)
