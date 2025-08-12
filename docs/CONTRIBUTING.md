# Contributing to Splendor Blockchain V4

Thank you for your interest in contributing to Splendor Blockchain! We welcome contributions from the community and are pleased to have you join us.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Security Guidelines](#security-guidelines)
- [Pull Request Process](#pull-request-process)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/splendor-blockchain-v4.git
   cd splendor-blockchain-v4
   ```
3. **Set up the development environment** (see [Development Setup](#development-setup))
4. **Create a branch** for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Environment details** (OS, Node.js version, etc.)
- **Screenshots or logs** if applicable

Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).

### Suggesting Features

Feature requests are welcome! Please:

- **Check existing feature requests** to avoid duplicates
- **Provide a clear use case** for the feature
- **Explain the expected behavior**
- **Consider implementation complexity**

Use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

### Code Contributions

We accept contributions in the following areas:

#### Core Blockchain
- **Consensus improvements**
- **Performance optimizations**
- **Security enhancements**
- **Bug fixes**

#### System Contracts
- **Governance improvements**
- **Validator management**
- **Economic model enhancements**

#### Documentation
- **API documentation**
- **Tutorials and guides**
- **Code examples**
- **Translation**

#### Developer Tools
- **SDK improvements**
- **Testing utilities**
- **Development scripts**

## Development Setup

### Prerequisites

- **Go 1.15+** for core blockchain development
- **Node.js 16+** and **npm** for tooling and contracts
- **Git** for version control

### Core Blockchain Setup

```bash
# Navigate to core blockchain
cd Core-Blockchain/node_src

# Install Go dependencies
go mod download
go mod tidy

# Build the node
go build -o geth.exe ./cmd/geth

# Initialize with genesis
./geth.exe init ../genesis.json --datadir ./data
```

### System Contracts Setup

```bash
# Navigate to contracts
cd System-Contracts

# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test
```

### Documentation Setup

```bash
# Install dependencies for documentation tools
npm install

# Verify mainnet connection
npm run verify
```

## Coding Standards

### Go Code Standards

- Follow **Go formatting standards** (`gofmt`)
- Use **meaningful variable names**
- Add **comprehensive comments** for public functions
- Follow **Go best practices** and idioms
- Include **error handling** for all operations

```go
// Good example
func ValidateTransaction(tx *Transaction) error {
    if tx == nil {
        return errors.New("transaction cannot be nil")
    }
    
    if tx.Amount <= 0 {
        return errors.New("transaction amount must be positive")
    }
    
    return nil
}
```

### Solidity Code Standards

- Use **Solidity 0.8.19+**
- Follow **OpenZeppelin patterns**
- Include **comprehensive NatSpec comments**
- Implement **proper access controls**
- Use **reentrancy guards** where applicable

```solidity
/**
 * @title Example Contract
 * @dev Demonstrates proper Solidity coding standards
 */
contract ExampleContract is Ownable, ReentrancyGuard {
    /**
     * @dev Transfers tokens with proper validation
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transfer(address to, uint256 amount) 
        external 
        nonReentrant 
        onlyOwner 
    {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be positive");
        
        // Implementation
    }
}
```

### JavaScript/TypeScript Standards

- Use **ES6+ features**
- Follow **consistent naming conventions**
- Include **JSDoc comments**
- Use **async/await** for promises
- Handle **errors appropriately**

```javascript
/**
 * Connects to Splendor mainnet
 * @param {string} rpcUrl - RPC endpoint URL
 * @returns {Promise<ethers.Provider>} Connected provider
 */
async function connectToMainnet(rpcUrl = 'https://mainnet-rpc.splendor.org/') {
    try {
        const provider = new ethers.JsonRpcProvider(rpcUrl);
        await provider.getNetwork();
        return provider;
    } catch (error) {
        throw new Error(`Failed to connect: ${error.message}`);
    }
}
```

## Testing Guidelines

### Unit Tests

- **Write tests** for all new functionality
- **Maintain high coverage** (aim for 80%+)
- **Use descriptive test names**
- **Test edge cases** and error conditions

### Integration Tests

- **Test component interactions**
- **Verify end-to-end workflows**
- **Test locally** before mainnet

### Performance Tests

- **Benchmark critical paths**
- **Test under load**
- **Monitor resource usage**

### Running Tests

```bash
# Go tests
cd Core-Blockchain/node_src
go test ./...

# Smart contract tests
cd System-Contracts
npx hardhat test

# Coverage reports
npx hardhat coverage
```

## Security Guidelines

### Security Best Practices

- **Never commit private keys** or sensitive data
- **Validate all inputs** thoroughly
- **Use established libraries** (OpenZeppelin, etc.)
- **Follow principle of least privilege**
- **Implement proper access controls**

### Security Review Process

1. **Self-review** your code for security issues
2. **Run security tools** (slither, mythril, etc.)
3. **Request security review** for critical changes
4. **Test locally** extensively

### Reporting Security Issues

**DO NOT** create public issues for security vulnerabilities. Instead:

1. Email security@splendor.org with details
2. Include steps to reproduce
3. Provide suggested fixes if possible
4. Allow time for responsible disclosure

## Pull Request Process

### Before Submitting

1. **Ensure tests pass** locally
2. **Update documentation** as needed
3. **Follow coding standards**
4. **Rebase on latest main** branch

### PR Requirements

- **Clear title and description**
- **Link to related issues**
- **Include test coverage**
- **Update relevant documentation**
- **Pass all CI checks**

### Review Process

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Security review** for sensitive changes
4. **Testing** locally if applicable
5. **Approval** from core team

### After Approval

- **Squash commits** if requested
- **Update branch** if needed
- **Merge** will be handled by maintainers

## Development Workflow

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring

### Commit Messages

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Examples:
- `feat(consensus): add validator rotation mechanism`
- `fix(rpc): resolve connection timeout issues`
- `docs(api): update JSON-RPC documentation`

### Release Process

1. **Version bump** in package.json
2. **Update CHANGELOG.md**
3. **Create release notes**
4. **Tag release** with semantic version
5. **Deploy locally** first for testing
6. **Deploy to mainnet** after validation

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Discord**: Real-time community chat
- **Twitter**: Updates and announcements

### Getting Help

- **Documentation**: Check our comprehensive docs
- **GitHub Issues**: Search existing issues
- **Community**: Ask in Discord or discussions
- **Support**: Contact team for urgent issues

### Recognition

Contributors will be:

- **Listed** in our contributors file
- **Mentioned** in release notes
- **Invited** to community events
- **Considered** for core team positions

## License

By contributing to Splendor Blockchain V4, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

Thank you for contributing to Splendor Blockchain! Together, we're building the future of decentralized technology.
