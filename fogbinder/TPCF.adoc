# Tri-Perimeter Contribution Framework (TPCF)

Fogbinder uses the **Tri-Perimeter Contribution Framework (TPCF)** for graduated trust and access control.

## Overview

TPCF recognizes that **not all contributors need the same level of access**. Instead of binary access control (all or nothing), we have three graduated perimeters with increasing trust and responsibility.

```
┌─────────────────────────────────────────────────┐
│  Perimeter 3: Community Sandbox (Public)        │
│  ┌───────────────────────────────────────────┐  │
│  │  Perimeter 2: Extended Team (Invited)     │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │  Perimeter 1: Core Team (Trusted)   │  │  │
│  │  │                                      │  │  │
│  │  │  - Full access                       │  │  │
│  │  │  - Architecture decisions            │  │  │
│  │  │  - Release authority                 │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  │                                             │  │
│  │  - PR review & merge                        │  │
│  │  - Issue triage                             │  │
│  │  - Elevated privileges                      │  │
│  └───────────────────────────────────────────┘  │
│                                                  │
│  - Fork & PR                                     │
│  - Report issues                                 │
│  - Open contribution                             │
└─────────────────────────────────────────────────┘
```

## Perimeter 3: Community Sandbox

### Who: Everyone

**Default perimeter for all contributors.**

### Access Rights

✅ **Can Do:**
- Fork repository
- Clone and modify locally
- Submit pull requests
- Report issues and bugs
- Participate in discussions
- Suggest features
- Review others' code (informal)
- Use the software (AGPLv3)

❌ **Cannot Do:**
- Direct commits to `main` branch
- Merge pull requests
- Close issues (without maintainer approval)
- Create releases
- Modify GitHub settings
- Access private discussions

### Contribution Process

1. **Fork** repository to your account
2. **Create branch** in your fork
3. **Make changes** with tests and documentation
4. **Submit PR** following [CONTRIBUTING.md](CONTRIBUTING.md)
5. **Wait for review** by Perimeter 1 or 2
6. **Address feedback** if requested
7. **Merge** by maintainer after approval

### Trust Model

- **Zero trust** - All contributions reviewed
- **Earn trust** - Consistent quality → invitation to Perimeter 2
- **Open participation** - Anyone can contribute
- **Transparent** - All activity public

### Time Commitment

**None required** - Contribute at your own pace.

### Example Contributors

- First-time contributors
- Occasional contributors
- Drive-by bug fixers
- Documentation improvers
- Issue reporters

---

## Perimeter 2: Extended Team

### Who: Invited Contributors

**Requires invitation from Perimeter 1 (Core Team).**

### Access Rights

✅ **Can Do (in addition to Perimeter 3):**
- **Triage issues** - Label, prioritize, close duplicates
- **Review pull requests** - Formal code review
- **Merge approved PRs** - After approval from 2+ reviewers
- **Assign reviewers** - Route PRs to appropriate people
- **Edit wiki** - Maintain documentation
- **Manage labels** - Organize issues/PRs
- **Moderate discussions** - Enforce Code of Conduct
- **Participate in roadmap** - Voice in project direction

❌ **Cannot Do (reserved for Perimeter 1):**
- Create releases
- Change core architecture without approval
- Invite new Perimeter 2 members
- Modify security policies
- Access deployment credentials

### Requirements to Join

**Demonstrated track record:**
- ✅ 3+ months of consistent contributions
- ✅ 10+ merged pull requests
- ✅ High-quality code (tests, docs, style)
- ✅ Understanding of philosophical foundations
- ✅ Adherence to Code of Conduct
- ✅ Community engagement (reviews, discussions)

**Process:**
1. Nominated by Perimeter 1 member
2. Unanimous approval from Core Team
3. Accept invitation and responsibilities
4. Added to GitHub team + MAINTAINERS.md

### Responsibilities

- **Code review** - Review PRs within 3 business days
- **Issue triage** - Triage new issues within 1 week
- **Mentorship** - Help Perimeter 3 contributors
- **Communication** - Participate in team discussions
- **Availability** - Best effort (~3-5 hours/week volunteer)

### Trust Model

- **Earned trust** - Proven through contributions
- **Peer review** - Changes still reviewed by others
- **Accountability** - Can be moved back to Perimeter 3 if needed
- **Transparency** - Elevated access, not secrecy

### Example Contributors

- Regular contributors
- Domain experts
- Documentation maintainers
- Community moderators

---

## Perimeter 1: Core Team

### Who: Project Maintainers

**Founders and long-term stewards of the project.**

### Access Rights

✅ **Full Access (in addition to Perimeter 2):**
- **Direct commits to `main`** - Emergency only (still prefer PRs)
- **Create releases** - Tag versions, publish packages
- **Architecture decisions** - Final say on design
- **Invite Perimeter 2 members** - Grow the team
- **Security response** - Handle vulnerability reports
- **Moderate Code of Conduct** - Enforce community standards
- **GitHub admin** - Repository settings, integrations
- **Deployment access** - Production credentials (if applicable)

❌ **Self-Imposed Limitations:**
- **No unilateral breaking changes** - Require RFC + consensus
- **No solo releases** - At least 2 Core members review
- **No CoC self-enforcement** - Uninvolved member handles

### Responsibilities

- **Project vision** - Define long-term direction
- **Code quality** - Maintain high standards
- **Releases** - Coordinate versioning and publishing
- **Security** - Respond to vulnerabilities
- **Community** - Foster healthy, inclusive culture
- **Documentation** - Keep docs accurate and current
- **Availability** - Best effort (~5-10 hours/week volunteer)

### Requirements to Join

**Extremely high bar:**
- ✅ 12+ months of Perimeter 2 membership
- ✅ Deep understanding of philosophical foundations
- ✅ Significant architectural contributions
- ✅ Community leadership
- ✅ Unanimous approval from existing Core Team

**Process:**
1. Nomination by existing Core member
2. Private discussion among Core Team
3. Unanimous vote required
4. Formal invitation
5. Public announcement
6. Update MAINTAINERS.md

### Trust Model

- **Maximum trust** - Full commit access
- **Mutual accountability** - Peer review encouraged
- **Transparent governance** - Decisions documented publicly
- **Stepping down** - Can leave gracefully at any time

### Current Members

See [MAINTAINERS.md](MAINTAINERS.md) for list.

**As of 2025-11-22:**
- Jonathan (Hyperpolymath) - Creator & Lead Maintainer

---

## Security Model

### Perimeter-Based Access Control

| Capability | Perimeter 3 | Perimeter 2 | Perimeter 1 |
|------------|-------------|-------------|-------------|
| Fork repo | ✅ | ✅ | ✅ |
| Submit PR | ✅ | ✅ | ✅ |
| Review PR | Informal | ✅ Formal | ✅ Formal |
| Merge PR | ❌ | ✅ | ✅ |
| Triage issues | ❌ | ✅ | ✅ |
| Create release | ❌ | ❌ | ✅ |
| Commit to `main` | ❌ | ❌ | ✅ Emergency |
| Invite P2 members | ❌ | ❌ | ✅ |
| Admin access | ❌ | ❌ | ✅ |

### Code Review Requirements

**Perimeter 3 PRs:**
- Minimum 2 approvals (Perimeter 1 or 2)
- All tests passing
- CI checks green
- Documentation updated

**Perimeter 2 PRs:**
- Minimum 1 approval (Perimeter 1)
- Encouraged to have 2+ reviews
- Same quality bar

**Perimeter 1 PRs:**
- Peer review encouraged
- Can self-merge for trivial fixes (typos, etc.)
- Complex changes require approval

### Security Response

- **All perimeters** - Can report security vulnerabilities
- **Perimeter 2+** - Can participate in private discussions
- **Perimeter 1 only** - Access to private security repo
- **Perimeter 1 only** - Coordinate disclosure

---

## Movement Between Perimeters

### Graduating to Perimeter 2

**Path:**
1. Consistent contributions for 3+ months
2. Quality meets standards
3. Community engagement
4. Core Team nominates
5. Accept invitation

**No formal application process** - You'll be invited if you qualify.

### Graduating to Perimeter 1

**Path:**
1. 12+ months in Perimeter 2
2. Exceptional contributions
3. Philosophical alignment
4. Community leadership
5. Core Team unanimous approval

**Extremely selective** - Quality over quantity.

### Demotion

**Rare but possible:**

**Perimeter 2 → 3:**
- Violation of Code of Conduct
- Extended inactivity (6+ months without communication)
- Abuse of privileges

**Perimeter 1 → 2:**
- Voluntarily stepping down
- Major governance disagreement
- Extended inactivity (1+ year)

**Process:**
- Private discussion
- Attempt resolution first
- Transparent communication
- Graceful transition

---

## Governance Integration

### Decision-Making by Perimeter

**Standard decisions:**
- **P3:** Propose via issue/PR
- **P2:** Review and merge
- **P1:** Final approval for significant changes

**Architectural decisions:**
- **P3:** Propose via RFC
- **P2:** Participate in discussion
- **P1:** Final vote (majority)

**Critical decisions:**
- **P3:** Community comment period
- **P2:** Advisory role
- **P1:** Unanimous approval required

### RFC (Request for Comments) Process

1. **Proposal** - Anyone (all perimeters) can propose
2. **Discussion** - Minimum 1 week for P3, 2 weeks for critical
3. **Revision** - Incorporate feedback
4. **Vote** - P1 votes (majority or unanimous)
5. **Implementation** - Any perimeter can implement once approved

---

## Comparison to Other Models

### vs. Traditional Open Source

**Traditional:**
- Committers vs. non-committers (binary)
- Sudden jump from outsider to insider
- Unclear path to commit access

**TPCF:**
- Three graduated levels
- Clear criteria at each level
- Transparent progression

### vs. Benevolent Dictator For Life (BDFL)

**BDFL:**
- Single person makes final decisions
- Risk of burnout
- Succession planning unclear

**TPCF:**
- Distributed decision-making
- Sustainable governance
- Clear succession process

### vs. Do-ocracy ("Whoever does the work decides")

**Do-ocracy:**
- Action-oriented
- Can lead to fragmentation
- Quality control challenging

**TPCF:**
- Action + oversight
- Coherent vision maintained
- Quality enforced via review

---

## Philosophy Behind TPCF

### Wittgensteinian Roots

**Language games** - Different perimeters are different "games" with different rules:
- P3: Game of "proposing ideas"
- P2: Game of "curating contributions"
- P1: Game of "stewarding vision"

**Family resemblance** - Contributors share overlapping characteristics, not strict definitions.

### Emotional Safety

**Graduated trust reduces anxiety:**
- P3: Low stakes, experiment freely
- P2: More responsibility, but support from P1
- P1: High stakes, but experienced

**Reversibility:**
- Can step down gracefully
- Can be demoted temporarily
- Not a permanent identity

### Meritocracy with Humility

**Merit matters** - Quality contributions earn trust

**But also:**
- Context matters (life circumstances change)
- Diverse contributions valued (code, docs, community)
- No one is indispensable (bus factor = 0)

---

## FAQ

### Q: How do I know which perimeter I'm in?

**A:**
- If you're reading this for the first time: **Perimeter 3**
- If you've been explicitly invited to team: **Perimeter 2**
- If you're listed in MAINTAINERS.md as Core: **Perimeter 1**

### Q: Can I request to join Perimeter 2?

**A:** No formal application. Just contribute consistently and you'll be invited.

### Q: What if I disagree with a Perimeter 1 decision?

**A:**
1. Open respectful discussion
2. Make your case with evidence
3. Accept final decision if consensus isn't reached
4. Remember: AGPLv3 allows forking

### Q: Can I jump straight to Perimeter 1?

**A:** Extremely rare. Must go through P2 first (with very rare exceptions).

### Q: What happens if all Perimeter 1 members leave?

**A:**
- Perimeter 2 promotes most senior member(s) to P1
- Community elects new leadership if needed
- Documented in GOVERNANCE.md (future)

### Q: Is TPCF bureaucratic?

**A:** No - it's lightweight. Most decisions happen informally. Structure is for clarity, not overhead.

---

## References

- **Concept Origin:** RSR (Rhodium Standard Repository) Framework
- **Inspiration:** Rust community's trust model, Debian's Developer tiers
- **Philosophy:** Late Wittgenstein (language games), gradual epistemology

---

## Contact

Questions about TPCF?
- **General:** Open a GitHub Discussion
- **Private:** Email maintainers (see MAINTAINERS.md)
- **Security:** See SECURITY.md

---

**Last Updated:** 2025-11-22
**Version:** 1.0
**License:** GNU AGPLv3

**The fog is not an obstacle. It's the medium of inquiry.** 🌫️
