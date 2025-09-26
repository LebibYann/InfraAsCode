# 🤝 Contributing Guide

This document explains how to submit high‑quality contributions and keep history clean.

---

## 🧭 Core Principles

- Readability and maintainability first.
- Every change should be traceable (Issue ↔ PR ↔ Commits).
- Small, focused PRs > large, hard-to-review PRs.
- Code ships with tests + docs (not later).
- Automate what can be automated (lint, format, tests, security).

---

## 🌿 Branching Strategy

* `main`: always deployable
* `dev`: main development branch
* `issueID-issue`: new issue

---

## 📝 Commit Messages

Use (simplified) Conventional Commits:

```
type(scope?): concise imperative subject

Optional body: explain in details.
Optional Refs: #ISSUE
```

Types: feat, fix, docs, chore, refactor, test, perf, ci, build, revert.

Example:
```
feat(api): add /health endpoint
```

---

## 🧪 Quality & Local Checks

Before pushing, please run all tests.
No PR should decrease test or coverage thresholds.

---

## 🔐 Security

Never commit secrets (API keys, tokens).<br>
Report vulnerabilities privately.<br>
Avoid unmaintained or license-unclear dependencies.

---

## 🧩 Contribution Workflow

1. Create / locate an Issue (avoid duplicates).
2. Clarify scope if ambiguous.
3. Branch from dev.
4. Implement in small atomic commits.
5. Add/update tests + docs + CHANGELOG (if used).
6. Run lint / tests locally.
7. Open a Pull Request using the template.
8. Address review feedback.
9. Clean up your branch history before merge if requested:
    - **Rebase**: use it if your commits are already clean, logical, and well-structured (keeps full history).
    - **Squash**: use it if you made many small, noisy, or fix commits (combines them into one or a few meaningful commits).
10. Merge according to project policy.

---

## 🔍 Code Review Checklist

Author:
- [ ] Issue linked
- [ ] Scope focused
- [ ] Tests added/updated
- [ ] No dead/debug code (print / console.log)
- [ ] Clear naming
- [ ] Docs / README updated
- [ ] No obvious duplication
- [ ] Consistent error handling

Reviewer:
- [ ] Intent quickly understandable
- [ ] Critical paths covered by tests
- [ ] No unnecessary tech debt introduced
- [ ] Consistent with existing patterns
- [ ] Performance acceptable
- [ ] Input validation / security considered
- [ ] No secret leakage

---

## 🗂 Issue Management

Suggested labels:

- **Type**
  - `type: bug` → Fix incorrect behavior
  - `type: feature` → Implement a new functionality
  - `type: task` → Maintenance, refactor, or non-feature work

- **Priority**
  - `priority: P0` → Must-have, blocker
  - `priority: P1` → Important, but not blocking
  - `priority: P2` → Nice-to-have / low impact

- **Size (effort estimation)**
  - `size: XS` → < 1h
  - `size: S` → < 0.5 day
  - `size: M` → 1–2 days
  - `size: L` → 3–5 days
  - `size: XL` → > 1 week

- **Process**
  - `status: backlog` → Needs clarification
  - `status: ready` → Ready to work on
  - `status: in-progress` → Being worked on
  - `status: in-review` → Being reviewed
  - `status: done` → Completed Issue
