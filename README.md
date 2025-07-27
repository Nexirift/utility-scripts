# Nexirift Utility Scripts

A comprehensive toolkit of automation scripts for Nexirift development that standardizes workflows and eliminates repetitive tasks across all development environments.

## Important Usage Note

**Always run scripts using the wrapper script.** This is essential for proper environment variable loading and dependency availability.

### Getting Started

This repository functions as a submodule under the `utility-scripts` directory within your main project repository, which should contain a `.env` file.

Execute any script through the wrapper:

```bash
./wrapper.sh script-name [arguments]
```

Examples:

```bash
./wrapper.sh reset-verdaccio
./wrapper.sh switch-registry
```

### Wrapper Benefits

The wrapper script provides critical functionality:
- Auto-detects and sources your `.env` file
- Loads all common utilities and dependencies
- Manages permissions and resolves paths automatically
- Provides clear error feedback and diagnostics

Direct script execution will fail as common utilities won't be loaded.

### Script Categories

#### Core Utilities
- `reset-verdaccio.sh` - Resets Verdaccio configuration and cleans caches
- `switch-registry.sh` - Toggles between local Verdaccio and remote Nexirift registries
- `update-shadcn.sh` - Updates Shadcn UI components with safety backups

#### Database Tools (`db/`)
- `start.sh` - Initializes or restarts PostgreSQL container
- `reset.sh` - Removes migrations and recreates clean database
- `run.sh` - Executes commands in @nexirift/db package context

#### Key-Value Store Tools (`kv/`)
- `start.sh` - Initializes or restarts Valkey (Redis) container
- `reset.sh` - Flushes all key-value store data

Run `./wrapper.sh` without arguments to see all available scripts

## Script Details

### Database Management

Streamlined PostgreSQL management for development:

- **db/start.sh**: Launches `nexirift-postgres` container, creating or restarting as needed using `.env` connection details.
- **db/reset.sh**: Performs complete database reset by removing migrations and recreating schemas (interactive confirmation required).
- **db/run.sh**: Provides direct access to `@nexirift/db` package functionality.

### Key-Value Store Management

Redis-compatible storage management:

- **kv/start.sh**: Launches `nexirift-valkey` container, creating or restarting as needed.
- **kv/reset.sh**: Performs data flush with interactive confirmation.

### Registry Management

- **reset-verdaccio.sh**: Performs clean reset of Verdaccio state and caches.
- **switch-registry.sh**: Manages registry configuration in `.npmrc` and `bunfig.toml` to toggle between local and remote registries.

### UI Component Management

- **update-shadcn.sh**: Manages Shadcn UI component updates with automatic backups, version selection (latest/canary), and component analysis.

## Script Development Guidelines

When creating new scripts, follow these requirements:

1. Make executable (`chmod +x script-name.sh`)
2. Use proper shebang (`#!/bin/bash`)
3. Implement consistent error handling and output formatting
4. Leverage `common.sh` utility functions
5. Add documentation both in-script and to this README

## Common Utilities

The `common.sh` module provides essential shared functionality automatically loaded by the wrapper.

### Package Manager Detection

- Auto-configures `PACKAGE_MANAGER` and `PACKAGE_RUNNER` variables
- Priority support for pnpm, with fallbacks to yarn, npm, and bun
- Honors pre-existing environment variable settings

### Output Formatters

Consistent, color-coded messaging functions:

- `print_error "Message"` - Red error text
- `print_warning "Message"` - Yellow warning text
- `print_success "Message"` - Green success text

### Package Operations

- `run_package_manager command [args]` - Safe package manager execution with error handling
- `run_package_runner package [args]` - Safe package execution with error handling

### Helper Functions

- `command_exists command_name` - PATH availability checker

### Implementation Example

```bash
#!/bin/bash

# Clear visual status messaging
print_warning "About to modify configuration files"

# Dependency verification
if ! command_exists docker; then
  print_error "Docker is required but not found"
  exit 1
fi

# Safe package operations
if run_package_manager install; then
  print_success "Dependencies installed successfully"
fi

# Component management
run_package_runner shadow-cli add button
```

## Contributing

### Development Setup

To contribute:

1. Fork and clone the repository
2. Create a feature branch (`git checkout -b feature/new-utility`)
3. Implement changes following guidelines below
4. Test thoroughly in a live Nexirift project
5. Submit a detailed pull request

### Testing Best Practices

When testing new or modified scripts:

1. Verify behavior in both interactive and non-interactive modes
2. Test across multiple environment configurations
3. Validate error handling with intentional failure scenarios
4. Use `set -x` with strategic echo statements for debugging

### Coding Standards

Required standards for contributions:

- Use Bash (`#!/bin/bash`) not POSIX sh
- Document complex logic with clear comments
- Utilize `common.sh` utilities consistently
- Follow established error handling patterns
- Use descriptive variable naming
- Scope variables with `local` within functions

## Configuration Requirements

Scripts rely on environment variables from your `.env` file, loaded automatically by the wrapper.

### Database Configuration

Required database variables:

- `DATABASE_URL` - PostgreSQL connection string in format `postgresql://postgres:password@localhost:5432/nexirift`

### Key-Value Configuration

Required KV variables:

- `KV_URL` - (optional) Valkey/Redis connection string, defaults to `redis://localhost:6379`

### Registry Configuration

Optional registry variables:

- `NPM_REGISTRY_TOKEN` - Authentication for Nexirift registry

## Troubleshooting

### Common Issues

#### Docker Service Unavailable

For Docker connectivity errors:

```bash
# Linux systems
sudo systemctl start docker

# macOS
open -a Docker
```

#### Permission Errors

For script permission issues:

```bash
# Direct permission fix
chmod +x utility-scripts/script-name.sh

# Or use the wrapper (recommended)
./utility-scripts/wrapper.sh script-name
```

#### Environment File Issues

For `.env` file detection problems:

```bash
# Run from project root or specify path explicitly
ENV_FILE=/path/to/.env ./utility-scripts/wrapper.sh script-name
```

#### Registry Configuration Problems

For registry switching failures:

```bash
# Inspect configuration
cat .npmrc
cat bunfig.toml

# Manual reset to default
echo "@nexirift:registry = \"https://code.nexirift.com/dev/~npm/\"" > .npmrc
```

## Version History

Evolution of these utilities:

- **v1.0.0** - Initial core utilities
- **v1.1.0** - Database management tools
- **v1.2.0** - Key-value store management
- **v1.3.0** - Enhanced environment detection
- **v1.4.0** - Comprehensive documentation

## License

These utilities are part of the Nexirift project and are governed by its license terms.
