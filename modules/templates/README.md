# Templates

This directory contains template configurations for various systems and environments, organized by category.

## Structure

- `services/`: Service-specific templates
  - `cache-server/`: Cache server configurations (Redis, Memcached)
  - `database-management/`: Database management and administration
  - `message-queue/`: Message queue systems (RabbitMQ, Apache Kafka)
  - `monitoring/`: Monitoring and observability stacks
- `infrastructure/`: Infrastructure templates
  - `containers/`: Container orchestration and management
  - `load-balancer/`: Load balancer configurations
- `platforms/`: Platform-specific templates
  - `nixos/`: NixOS-specific templates and configurations
  - `windows/`: Windows-specific templates
- `templates.nix`: Core template functionality and shared configurations

## Usage

Each template category can be imported individually or as a group:

```nix
{
  imports = [
    # Import all service templates
    nix-mox.nixosModules.templates.services
    
    # Import specific service template
    nix-mox.nixosModules.templates.services.cache-server
    
    # Import infrastructure templates
    nix-mox.nixosModules.templates.infrastructure
    
    # Import platform templates
    nix-mox.nixosModules.templates.platforms
  ];
}
```

## Template Categories

### Services

Service templates provide configurations for common application services:

- **Cache Server**: Redis and Memcached configurations with monitoring
- **Database Management**: Database administration and maintenance tools
- **Message Queue**: Message queue systems for distributed applications
- **Monitoring**: Complete monitoring stacks with Prometheus, Grafana, and AlertManager

### Infrastructure

Infrastructure templates handle system-level configurations:

- **Containers**: Docker and LXC container management
- **Load Balancer**: High-availability load balancer setups

### Platforms

Platform-specific templates for different operating systems:

- **NixOS**: NixOS-specific configurations including VM templates, CI runners, and safe configurations
- **Windows**: Windows-specific templates for development, gaming, and multimedia workstations
