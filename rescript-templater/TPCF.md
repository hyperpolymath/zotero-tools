# TPCF: Tri-Perimeter Contribution Framework

**Project:** Zotero ReScript Templater
**Framework Version:** 1.0
**Last Updated:** 2024-11-22

## Overview

This project uses the **Tri-Perimeter Contribution Framework (TPCF)**, a graduated trust model that balances openness with security. TPCF defines three concentric perimeters of access control, each with clear entry criteria and responsibilities.

## The Three Perimeters

```
┌─────────────────────────────────────────────┐
│         Perimeter 1: Core Team             │
│          (Administrative Access)            │
│  ┌───────────────────────────────────────┐ │
│  │    Perimeter 2: Trusted Contributors  │ │
│  │         (Commit Access)                │ │
│  │  ┌─────────────────────────────────┐  │ │
│  │  │  Perimeter 3: Community Sandbox │  │ │
│  │  │    (Open Contribution)           │  │ │
│  │  └─────────────────────────────────┘  │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Perimeter 3: Community Sandbox

### Purpose
**Open contribution** - Anyone can participate, submit issues, create PRs, and engage in discussions.

### Who Can Access
- **Anyone** with a GitHub account
- No prior approval required
- Anonymous users (read-only)

### What You Can Do
- 📝 Open issues (bug reports, feature requests, questions)
- 💬 Participate in discussions
- 🔀 Submit pull requests
- 📖 Read all public documentation
- 🔍 Review code and provide feedback
- ⭐ Star and watch the repository

### Entry Requirements
None - completely open!

### Responsibilities
- Follow [Code of Conduct](CODE_OF_CONDUCT.md)
- Respect [contributing guidelines](CONTRIBUTING.md)
- Provide constructive feedback
- Test your changes before submitting PRs
- Write clear issue descriptions

### Limitations
- Cannot merge PRs (must be reviewed by Perimeter 2)
- Cannot create releases
- Cannot modify CI/CD pipelines
- Cannot access security advisories
- Cannot manage repository settings

### How to Contribute
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
5. Respond to review feedback

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Graduation to Perimeter 2
Show sustained involvement and quality contributions:
- 10+ merged PRs of substantial quality
- 6+ months of active participation
- Technical competence demonstrated
- Good judgment in reviews and discussions
- Endorsement by existing Perimeter 2 maintainer

## Perimeter 2: Trusted Contributors

### Purpose
**Commit access** - Trusted community members who can merge PRs, triage issues, and participate in project governance.

### Who Has Access
See [MAINTAINERS.md](MAINTAINERS.md) for current list.

### What You Can Do
- ✅ Merge pull requests (after review)
- 🏷️ Manage issues (labels, milestones, assignment)
- 📦 Create pre-releases (non-production)
- 🔧 Modify CI/CD workflows (with peer review)
- 💬 Participate in governance discussions
- 👥 Mentor Perimeter 3 contributors
- 🔍 Review security reports (non-critical)

### Entry Requirements
- 10+ merged PRs demonstrating technical skill
- 6+ months of consistent contribution
- Deep understanding of at least one major component:
  - PowerShell scaffolder
  - Racket scaffolder
  - Bash scaffolder
  - Template system
  - Testing infrastructure
  - CI/CD pipelines
- Demonstrated good judgment in code reviews
- Endorsement by existing Perimeter 2 maintainer
- Community vote (simple majority)

### Responsibilities
- **Code review**: Review PRs within 7 days
- **Issue triage**: Label and respond to issues within 3 days
- **Mentorship**: Help Perimeter 3 contributors
- **Quality**: Ensure CI passes before merging
- **Communication**: Participate in discussions respectfully
- **Documentation**: Keep docs up-to-date
- **Testing**: Verify changes work across platforms

### Accountability
- Reviews auditable in git history
- Annual activity check (6 months inactivity → emeritus status)
- Can be removed for Code of Conduct violations (2/3 vote)
- Expected to self-recuse from reviews where conflict of interest

### How to Become a Perimeter 2 Contributor
1. Contribute regularly for 6+ months
2. Earn trust through quality work
3. Get nominated by existing Perimeter 2 member
4. Accept nomination publicly
5. 1-week comment period for feedback
6. Simple majority vote by existing Perimeter 2

See [MAINTAINERS.md](MAINTAINERS.md) for detailed process.

### Graduation to Perimeter 1
Demonstrate long-term leadership:
- 12+ months as Perimeter 2 maintainer
- Broad expertise across multiple components
- Community leadership and stewardship
- Unanimous approval by Perimeter 1 members

## Perimeter 1: Core Team

### Purpose
**Administrative access** - Long-term project leadership with full repository privileges.

### Who Has Access
See [MAINTAINERS.md](MAINTAINERS.md) for current core team.

### What You Can Do
- 🚀 Create official releases
- 🔐 Manage GitHub repository settings
- 🔒 Handle critical security vulnerabilities
- 📦 Publish to package registries (PSGallery, Racket catalog)
- 👥 Add/remove Perimeter 2 maintainers
- ⚖️ Make final decisions on disputes
- 🏛️ Update governance documents (with vote)
- 💰 Manage funding and sponsorships (if applicable)

### Entry Requirements
- 12+ months as active Perimeter 2 maintainer
- Demonstrated long-term commitment
- Deep technical expertise across project
- Community trust and leadership
- Unanimous approval by existing Perimeter 1 members

### Responsibilities
- **Releases**: Cut releases following semantic versioning
- **Security**: Coordinate vulnerability response per [SECURITY.md](SECURITY.md)
- **Governance**: Make final decisions on contentious issues
- **Onboarding**: Mentor new Perimeter 2 maintainers
- **Infrastructure**: Maintain CI/CD, packages, deployments
- **Community**: Represent project professionally
- **Succession**: Plan for leadership continuity

### Accountability
- All actions logged and auditable
- Requires unanimous vote for major changes:
  - Governance model updates
  - License changes
  - Repository ownership transfer
  - Adding new Perimeter 1 members
- Can be removed for serious CoC violations (unanimous vote minus accused)
- Expected to delegate when conflicts of interest arise

### How to Become a Core Team Member
This is rare and requires:
1. 12+ months of exceptional Perimeter 2 service
2. Nomination by existing Perimeter 1 member
3. Demonstration of:
   - Technical mastery
   - Community leadership
   - Long-term commitment
   - Mature judgment
4. Unanimous approval by all Perimeter 1 members
5. Acceptance of increased responsibility

## Security Perimeter Mapping

| Security Level | TPCF Perimeter | Access | Vulnerability Handling |
|----------------|----------------|--------|------------------------|
| Public | Perimeter 3 | Read-only | Can report via SECURITY.md |
| Low | Perimeter 3 | Submit PRs | Informed after public disclosure |
| Medium | Perimeter 2 | Triage/Merge | Informed after patch ready |
| High | Perimeter 1 | Full admin | Coordinate response |
| Critical | Perimeter 1 | Full admin | Immediate notification |

## Decision-Making Process

### Lazy Consensus (Default)
1. Proposal made (issue, PR, discussion)
2. 72-hour review period
3. If no objections → approved
4. If objections → discussion continues

**Applies to:**
- Most pull requests
- Minor documentation changes
- Bug fixes
- Feature additions (non-breaking)

### Voting (When Needed)
1. Vote called by any Perimeter 2+ member
2. 1-week voting period
3. Simple majority (>50%) required
4. Lead maintainer has tie-breaking vote

**Requires voting:**
- Adding/removing Perimeter 2 maintainers
- Major architectural changes
- Breaking changes
- License modifications
- Code of Conduct updates
- Governance changes

### Unanimous Consent
**Requires unanimous approval:**
- Adding Perimeter 1 members
- Repository ownership transfer
- Fundamental project direction changes

## Movement Between Perimeters

### Promotion Path
```
Perimeter 3 → Perimeter 2:
  Criteria: 10+ PRs, 6+ months, nomination + vote
  Process: Public nomination, 1-week comment, majority vote

Perimeter 2 → Perimeter 1:
  Criteria: 12+ months P2, broad expertise, leadership
  Process: Nomination, demonstration, unanimous vote
```

### Demotion/Removal
```
Inactive (6+ months):
  Process: Attempt contact, move to emeritus after 1 month

Code of Conduct Violation:
  Perimeter 3: Remove access (immediate for severe violations)
  Perimeter 2: 2/3 vote required
  Perimeter 1: Unanimous vote (minus accused)

Voluntary:
  Any member can request to step down at any time
```

## Perimeter Statistics (Current)

| Perimeter | Members | PRs/Month | Reviews/Week | Response Time |
|-----------|---------|-----------|--------------|---------------|
| 1 | 1 | N/A | N/A | 48 hours |
| 2 | 0 | N/A | N/A | 7 days |
| 3 | Open | Variable | N/A | Best effort |

## Benefits of TPCF

### For Contributors (Perimeter 3)
- ✅ Clear path to increased responsibility
- ✅ Low barrier to entry
- ✅ Transparent governance
- ✅ Recognition for contributions

### For Maintainers (Perimeter 2)
- ✅ Distributed workload
- ✅ Reduced burnout
- ✅ Community ownership
- ✅ Succession planning

### For Core Team (Perimeter 1)
- ✅ Focus on strategy
- ✅ Trust-but-verify model
- ✅ Sustainable governance
- ✅ Protected critical resources

### For the Project
- ✅ Sustainable growth
- ✅ Community resilience
- ✅ Quality maintenance
- ✅ Security by design

## TPCF vs. Traditional Models

| Aspect | TPCF | Traditional Open Source | Corporate OSS |
|--------|------|-------------------------|---------------|
| Entry Barrier | Low (P3 open) | Variable | Often high |
| Trust Model | Graduated | Binary (contributor/maintainer) | Employment-based |
| Scalability | High | Medium | Low |
| Sustainability | High | Variable | Tied to sponsor |
| Community Ownership | Shared | Maintainer-centric | Company-centric |
| Security | Layered | Variable | Centralized |

## Implementation Notes

### For This Project
- **Current State**: Perimeter 3 (Community Sandbox) fully operational
- **Next Milestone**: Recruit first Perimeter 2 maintainers
- **Long-term Goal**: Build sustainable multi-perimeter team

### Tooling
- GitHub permissions match perimeters:
  - P3: No special permissions (default)
  - P2: Write access (can merge PRs)
  - P1: Admin access (full control)
- Branch protection enforces review requirements
- CODEOWNERS file maps to perimeters (to be added)

### Monitoring
- Monthly review of perimeter composition
- Annual audit of access levels
- Regular contributor recognition
- Transparency reports in CHANGELOG

## Questions?

- **General questions**: Open a [Discussion](https://github.com/Hyperpolymath/zotero-rescript-templater/discussions)
- **Become a contributor**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Become a maintainer**: See [MAINTAINERS.md](MAINTAINERS.md)
- **Security concerns**: See [SECURITY.md](SECURITY.md)

## Further Reading

- [MAINTAINERS.md](MAINTAINERS.md) - Detailed maintainer responsibilities
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) - Community standards
- [RSR_COMPLIANCE.md](RSR_COMPLIANCE.md) - RSR framework alignment

---

*The TPCF model is inspired by the Rhodium Standard Repository framework and adapted for this project's needs.*

**Version:** 1.0
**License:** Same as project (AGPL-3.0)
**Changes:** This document can be updated via PR with Perimeter 2 review or Perimeter 1 vote for major changes.
