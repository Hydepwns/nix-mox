# Troubleshooting Guide

Terse guide for resolving common issues with `nix-mox` templates.

## Issue Resolution Flow

```mermaid
flowchart TD
    A[Issue] --> B{Type}
    B -->|Template| C[Not Found]
    B -->|Package| D[Dependency]
    B -->|Config| E[Variables]
    B -->|Files| F[Overrides]
    B -->|Service| G[Systemd]
    
    C --> H[Check Name]
    D --> I[Verify Dependencies]
    E --> J[Validate Config]
    F --> K[Check Paths]
    G --> L[Check Logs]
    
    H --> M[Resolved]
    I --> M
    J --> M
    K --> M
    L --> M
```

## Common Issues

```mermaid
graph TD
    A[Common Issues] --> B[Template Not Found]
    A --> C[Dependency Errors]
    A --> D[Variable Issues]
    A --> E[Override Problems]
    A --> F[Service Failures]
    
    B --> B1[Check Name]
    B --> B2[Verify Template]
    
    C --> C1[Check Package]
    C --> C2[Verify Version]
    
    D --> D1[Check Variables]
    D --> D2[Validate Syntax]
    
    E --> E1[Check Paths]
    E --> E2[Verify Structure]
    
    F --> F1[Check Logs]
    F --> F2[Verify Config]
```

## Quick Solutions

### 1. Template Not Found

```nix
# Error: 'template-name' not in enumeration
services.nix-mox.templates.templates = [
  "template-name"  # Check spelling
];
```

### 2. Dependency Errors

```nix
# Error: Dependency 'some-package' not found
services.nix-mox.templates.customOptions = {
  template-name = {
    package = "some-package";  # Verify in pkgs
  };
};
```

### 3. Variable Substitution

```nix
# Error: @variable@ not replaced
services.nix-mox.templates.templateVariables = {
  variable = "value";  # Match exactly
};
```

### 4. Override Issues

```nix
# Error: Override not applied
services.nix-mox.templates.templateOverrides = {
  "template-name" = ./path;  # Verify structure
};
```

### 5. Service Failures

```bash
# Check service status
systemctl status <service-name>.service
journalctl -u <service-name>.service
```

## Debug Flow

```mermaid
flowchart TD
    A[Debug] --> B[Check Config]
    B --> C[Verify Files]
    C --> D[Test Service]
    D --> E[Check Logs]
    
    B --> B1[templateVariables]
    B --> B2[customOptions]
    
    C --> C1[File Structure]
    C --> C2[Permissions]
    
    D --> D1[Manual Run]
    D --> D2[Status Check]
    
    E --> E1[systemctl]
    E --> E2[journalctl]
```

## Resolution Steps

```mermaid
graph TD
    A[Resolution] --> B[Identify]
    B --> C[Locate]
    C --> D[Fix]
    D --> E[Verify]
    
    B --> B1[Error Message]
    B --> B2[Logs]
    
    C --> C1[Config]
    C --> C2[Files]
    
    D --> D1[Update]
    D --> D2[Test]
    
    E --> E1[Check]
    E --> E2[Monitor]
```
