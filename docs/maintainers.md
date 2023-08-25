## Overview

This document explains what maintainers of the repo do and how they should be doing it. If you're interested in contributing, see [CONTRIBUTING](CONTRIBUTING.md).

## Current Maintainers

The current maintainers can be found in the `Chart.yaml` file of a given Helm chart.

## Maintainer Responsibilities

Maintainers are active and visible members of the community, and have [maintain-level permissions on a repository](https://docs.github.com/en/organizations/managing-access-to-your-organizations-repositories/repository-permission-levels-for-an-organization). Use those privileges to serve the community and evolve code as follows.

### Prioritize Security

Security is your number one priority. Maintainer's Github keys must be password protected securely and any reported security vulnerabilities are addressed before features or bugs.

### Review Pull Requests

It's our responsibility to ensure the content and code in pull requests are correct and of high quality before they are merged. Here are some best practices:

- Leverage the issue triaging process to review pull requests and assign them to maintainers for review.
- In cases of uncertainty on how to proceed, search for related issues and reference the pull request to find additional collaborators.
- When providing feedback on pull requests, make sure your feedback is actionable to guide the pull request towards a conclusion.
- If a pull request is valuable but isn't gaining traction, consider reaching out to fulfill the necessary requirements. This way, the pull request can be merged, even if the work is done by several individuals.
- Lastly, strive for progress, not perfection.

### Triage Open Issues

Manage labels, review issues regularly, and triage by labelling them.

All repositories in this organization have a standard set of labels, including `bug`, `documentation`, `duplicate`, `enhancement`, `good first issue`, `help wanted`, `blocker`, `invalid`, `question`, and `wontfix`.

Use labels to target an issue or a PR for a given release, add `help wanted` to good issues for new community members, and `blocker` for issues that scare you or need immediate attention. Request for more information from a submitter if an issue is not clear. Create new labels as needed by the project.

#### Automatically Label Issues

There are many tools available in GitHub for controlling labels on issues and pull requests.  Use standard issue templates in the `.github/ISSUE_TEMPLATE` directory to apply appropriate labels such as `bug` and `untriaged`.

### Be Responsive

Respond to enhancement requests, and forum posts. Allocate time to reviewing and commenting on issues and conversations as they come in.

### Maintain Overall Health of the Repo

Keep the `main` branch at production quality at all times. Backport features as needed. Cut release branches and tags to enable future patches.

#### Keep Dependencies up to Date

Maintaining up-to-date dependencies on third party projects reduces the risk of security vulnerabilities. The Open Source Security Foundation (OpenSSF) [recommends](https://github.com/ossf/scorecard/blob/main/docs/checks.md#dependency-update-tool) either [dependabot](https://docs.github.com/en/code-security/dependabot) or [renovatebot](https://docs.renovatebot.com/). Both of these applications generate Pull Requests for dependency version updates.

### Add Continuous Integration Checks

Add integration checks that validate pull requests and pushes to ease the burden on Pull Request reviewers.

### Use Semver

Use and enforce [semantic versioning](https://semver.org/) and do not let breaking changes be made outside of major releases.

### Release Frequently

Make frequent project releases to the community.

### Promote Other Maintainers

Assist, add, and remove maintainers. Exercise good judgement, and propose high quality contributors to become co-maintainers.

## Becoming a Maintainer

You can become a maintainer by actively [contributing](CONTRIBUTING.md) to the project and being nominated by an existing maintainer.
