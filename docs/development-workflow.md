
# TripRaft Engineering Development Workflow

## 1. Purpose

This document defines the development process for
all TripRaft engineers.

Every feature, bug fix, and infrastructure change
must follow the appropriate planning, review,
testing, and release process.

## 2. Team Responsibilities

### CTO
- Approves major technical decisions.
- Oversees architecture and infrastructure.
- Reviews production readiness.
- Authorizes production releases.
- Controls production database migrations.

### Developers
- Work on assigned GitHub Issues.
- Develop code in feature branches.
- Add or update relevant tests.
- Submit pull requests for review.
- Fix failed tests and review findings.
- Never directly push to protected main.

### QA Responsibility
- Developers test their own changes.
- Reviewers verify acceptance criteria.
- Automated CI runs mandatory checks.
- A designated QA owner coordinates staging tests.

## 3. Git Branch Strategy

main:
- Stable, release-ready code.
- Requires mandatory QA and approvals.
- No direct developer pushes.

develop:
- Shared integration branch.
- Requires mandatory CI checks.
- Requires two eligible PR approvals.

feature/*:
- Used for individual development tasks.
- Created from the latest develop branch.
- Merged through pull requests.

Existing personal development branches:
- arsh-develop
- devansh-develop
- deep-develop
- cto-develop (if available)

Personal branches may be used for individual
work, but feature PRs should contain only
the changes required for their assigned task.

## 4. Feature Development Process

1. Create a GitHub Issue.
2. Define requirements and acceptance criteria.
3. Set task priority and assign a developer.
4. Create a feature branch.
5. Implement the required changes.
6. Add or update relevant QA test cases.
7. Run local tests.
8. Open a pull request to develop.
9. Complete automated CI checks.
10. Obtain required code review approvals.
11. Merge into develop.
12. Perform integration testing.
13. Validate the release candidate in staging.
14. Open the release pull request to main.
15. Complete release checks and CTO authorization.
16. Merge into main.
17. Deploy the approved release.
18. Run production smoke tests.
19. Monitor errors and performance.
20. Close the task when verification is complete.

## 5. Required QA Checks

Relevant checks include:

- Code linting and formatting
- Type checking
- Unit tests
- API integration tests
- Frontend component tests
- Database migration tests
- Security and permission tests
- End-to-end browser tests
- Regression tests
- AI agent evaluation when applicable

Required automated checks must pass
before a protected branch can be merged.

## 6. Database Rules

- Use PostgreSQL for shared application data.
- Never run destructive tests on production data.
- Use isolated databases for automated QA.
- Never commit passwords or database secrets.
- Database schema changes require review.
- Production migrations require CTO authorization.
- Backups and rollback plans must be verified.

## 7. Security Rules

- Do not commit credentials or API keys.
- Validate user input.
- Enforce authentication and authorization.
- Protect user and employee data.
- Check third-party dependencies.
- Report security vulnerabilities immediately.
- Do not expose private user data in issues or logs.

## 8. Pull Request Requirements

Every PR should include:

- Related GitHub Issue
- Summary of changes
- Affected components
- QA test cases
- Testing results
- Database changes, if any
- Security considerations
- Screenshots for UI changes
- Risks and dependencies

A completed PR checklist is not a substitute
for passing CI checks and GitHub reviews.

## 9. Release Requirements

Before production deployment:

- Required automated QA passes.
- No unresolved release-blocking defects.
- Staging verification passes.
- Database changes are reviewed.
- Backup and rollback readiness is confirmed.
- Required approvals are recorded.
- CTO authorizes the production release.

Production deployment must use the approved
release revision.

## 10. Production Monitoring

After deployment:

- Verify critical application workflows.
- Monitor backend errors and frontend failures.
- Monitor API latency and availability.
- Check database health.
- Track important user-reported bugs.
- Roll back or mitigate critical failures.

## 11. Task Completion

A task may be marked Done when:

- Required code is merged.
- Applicable QA checks pass.
- The released functionality is verified.
- Documentation is updated when necessary.
- No release-blocking issue remains.

## 12. Enforcement

These rules describe TripRaft's intended
engineering process.

Actual merge restrictions, required checks,
approval requirements, and deployment controls
must be configured separately through GitHub
rulesets, Actions, and release environments.
