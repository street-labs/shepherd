# Security Policy

## Reporting a vulnerability

**Do not open a public pull request for a security issue** — and note that this repository's issue tracker is disabled.

Report vulnerabilities privately through GitHub's **[private vulnerability reporting](https://github.com/street-labs/shepherd/security/advisories/new)** (Security → Report a vulnerability). This opens a private advisory visible only to the maintainers.

Please include:

- A description of the vulnerability and its impact.
- Steps to reproduce (a minimal repro is ideal).
- Affected version(s) — a commit SHA or release tag.

We'll acknowledge the report, investigate, and coordinate a fix and disclosure with you.

## Scope

Shepherd is a local macOS app that reads source files from your machine and renders them (including markdown as HTML). The most relevant classes of issue are: unsafe rendering or insufficient sanitization of file/markdown content, path handling that reads outside the intended file, unsafe handling of the launch URL / session parameters, or shell-injection in the install and helper scripts under `scripts/`. Reports in these areas are especially welcome.
