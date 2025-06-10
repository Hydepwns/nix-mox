# Future Development Roadmap

This document outlines potential future directions and enhancements for the `nix-mox` templating system. With the core features for customization, documentation, and testing now in place, these ideas represent the next steps in evolving the project into a more powerful and user-friendly platform.

## 1. Template Marketplace

A centralized, community-driven repository for discovering and sharing `nix-mox` templates.

- **Concept**: Lower the barrier for users to find and implement solutions for their own infrastructure, and for developers to share their work. The marketplace would serve as a curated hub for high-quality, reusable templates.
- **Implementation Ideas**:
  - A dedicated GitHub repository acting as a simple, curated list of approved templates, categorized by function (e.g., web, database, monitoring).
  - A web interface that provides a searchable, filterable catalog of templates, complete with documentation and usage examples.
  - A CLI extension, such as `nix-mox template search <keyword>` or `nix-mox template add <template-name>`, to integrate discovery directly into the user's workflow.
- **Benefits**: Fosters a vibrant community ecosystem, accelerates development by promoting reuse, and helps standardize best practices across different infrastructure types.

## 2. Advanced Template Dependencies

An explicit dependency management system where templates can declare dependencies on other templates.

- **Concept**: While template composition allows for building stacks, it doesn't enforce required dependencies. A formal dependency system would allow a template to state, "I cannot function without the `monitoring` template."
- **Implementation Ideas**:
  - Introduce a `templateDependencies` attribute to template definitions in `modules/templates.nix`.
  - The template resolution logic would be updated to recursively find and enable all required template dependencies, ensuring a complete and valid configuration.
  - Could be extended to support version constraints (e.g., `dependsOn = ["database-management>=2.0"]`), though this would require a more robust versioning scheme.
- **Benefits**: Improves the modularity and reliability of complex templates, prevents runtime errors from missing dependencies, and makes the relationships between different services explicit.

## 3. Automated Template Updates

A streamlined process for users to update their templates to the latest versions.

- **Concept**: As templates in the main `nix-mox` repository (or a marketplace) are improved and patched, users should have an easy way to pull in these updates.
- **Implementation Ideas**:
  - A new CLI command, `nix-mox template update`, that inspects the user's configuration, checks the upstream sources for new versions, and reports on available updates.
  - The tool could offer to automatically apply non-breaking changes or provide a migration guide for breaking changes.
  - This would integrate well with the existing flake mechanism, providing a more user-friendly layer on top of `nix flake update`.
- **Benefits**: Simplifies long-term maintenance for users, ensures timely application of security patches and bug fixes, and keeps the user's infrastructure current with best practices.

## 4. Enhanced Template Security

A more formalized set of security-focused features and best practices for the template ecosystem.

- **Concept**: As the number of community-contributed templates grows, ensuring they are safe and trustworthy becomes paramount.
- **Implementation Ideas**:
  - **Sandboxing**: Investigate running template-related scripts in more restrictive environments to limit their access to the host system.
  - **Code Signing**: A system for templates in the marketplace to be cryptographically signed, allowing users to verify their integrity and origin.
  - **Security Scanner**: A dedicated CI job that automatically scans templates for common security vulnerabilities, such as hardcoded secrets, insecure default permissions, or use of deprecated packages.
- **Benefits**: Builds user trust in community templates, mitigates the risk of supply chain attacks, and promotes a culture of security-by-default within the project.

## 5. Rich Template Validation

A schema-based system for validating the structure, options, and metadata of a template.

- **Concept**: Go beyond basic Nix type checking to provide a more descriptive and robust validation layer for template authors and users.
- **Implementation Ideas**:
  - Define a formal schema (e.g., using JSON Schema or a custom Nix-based DSL) for `customOptions` that allows for more complex validation rules (e.g., string patterns, integer ranges, conditional fields).
  - A `nix-mox template validate` command to check a local template directory against the schema, providing clear and actionable feedback to the developer.
  - Enforce schema validation in the CI pipeline for any templates submitted to the marketplace.
- **Benefits**: Catches errors early in the development process, improves the quality and consistency of templates, and provides a better user experience by preventing misconfigurations.

## 6. Further Enhancements to Customization

The existing customization features (`Composition`, `Inheritance`, `Variables`, and `Overrides`) are powerful but could be extended further.

- **Scoped Variables**: Allow `templateVariables` to be defined on a per-template basis, rather than only globally.
- **Deeper Merging**: Provide more control over how `customOptions` are merged during inheritance (e.g., appending to lists instead of replacing them).
- **Conditional Logic**: Introduce simple conditional logic within template files (e.g., `if @enable_feature@ ... endif`) that could be controlled by variables or options.
