# Maintainers

This document lists the maintainers of the Zotero ReScript Templater project and describes the governance model.

## Current Maintainers

### Core Maintainers

**Lead Maintainer:**
- Name: Hyperpolymath
- GitHub: @Hyperpolymath
- Role: Project leadership, final decision authority, release management
- Areas: All aspects of the project
- Availability: Best effort

**Maintainer Responsibilities:**
- Review and merge pull requests
- Triage and respond to issues
- Maintain project infrastructure (CI/CD, releases)
- Enforce Code of Conduct
- Guide project direction
- Mentor contributors

## Becoming a Maintainer

We follow the **TPCF (Tri-Perimeter Contribution Framework)** graduated trust model.

### Perimeter 3: Community Sandbox (Open Contribution)

**Who:** Anyone
**Access:** Can submit issues, PRs, discussions
**Process:**
1. Submit quality contributions (code, docs, tests)
2. Follow CONTRIBUTING.md guidelines
3. Demonstrate sustained involvement (3+ months)
4. Show technical competence and judgment

### Perimeter 2: Trusted Contributors (Commit Access)

**Who:** Established contributors
**Access:** Can merge PRs, manage issues, create releases
**Criteria:**
- 10+ merged PRs of substantial quality
- 6+ months of sustained contribution
- Deep understanding of codebase
- Demonstrated good judgment
- Endorsement by existing maintainer(s)

**Process:**
1. Existing maintainer nominates candidate
2. Candidate accepts nomination
3. 1-week comment period for feedback
4. Existing maintainers vote (simple majority)
5. New maintainer added to MAINTAINERS.md

### Perimeter 1: Core Team (Administrative Access)

**Who:** Long-term maintainers
**Access:** GitHub admin, package registry publishing, security advisories
**Criteria:**
- 12+ months as Perimeter 2 maintainer
- Demonstrated leadership and stewardship
- Broad codebase expertise
- Community trust
- Unanimous approval by existing Perimeter 1 members

## Maintainer Duties

### All Maintainers

- **Code Review**: Review PRs within 7 days
- **Issue Triage**: Label and respond to issues within 3 days
- **Communication**: Participate in discussions respectfully
- **Documentation**: Keep docs up-to-date
- **Testing**: Ensure CI passes before merging
- **Security**: Handle security reports per SECURITY.md

### Core Maintainers (Perimeter 1)

- **Releases**: Cut releases following semantic versioning
- **Infrastructure**: Maintain CI/CD, container images, deployment
- **Onboarding**: Mentor new maintainers
- **Governance**: Make final decisions on disputes
- **Security**: Coordinate security vulnerability responses

## Decision Making

### Consensus-Based

We use **lazy consensus**:
1. Proposal made (issue, PR, discussion)
2. 72-hour review period
3. If no objections, proposal passes
4. If objections, discussion continues

### Voting (When Needed)

For contentious decisions:
- Each maintainer gets one vote
- Simple majority (>50%) required
- Lead maintainer has tie-breaking vote
- Voting period: 1 week

**Requires voting:**
- Adding/removing maintainers
- Changing governance model
- Major architectural changes
- Licensing changes
- Code of Conduct updates

## Maintainer Expectations

### Time Commitment

- **Minimum**: 2-4 hours per week
- **Responsive**: Check GitHub 2-3 times per week
- **Available**: Respond to pings within 48 hours (best effort)

### Technical Competence

- Deep understanding of Zotero plugin architecture
- Proficiency in PowerShell, Racket, or Bash
- Familiarity with CI/CD, testing, security practices
- Understanding of open source best practices

### Community Leadership

- Model behavior per Code of Conduct
- Welcome newcomers warmly
- Provide constructive feedback
- Resolve conflicts diplomatically
- Represent project professionally

## Inactive Maintainers

If a maintainer becomes inactive:

**Definition of Inactive:**
- No activity (commits, reviews, comments) for 6+ months
- No response to direct contact for 1 month

**Process:**
1. Attempt contact via email and GitHub
2. After 1 month no response, move to "Emeritus" status
3. Remove from maintainer team
4. Add to Emeritus section below
5. Can return to active status by contributing again

## Emeritus Maintainers

Former maintainers who contributed significantly:

*(None yet - founding team)*

Thank you for your service! 🙏

## Removing a Maintainer

Maintainers can be removed for:
- **Voluntary**: Personal request to step down
- **Inactive**: 6+ months inactivity (see above)
- **Code of Conduct Violation**: Serious or repeated violations
- **Technical Incompetence**: Persistent poor judgment causing harm

**Process for CoC/Competence Removal:**
1. Private discussion with maintainer
2. If unresolved, vote by remaining maintainers (2/3 majority)
3. Decision communicated privately
4. Public announcement (keeping details confidential)

## Maintainer Tools

### Access Required

- **GitHub**: Write access to repository
- **CI/CD**: GitHub Actions secrets access
- **Releases**: GitHub Releases permission
- **Packages**: (Future) PSGallery, Racket catalog
- **Security**: GitHub Security Advisories access

### Communication Channels

- **Public**: GitHub Issues, Discussions, PRs
- **Internal**: GitHub Discussions (private category for maintainers)
- **Security**: GitHub Security Advisories (see SECURITY.md)
- **Emergency**: Direct GitHub mention @Hyperpolymath

## Acknowledgments

We deeply appreciate all contributors, regardless of maintainer status. Every contribution matters:
- Code contributors
- Documentation writers
- Bug reporters
- Feature requesters
- Community helpers
- Users who provide feedback

## Changes to This Document

This document can be updated by:
- Pull request reviewed by any maintainer
- Lazy consensus (72 hours)
- Major changes require voting

## Contact

For questions about maintainership:
- Open a GitHub Discussion
- Use GitHub Security Advisories for security-related contact
- Mention @Hyperpolymath in an issue

---

*Last updated: 2025-01-15*
*Version: 1.0*
*License: Same as project (AGPL-3.0)*
