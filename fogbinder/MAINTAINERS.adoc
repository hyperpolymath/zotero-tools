# Maintainers

This document lists the current maintainers of the Fogbinder project and their responsibilities.

## TPCF Perimeter 1: Core Team

The Core Team has full commit access and makes final decisions on project direction, architecture, and releases.

### Current Maintainers

#### Jonathan (Hyperpolymath)
- **Role:** Creator & Lead Maintainer
- **GitHub:** [@Hyperpolymath](https://github.com/Hyperpolymath)
- **Email:** jonathan@fogbinder.org (FUTURE)
- **Focus Areas:**
  - Overall project vision
  - Philosophical foundations (Wittgenstein, Austin)
  - Architecture decisions
  - Release management
- **Timezone:** GMT (London)
- **Availability:** Best effort (volunteer project)

---

## TPCF Perimeter 2: Extended Team

The Extended Team has elevated privileges including PR review and merge rights. Currently empty - invitations extended based on sustained contributions.

### Becoming an Extended Team Member

**Requirements:**
- 3+ months of consistent, high-quality contributions
- 10+ merged pull requests
- Demonstrated understanding of philosophical foundations
- Adherence to Code of Conduct
- Community engagement (code review, issue triage, discussions)

**Process:**
1. Nominated by existing Core Team member
2. Unanimous approval from Core Team
3. Accept invitation and responsibilities
4. Added to this document

---

## TPCF Perimeter 3: Community Sandbox

All contributors operate here by default. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## Responsibilities

### Core Team (Perimeter 1)

**Decision-Making:**
- ✅ Final say on architecture
- ✅ Approve/reject RFCs
- ✅ Merge pull requests
- ✅ Create releases
- ✅ Manage project roadmap
- ✅ Invite Extended Team members

**Code:**
- ✅ Direct commits to `main` (emergency only)
- ✅ Review and merge PRs
- ✅ Maintain CI/CD
- ✅ Security response

**Community:**
- ✅ Enforce Code of Conduct
- ✅ Moderate discussions
- ✅ Mentor contributors
- ✅ Represent project publicly

**Time Commitment:**
- ~5-10 hours/week (volunteer)
- Best effort availability
- Communicate absences

### Extended Team (Perimeter 2)

**Code:**
- ✅ Review pull requests
- ✅ Merge approved PRs
- ✅ Triage issues
- ✅ Maintain documentation

**Community:**
- ✅ Answer questions
- ✅ Help new contributors
- ✅ Participate in roadmap discussions

**Limitations:**
- ❌ Cannot create releases
- ❌ Cannot change core architecture without approval
- ❌ Cannot invite new Extended Team members

**Time Commitment:**
- ~3-5 hours/week (volunteer)
- Best effort availability

---

## Decision-Making Process

### Standard Decisions (Day-to-Day)

**Examples:**
- Merging standard PRs
- Triaging issues
- Answering questions

**Process:**
- Any Core/Extended Team member can act
- No formal approval needed
- Communicate in relevant thread

### Significant Decisions

**Examples:**
- New features affecting architecture
- Breaking changes
- Adding major dependencies
- Changing philosophical approach

**Process:**
1. Open RFC (Request for Comments) issue
2. Discussion period (minimum 1 week)
3. Core Team vote (majority required)
4. Document decision in CHANGELOG.md

### Critical Decisions

**Examples:**
- Changing license
- Adding Perimeter 1 members
- Major version releases
- Project governance changes

**Process:**
1. Open RFC with detailed proposal
2. Extended discussion period (minimum 2 weeks)
3. Core Team unanimous approval required
4. Community comment period (1 week)
5. Final decision and announcement

---

## Conflict Resolution

### Technical Disagreements

1. **Discussion:** Try to reach consensus through discussion
2. **RFC:** If stuck, create formal RFC
3. **Vote:** Core Team votes if consensus impossible
4. **Binding:** Decision is binding once made
5. **Revisit:** Can be revisited with new evidence

### Interpersonal Conflicts

1. **Private:** Try to resolve privately first
2. **Mediation:** Involve neutral Core Team member
3. **Code of Conduct:** Escalate to CoC enforcement if needed

### Philosophical Disagreements

Fogbinder has strong philosophical commitments (late Wittgenstein, J.L. Austin). If you fundamentally disagree:

1. **Fork:** Fogbinder is AGPLv3 - you can fork
2. **Propose:** Submit RFC for architectural alternatives
3. **Accept:** Understand Core Team has final say

**We value intellectual disagreement but require alignment on core principles.**

---

## Stepping Down

Maintainers can step down at any time by:

1. Notifying other Core Team members
2. Updating this document
3. Transferring active responsibilities
4. Optional: Stay on as Emeritus

### Emeritus Maintainers

Former maintainers who have stepped down but remain honored contributors:

- _None yet_

---

## Inactive Maintainers

If a maintainer is inactive for 6+ months without communication:

1. Attempt contact (email, GitHub)
2. If no response after 30 days, mark as inactive
3. Remove commit access (can be restored upon return)
4. Document in this file

**Currently:** All maintainers active (project is new)

---

## Adding New Maintainers

### Perimeter 1 (Core Team)

**Criteria:**
- 12+ months of Extended Team membership
- Deep understanding of philosophical foundations
- Significant architectural contributions
- Community leadership
- Unanimous approval from existing Core Team

**Process:**
1. Nomination by Core Team member
2. Private discussion among Core Team
3. Unanimous vote required
4. Formal invitation
5. Public announcement
6. Update this document

### Perimeter 2 (Extended Team)

See "Becoming an Extended Team Member" above.

---

## Communication

### Internal (Core Team)

- **Channel:** Private GitHub repository / email
- **Frequency:** As needed
- **Decisions:** Documented in public issues

### With Extended Team

- **Channel:** Private GitHub team mentions
- **Frequency:** Weekly updates
- **Topics:** Roadmap, releases, significant decisions

### With Community

- **Channel:** Public GitHub issues, discussions
- **Frequency:** Continuous
- **Transparency:** All decisions documented publicly

---

## Release Process

See [RELEASING.md](RELEASING.md) (FUTURE) for detailed release process.

**TL;DR:**
1. Core Team member creates release branch
2. Update CHANGELOG.md
3. Bump version (semver)
4. Tag release
5. Build and test
6. Publish (npm, GitHub releases)
7. Announce (GitHub discussions, social media)

**Release authority:** Core Team only

---

## Security Response

See [SECURITY.md](SECURITY.md) for public security policy.

**Internal process:**
1. Security report received (private)
2. Core Team notified immediately
3. Assessment within 24-48 hours
4. Fix developed privately
5. Coordinated disclosure
6. Public announcement

**Security authority:** Core Team only

---

## Code of Conduct Enforcement

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for public CoC.

**Enforcement team:**
- All Core Team members
- Extended Team members can report/flag but not enforce

**Process:**
1. Report received
2. Investigation (confidential)
3. Decision by uninvolved Core Team members
4. Action taken (warning, ban, etc.)
5. Documented privately
6. Appeals process available

---

## Acknowledgments

### Special Thanks

This project builds on the shoulders of giants:

- **Ludwig Wittgenstein** - Philosophical foundations (Philosophical Investigations)
- **J.L. Austin** - Speech act theory (How to Do Things With Words)
- **Zotero Team** - Citation management platform
- **ReScript Community** - Type-safe functional programming
- **Deno Team** - Secure JavaScript runtime

### Contributors

All contributors are listed in [CONTRIBUTORS.md](CONTRIBUTORS.md) (auto-generated).

---

## Contact

- **General:** Open a GitHub Discussion
- **Maintainer questions:** Email maintainer directly (see above)
- **Private matters:** jonathan@fogbinder.org (FUTURE)
- **Security:** See [SECURITY.md](SECURITY.md)
- **CoC violations:** See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

---

**Last Updated:** 2025-11-22
**Version:** 0.1.0
**License:** GNU AGPLv3
