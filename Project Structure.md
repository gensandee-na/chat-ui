# 🧱 Project Structure

This page explains how the **chat-ui** repository is organised.

The project follows a **monorepo structure**, meaning multiple applications, services, and shared packages live in a single repository. [2](https://medium.com/@julakadaredrishi/monorepos-a-comprehensive-guide-with-examples-63202cfab711)

---

## 📁 Overview

```text
chat-ui/
├── apps/            # Frontend / UI applications
├── packages/        # Shared libraries and components
├── services/        # Backend services (Node, Python, etc.)
├── python/          # Python-specific projects
├── rust/            # Rust crates / services
├── .github/         # CI/CD, workflows, configs
├── package.json     # Root workspace config
├── README.md        # Project overview
