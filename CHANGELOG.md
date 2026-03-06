## v0.1.1 (2026-03-06)

### 🐛 Bug Fixes

- (release) appsec action ([`e5813a4`])
- (release) release v0.1.1: update .github/workflows/appsec.yaml ([`fdb3a45`])

### ⚡ Performance

- (release) appsec action ([`19413b1`])

## v0.1.1 (2026-03-06)

### 🐛 Bug Fixes

- (release) appsec action ([`e5813a4`])
- (release) release v0.1.1: update .github/workflows/appsec.yaml ([`fdb3a45`])

## v0.1.1 (2026-03-06)

### 🐛 Bug Fixes

- (release) release v0.1.1: update .github/workflows/appsec.yaml ([`fdb3a45`])

## v0.1.1 (2026-03-06)

### 🔧 Chores

- local working tree changes: .github/workflows/appsec.yaml ([`local`])

## v0.1.1 (2026-03-06)

### 🔧 Chores

- local working tree changes: .github/workflows/appsec.yaml ([`local`])

## v0.1.0 (2026-03-06)

### ✨ Features

- add script for configuring Service Account and Workload Identity Federation for Docker image publishing from GitHub Actions to GCP ([`57c5689`])
- add gcloud installation and configuration to bootstrap script ([`3ed20e7`])
- add installation and configuration scripts for Git hooks with YAML support ([`fd9c93b`])
- add installation scripts for Git hooks, system cleaner, GCP SDK, GitHub SSH key setup, Go environment management, and Gosec ([`0902701`])
- add installation scripts for Git hooks, system cleanup, GCP SDK, GitHub SSH key setup, Go environment management, and Gosec ([`1038fb5`])
- add ggwork alias for automated git add, commit, and push process ([`ecb773f`])
- add goenv installation and uninstallation scripts for macOS and Linux ([`bb16911`])
- add installation script and configuration for Git hooks ([`4c42a91`])

### 🐛 Bug Fixes

- exclude SC1090 rule in ShellCheck scan for improved linting accuracy ([`e3385e2`])
- remove unnecessary ShellCheck exclusion for improved linting accuracy ([`6dcd4b4`])
- remove unnecessary shebang line and shellcheck directive for cleaner scripts ([`3146c78`])
- update ShellCheck severity level and exclude alias files for improved linting accuracy ([`d58e92f`])
- correct syntax in snap removal command for improved reliability ([`63c8610`])
- standardize variable usage and update action versions in appsec workflow ([`8b5b201`])
- update action versions in appsec workflow for consistency ([`36347d3`])
- update Gitleaks scan command to suppress banner output ([`70637eb`])
- rename workflow to security-pipeline and update scan steps for clarity ([`c6172c5`])
- update appsec workflow steps for Gitleaks and Semgrep scans ([`10b5d49`])
- remove Go code check and related steps from appsec workflow ([`46fae66`])
- add Go code check before running Go Vulnerability Check in appsec workflow ([`98cbfa5`])
- replace AppSec Scanner with Gitleaks Core Scan and update workflow steps ([`2b73fb7`])
- remove deprecated security scan steps and streamline appsec workflow ([`0a4e98c`])
- replace Gitleaks action with Docker command for core scan in appsec workflow ([`da7e092`])
- update Zizmor action version and add Go Vulnerability Check in appsec workflow ([`942d32e`])
- update Zizmor action version in appsec workflow ([`6e53ae4`])
- standardize step names in appsec workflow and improve clarity ([`9526197`])
- update action versions and replace Zizmor installation with action in appsec workflow ([`5569ea0`])
- standardize step names and update action versions in appsec workflow ([`64b06d5`])
- update action versions and improve Gitleaks and Zizmor commands in appsec workflow ([`4672062`])
- remove unnecessary permissions and streamline Gitleaks and Zizmor steps in appsec workflow ([`85c6319`])
- replace Gitleaks action with installation and execution steps for improved control ([`2671eb2`])
- streamline profile file selection for macOS and Linux ([`bd6e4d0`])
- quote variable in SSH agent check for robustness ([`2fde617`])

### ♻️  Refactor

- remove old Git hooks and add new installation script with configuration ([`cb1a2fb`])
- clean up logging functions and improve architecture detection output ([`b1e83dc`])
- improve Gitleaks installation and update upload action to v4 ([`e45ba3b`])

### 📦 Other

- Refactor and reorganize security and Git configuration scripts ([`669694e`])
- update ShellCheck scan to specify bash shell and remove external checks download ([`32c5238`])
- Fixing .github/workflows/appsec.yml ([`57227f6`])
- refactor appsec.yml to rename pipeline and update permissions for SAST analysis ([`c108b8c`])
- add SARIF generation to Semgrep action for enhanced security reporting ([`8b5cf46`])
- add SAST analysis job with Semgrep and SARIF upload to GitHub Code Scanning ([`19346e6`])
- add Git hooks configuration and installation script for pre-commit with Gitleaks integration ([`c8487a8`])
- add pre-commit configuration for gitleaks to enhance security checks ([`fe31a60`])
- update appsec.yml to set permissions and simplify checkout process ([`c961ec3`])
- testing appsec leaks first ([`1b2f6ca`])
- testing appsec leaks first ([`e2c2fe1`])
- unify common safe aliases ([`22f5c04`])
- 48:21 CET 2026 ([`0d09234`])
- none important changes. styling ([`c9ce071`])
- Update GitHub Actions workflow for security scans ([`b57d454`])
- Update appsec.yml with specific action versions ([`ddcde97`])
- Update actions versions in appsec.yml ([`e6db6c0`])
- Update ShellCheck action version in appsec.yml ([`c040eee`])
- Remove gosec installation script and add goenv installation and uninstallation scripts ([`d265bb0`])
- secure action v1 ([`5472e6f`])
- order and cleanup ([`69f2276`])
- doc action ([`a5c78ec`])
- testing actions all jobs ([`7d8ebfc`])
- appsec testing ([`2c8e17b`])
- appsec testing ([`92e9383`])
- appsec testing ([`179f949`])
- appsec gitleaks ([`db7b544`])
- added git config pull.rebase false ([`ef1f24d`])
- git aliases and goenv ([`6466366`])
- rename best naming for some scripts ([`a12db08`])
- order ([`e13385c`])
- gcp sdk installer for mac linux ([`d79c248`])
- initial import ([`c986461`])

