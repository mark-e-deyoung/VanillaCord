# Instructions for AI Agents

Welcome! If you are an AI agent working on this repository, please review these instructions to understand the stack and workflows for this project.

## Tech Stack
* **Java:** Version 21
* **Build Tool:** Maven

## Build Instructions
This project uses GitHub Packages to download the `Bridge` dependency. When running a build locally or within an automated environment, you must provide authentication.

### Authentication
To build the project, you need a GitHub Personal Access Token (PAT) with `read:packages` scope.
1. Provide the token via the `GITHUB_TOKEN` environment variable.
2. (Optional) Provide the `GITHUB_ACTOR` environment variable with your GitHub username.

Example of setting up authentication locally:
```sh
export GITHUB_TOKEN=your-personal-access-token
export GITHUB_ACTOR=your-github-username
```
(See `.env.example` in the root of the repository for reference).

### Compiling and Verifying
To compile the code and run the tests, use Maven.

Before running Maven, if you need to fetch the latest `Bridge` version, use the provided script:
```sh
export BRIDGE_VERSION=$(./scripts/resolve-bridge-version.sh)
```
Then run the build:
```sh
mvn -B verify
```

Alternatively, you can skip the specific `BRIDGE_VERSION` export and just rely on Maven to pull `0.1.0-SNAPSHOT` if you don't need a strict version pin, but providing it ensures reproducibility.

To quickly check if everything compiles:
```sh
mvn -B clean compile
```

To run tests:
```sh
mvn -B test
```

## Important Notes
* Do not modify build artifacts directly.
* Ensure proper testing and verification after modifying the codebase.
* Look for `AGENTS.md` files in nested directories (if any are added in the future) for more specific instructions.
