# Tri-Perimeter Contribution Framework (TPCF)

## Overview

The Tri-Perimeter Contribution Framework (TPCF) is a graduated trust model for managing contributions to open-source projects. It provides clear boundaries and expectations for contributors while maintaining project quality and security.

## Current Perimeter

**NSAI is currently operating at: Perimeter 3 (Community Sandbox)**

This means: **Fully open contribution** - All contributors are welcome!

## The Three Perimeters

### Perimeter 1: Core Team (Inner Circle)

**Access Level**: Full repository access, merge rights, release authority

**Who**: Trusted maintainers with deep project knowledge

**Responsibilities**:
- Review and merge pull requests
- Manage releases and versioning
- Handle security issues
- Set project direction
- Mentor contributors

**Requirements**:
- 6+ months of sustained contribution
- Deep understanding of Tractarian philosophy
- Track record of high-quality code
- Commitment to project values

**Current Members**:
- Hyperpolymath (Lead Maintainer)

### Perimeter 2: Trusted Contributors (Middle Circle)

**Access Level**: Priority review, direct commits to development branch

**Who**: Regular contributors with proven track record

**Responsibilities**:
- Contribute features and fixes
- Review others' pull requests
- Improve documentation
- Help with issue triage

**Requirements**:
- 3+ months of contribution
- Understanding of project architecture
- Multiple accepted pull requests
- Adherence to coding standards

**Current Members**: *(None yet - project is new)*

### Perimeter 3: Community Sandbox (Outer Circle)

**Access Level**: Fork, submit pull requests, report issues

**Who**: Anyone interested in contributing

**Responsibilities**:
- Report bugs
- Submit pull requests
- Improve documentation
- Participate in discussions

**Requirements**:
- Follow Code of Conduct
- Read CONTRIBUTING.md
- Respect review feedback

**Current Members**: **Open to all**

## How TPCF Works

### 1. Starting Out (Perimeter 3)

Everyone starts here:

```
Fork → Clone → Branch → Code → Test → PR → Review → Merge
```

**What you can do**:
- Report issues
- Submit PRs (with review)
- Improve docs
- Add tests
- Fix bugs

**Limitations**:
- Cannot merge directly
- Cannot create releases
- Cannot access security reports

### 2. Building Trust (Path to Perimeter 2)

After sustained quality contributions:

**Indicators**:
- ✅ 5+ merged PRs
- ✅ 3+ months active
- ✅ Helpful code reviews
- ✅ Good communication
- ✅ Philosophy alignment

**Process**:
1. Maintainer nominates contributor
2. Discussion among Perimeter 1
3. Invitation extended
4. Accept and receive access

### 3. Core Team (Path to Perimeter 1)

After significant long-term contribution:

**Indicators**:
- ✅ 10+ merged PRs
- ✅ 6+ months active
- ✅ Major features delivered
- ✅ Mentoring others
- ✅ Philosophy stewardship

**Process**:
1. Consensus among existing Perimeter 1
2. Formal invitation
3. Onboarding with responsibilities

## Philosophical Alignment

### Why TPCF for NSAI?

NSAI's Tractarian foundation requires careful stewardship:

1. **Formal Validation**: Contributors must understand validation vs. semantic truth
2. **Certainty Boundary**: Know what NSAI can/cannot do
3. **Fogbinder Handoff**: Respect the complementarity
4. **Type Safety**: Maintain strict TypeScript standards

TPCF ensures:
- **Quality** through graduated trust
- **Security** through access control
- **Philosophy** through careful onboarding
- **Community** through clear expectations

## Moving Between Perimeters

### Promotion

**Happens organically** based on:
- Contribution quality and quantity
- Communication and collaboration
- Understanding of project philosophy
- Alignment with project values

**Never based on**:
- Time alone
- Personal relationships
- External status

### Demotion

Rare, but possible if:
- Extended inactivity (6+ months)
- Repeated Code of Conduct violations
- Security breaches
- Loss of philosophical alignment

**Process**:
1. Private conversation
2. Opportunity to address concerns
3. Formal decision by Perimeter 1
4. Respectful transition

## Benefits of TPCF

### For the Project

- **Quality Control**: Maintain high standards
- **Security**: Limit access to sensitive areas
- **Sustainability**: Clear succession planning
- **Philosophy**: Preserve Tractarian foundations

### For Contributors

- **Clear Path**: Know how to progress
- **Fair Process**: Transparent criteria
- **Recognition**: Visible trust levels
- **Safety**: Work within appropriate boundaries

## Special Roles

### Security Researcher (Cross-Perimeter)

**Special access**: Can report vulnerabilities privately

**Requirements**:
- Follow coordinated disclosure (see SECURITY.md)
- 90-day disclosure timeline
- Respect embargo

**Any perimeter can**:
- Report security issues
- Get credited for findings

### Documentation Expert (Cross-Perimeter)

**Special focus**: Can contribute docs at any level

**Encouraged**:
- Improve clarity
- Fix errors
- Add examples
- Translate (future)

### Accessibility Advocate (Cross-Perimeter)

**Special focus**: Can improve accessibility at any level

**Valued contributions**:
- ARIA improvements
- Keyboard navigation
- Screen reader support
- WCAG compliance

## Current Trust Model

```
┌─────────────────────────────────────┐
│                                     │
│  Perimeter 3: Community Sandbox     │
│  (Everyone - Open Contribution)     │
│                                     │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │ Perimeter 2: Trusted          │  │
│  │ (None yet)                    │  │
│  │                               │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │                         │  │  │
│  │  │ Perimeter 1: Core       │  │  │
│  │  │ (Hyperpolymath)         │  │  │
│  │  │                         │  │  │
│  │  └─────────────────────────┘  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Getting Started

### New Contributors (Perimeter 3)

1. **Read**:
   - README.md
   - PHILOSOPHY.md
   - CONTRIBUTING.md
   - CODE_OF_CONDUCT.md

2. **Explore**:
   - Browse open issues
   - Read the code
   - Run the tests
   - Understand the Tractarian approach

3. **Contribute**:
   - Pick a "good first issue"
   - Fork and create a branch
   - Make your changes
   - Submit a PR
   - Respond to review feedback

4. **Engage**:
   - Join discussions
   - Help others
   - Share ideas
   - Ask questions

### Questions?

- **About TPCF**: Open a discussion
- **About your perimeter**: Ask maintainers
- **About promotion**: It happens naturally - just keep contributing!

## Examples

### Perimeter 3 → 2 Journey

**Timeline**: 4 months

1. **Month 1**: First PR (docs fix)
2. **Month 2**: Bug fix PR, helped with issue triage
3. **Month 3**: Feature PR (new validation rule), reviewed 2 PRs
4. **Month 4**: Major refactoring, mentored new contributor
5. **Result**: Invited to Perimeter 2

### Perimeter 2 → 1 Journey

**Timeline**: 8 months

1. **Months 1-3**: Regular PRs, reviews, issue triage
2. **Months 4-6**: Major features, architecture discussions
3. **Months 7-8**: Security fix, release management, philosophy docs
4. **Result**: Invited to Perimeter 1

## Philosophy Note

TPCF embodies Tractarian principles:

- **Clear boundaries** (what can be said clearly)
- **Graduated trust** (logical progression)
- **Explicit criteria** (formal verification)
- **Transparency** (no hidden requirements)

Just as NSAI validates what can be validated and hands off uncertainty to Fogbinder, TPCF provides certainty about contribution expectations while allowing organic growth into trusted roles.

---

**"What can be contributed clearly, can be merged. What requires deeper trust, requires deeper engagement."**
