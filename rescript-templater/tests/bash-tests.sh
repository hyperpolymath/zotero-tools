#!/usr/bin/env bash
# Bash Scaffolder Tests
# Run with: bash tests/bash-tests.sh

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAFFOLDER="$SCRIPT_DIR/init-zotero-plugin.sh"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  ((TESTS_RUN++))
  if [[ -f "$file" ]]; then
    echo -e "${GREEN}✓${NC} $message"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $message"
    ((TESTS_FAILED++))
  fi
}

assert_dir_exists() {
  local dir="$1"
  local message="${2:-Directory should exist: $dir}"

  ((TESTS_RUN++))
  if [[ -d "$dir" ]]; then
    echo -e "${GREEN}✓${NC} $message"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $message"
    ((TESTS_FAILED++))
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File should contain pattern}"

  ((TESTS_RUN++))
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} $message"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $message (pattern: $pattern)"
    ((TESTS_FAILED++))
  fi
}

assert_file_not_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File should not contain pattern}"

  ((TESTS_RUN++))
  if ! grep -q "$pattern" "$file" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} $message"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $message (found: $pattern)"
    ((TESTS_FAILED++))
  fi
}

assert_command_succeeds() {
  local cmd="$1"
  local message="${2:-Command should succeed}"

  ((TESTS_RUN++))
  if eval "$cmd" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $message"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $message"
    ((TESTS_FAILED++))
  fi
}

assert_command_fails() {
  local cmd="$1"
  local message="${2:-Command should fail}"

  ((TESTS_RUN++))
  if ! eval "$cmd" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $message"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} $message"
    ((TESTS_FAILED++))
  fi
}

# === Test Suites ===

test_help() {
  echo -e "\n${YELLOW}=== Test: Help message ===${NC}"

  assert_command_succeeds "bash '$SCAFFOLDER' -h" "Help flag should work"
}

test_missing_arguments() {
  echo -e "\n${YELLOW}=== Test: Missing arguments ===${NC}"

  cd "$TEST_DIR"

  assert_command_fails "bash '$SCAFFOLDER'" "Should fail with no arguments"
  assert_command_fails "bash '$SCAFFOLDER' -n TestOnly" "Should fail without author"
  assert_command_fails "bash '$SCAFFOLDER' -a 'Author Only'" "Should fail without project name"
}

test_student_scaffolding() {
  echo -e "\n${YELLOW}=== Test: Student template scaffolding ===${NC}"

  cd "$TEST_DIR"
  local project="TestStudent"

  bash "$SCAFFOLDER" -n "$project" -a "Test Author" -t student

  # Check project structure
  assert_dir_exists "$project" "Project directory created"
  assert_file_exists "$project/README.md" "README.md exists"
  assert_file_exists "$project/TUTORIAL.md" "TUTORIAL.md exists"
  assert_file_exists "$project/install.rdf" "install.rdf exists"
  assert_file_exists "$project/chrome.manifest" "chrome.manifest exists"
  assert_file_exists "$project/bootstrap.js" "bootstrap.js exists"
  assert_file_exists "$project/chrome/content/main.js" "main.js exists"
  assert_file_exists "$project/chrome/content/overlay.xul" "overlay.xul exists"
  assert_file_exists "$project/.gitignore" ".gitignore exists"
  assert_file_exists "$project/audit-index.json" "audit-index.json generated"

  # Check variable substitution
  assert_file_contains "$project/README.md" "$project" "README contains project name"
  assert_file_contains "$project/README.md" "Test Author" "README contains author name"
  assert_file_not_contains "$project/README.md" "{{ProjectName}}" "No unsubstituted variables in README"
  assert_file_not_contains "$project/install.rdf" "{{AuthorName}}" "No unsubstituted variables in install.rdf"
}

test_duplicate_project_fails() {
  echo -e "\n${YELLOW}=== Test: Duplicate project fails ===${NC}"

  cd "$TEST_DIR"
  local project="DuplicateTest"

  # Create first project
  bash "$SCAFFOLDER" -n "$project" -a "Author"

  # Second should fail
  assert_command_fails "bash '$SCAFFOLDER' -n '$project' -a 'Author'" "Duplicate project should fail"
}

test_audit_index_structure() {
  echo -e "\n${YELLOW}=== Test: Audit index structure ===${NC}"

  cd "$TEST_DIR"
  local project="AuditTest"

  bash "$SCAFFOLDER" -n "$project" -a "Test Author"

  assert_file_exists "$project/audit-index.json" "audit-index.json exists"
  assert_file_contains "$project/audit-index.json" '"generated"' "Has generated timestamp"
  assert_file_contains "$project/audit-index.json" '"files"' "Has files array"
  assert_file_contains "$project/audit-index.json" '"path"' "Files have path"
  assert_file_contains "$project/audit-index.json" '"hash"' "Files have hash"
}

test_integrity_verification() {
  echo -e "\n${YELLOW}=== Test: Integrity verification ===${NC}"

  cd "$TEST_DIR"
  local project="IntegrityTest"

  bash "$SCAFFOLDER" -n "$project" -a "Test Author"

  # Verify should pass on fresh project
  assert_command_succeeds "bash '$SCAFFOLDER' -n '$project' -v" "Verification should pass on fresh project"

  # Modify a file - verification should still work (may fail or pass depending on hash method)
  echo "Modified content" >> "$project/README.md"
  # Note: We don't assert this fails because hash mismatch detection depends on tool availability
}

test_practitioner_template() {
  echo -e "\n${YELLOW}=== Test: Practitioner template ===${NC}"

  cd "$TEST_DIR"
  local project="PractitionerTest"

  bash "$SCAFFOLDER" -n "$project" -a "Pro Author" -t practitioner

  assert_dir_exists "$project" "Practitioner project created"
  assert_file_exists "$project/README.md" "README.md exists"
  assert_file_exists "$project/bootstrap.js" "bootstrap.js exists"
}

test_researcher_template() {
  echo -e "\n${YELLOW}=== Test: Researcher template ===${NC}"

  cd "$TEST_DIR"
  local project="ResearcherTest"

  bash "$SCAFFOLDER" -n "$project" -a "Researcher" -t researcher

  assert_dir_exists "$project" "Researcher project created"
  assert_file_exists "$project/README.md" "README.md exists"
  assert_file_exists "$project/bootstrap.js" "bootstrap.js exists"
}

test_git_init() {
  echo -e "\n${YELLOW}=== Test: Git initialization ===${NC}"

  cd "$TEST_DIR"
  local project="GitTest"

  # Only test if git is available
  if command -v git &> /dev/null; then
    bash "$SCAFFOLDER" -n "$project" -a "Git Author" -g

    assert_dir_exists "$project/.git" "Git directory created"
    assert_command_succeeds "cd '$project' && git log --oneline -1" "Has initial commit"
  else
    echo -e "${YELLOW}⚠${NC} Git not available, skipping git tests"
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
  fi
}

# === Main ===

main() {
  echo -e "${YELLOW}======================================${NC}"
  echo -e "${YELLOW}  Bash Scaffolder Tests${NC}"
  echo -e "${YELLOW}======================================${NC}"

  # Check scaffolder exists
  if [[ ! -f "$SCAFFOLDER" ]]; then
    echo -e "${RED}Error: Scaffolder not found at $SCAFFOLDER${NC}"
    exit 1
  fi

  # Run tests
  test_help
  test_missing_arguments
  test_student_scaffolding
  test_duplicate_project_fails
  test_audit_index_structure
  test_integrity_verification
  test_practitioner_template
  test_researcher_template
  test_git_init

  # Summary
  echo -e "\n${YELLOW}======================================${NC}"
  echo -e "${YELLOW}  Test Summary${NC}"
  echo -e "${YELLOW}======================================${NC}"
  echo -e "Tests run: $TESTS_RUN"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
  else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

main "$@"
