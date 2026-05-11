# Security Policy

## 🛡️ Supported Versions

We actively maintain and provide security updates for the latest version of this project.

| Version        | Supported |
|----------------|-----------|
| Latest (main)  | ✅ Yes     |
| Older versions | ❌ No      |

⚠️ If you are using an older version, please upgrade to the latest version to receive security fixes.

---

## 🚨 Reporting a Vulnerability

We take security issues seriously and appreciate responsible disclosure.

**Please do NOT report security vulnerabilities through public GitHub issues.**  
Public disclosure before a fix is available can expose users to risk. [1](https://wiki.penguinmod.com/wiki/PenguinAI)

### ✅ Preferred method (GitHub Security Advisories)

1. Go to the **Security tab** of this repository  
2. Click **"Report a vulnerability"**  
3. Submit the report privately  

This creates a confidential channel visible only to maintainers.

---

### ✉️ Alternative: Email

If needed, you can report vulnerabilities via email:

**beernanthasit@icloud.com**

Please include:

- Clear description of the issue  
- Steps to reproduce  
- Affected components (e.g. frontend, backend, Python services, Rust crates)  
- Potential impact  
- Suggested fix (optional)

---

## ⏱️ Response Timeline

We aim to respond quickly and transparently:

- **Initial response:** within 24–48 hours  
- **Status updates:** within 3–5 days  
- **Resolution target:** within 30–60 days (depending on severity)  

Higher severity issues are prioritised and addressed faster.

---

## 🔐 Disclosure Policy

We follow **coordinated vulnerability disclosure**:

- Issues are handled privately until a fix is available  
- We work with reporters to agree on disclosure timing  
- Public disclosure happens after mitigation or patch release  

Researchers will be credited unless they prefer anonymity.

---

## 🔍 Security Practices

This repository follows security best practices across all components:

- ✅ Dependency updates via Dependabot  
- ✅ Automated vulnerability alerts and scans  
- ✅ Regular dependency audits (npm, pip, cargo)  
- ✅ Code review and testing before releases  

Dependency audits help detect known vulnerabilities early in third-party packages. [2](https://forum.cfx.re/t/best-qbcore-esx-chat-script-for-fivem-servers/5051889)[3](https://forum.cfx.re/t/jgs-dynamic-chat-qbcore-esx-fivem/5264144)

---

## 📦 Scope

This policy applies to all parts of the monorepo, including:

- `/apps/*` → frontend / UI apps (npm)
- `/packages/*` → shared libraries (npm)
- `/services/*` → backend services (Node.js, Python, etc.)
- `/python` or similar → Python projects (pip / pyproject)
- `/rust` or `/crates/*` → Rust services (cargo)

If you're unsure whether a component is in scope, report it anyway — we’ll assess it.

---

## 💰 Bug Bounty

We do not currently offer a bug bounty programme.

However, responsible disclosure is appreciated and contributors may be acknowledged in release notes or advisories.

---

## 📢 Questions

For non-sensitive questions about security, feel free to open a GitHub discussion or issue.

---

✅ Thank you for helping keep this project and its users safe!
``
