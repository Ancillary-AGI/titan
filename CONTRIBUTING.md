# Contributing to Titan Browser

We welcome contributions to Titan Browser! This document provides comprehensive guidelines for contributing to the project.

## 🚀 Quick Start

```bash
# Fork and clone the repository
git clone https://github.com/yourusername/titan-browser.git
cd titan-browser

# Set up development environment
make dev-setup

# Run tests to ensure everything works
make test

# Start developing!
make run
```

## 📋 Development Setup

### Prerequisites
- **Flutter SDK**: 3.16.0 or later
- **Rust toolchain**: 1.75.0 or later
- **Git**: Latest version
- **Make**: For build automation
- **Docker**: For containerized builds (optional)

### IDE Setup
We recommend **VS Code** with these extensions:
- Flutter
- Rust Analyzer
- GitLens
- Error Lens

## 🏗️ Project Structure

```
titan-browser/
├── lib/                    # Flutter application code
│   ├── core/              # Core utilities and services
│   ├── models/            # Data models
│   ├── services/          # Business logic services
│   ├── screens/           # UI screens
│   └── widgets/           # Reusable UI components
├── rust_engine/           # Rust browser engine
├── test/                  # Test files
├── .github/workflows/     # CI/CD pipelines
└── docs/                  # Documentation
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
make test

# Run specific test categories
flutter test test/services/
flutter test test/widgets/
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

### Writing Tests
- **Unit tests**: Test individual functions and classes
- **Widget tests**: Test UI components
- **Integration tests**: Test complete user workflows
- **Platform tests**: Test platform-specific functionality

Example test structure:
```dart
void main() {
  group('ServiceName Tests', () {
    late ServiceName service;
    
    setUp(() {
      service = ServiceName();
    });
    
    test('should perform expected behavior', () {
      // Arrange
      final input = 'test input';
      
      // Act
      final result = service.performAction(input);
      
      // Assert
      expect(result, equals('expected output'));
    });
  });
}
```

## 📝 Code Style

### Dart Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for automatic formatting
- Run `flutter analyze` to check for issues
- Maximum line length: 80 characters
- Use meaningful names for variables and functions

### Rust Code Style
- Follow [Rust style guide](https://doc.rust-lang.org/1.0.0/style/)
- Use `cargo fmt` for formatting
- Run `cargo clippy` for linting
- Write documentation comments for public APIs

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
type(scope): description

feat(browser): add tab management functionality
fix(security): resolve XSS vulnerability in URL parser
docs(readme): update installation instructions
test(ai): add unit tests for AI service
```

## 🔄 Pull Request Process

### Before Submitting
1. **Create a feature branch**: `git checkout -b feature/your-feature-name`
2. **Write tests**: Ensure your code is well-tested
3. **Run quality checks**: `make lint analyze test`
4. **Update documentation**: Add/update relevant docs
5. **Test on multiple platforms**: Ensure cross-platform compatibility

### PR Requirements
- [ ] All tests pass
- [ ] Code coverage maintained (>80%)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No merge conflicts
- [ ] Follows code style guidelines

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

## 🐛 Bug Reports

Use the bug report template:
```markdown
**Bug Description**
Clear description of the bug

**Steps to Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: [e.g., Windows 11]
- Flutter version: [e.g., 3.16.0]
- Titan version: [e.g., 1.0.0]

**Screenshots**
If applicable, add screenshots
```

## 💡 Feature Requests

Use the feature request template:
```markdown
**Feature Description**
Clear description of the feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should this feature work?

**Alternatives Considered**
Other solutions you've considered

**Additional Context**
Any other relevant information
```

## 🏷️ Issue Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Improvements to documentation
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention is needed
- `priority:high`: High priority issue
- `platform:windows`: Windows-specific
- `platform:macos`: macOS-specific
- `platform:linux`: Linux-specific

## 🚀 Release Process

1. **Version Bump**: Update version in `pubspec.yaml`
2. **Changelog**: Update `CHANGELOG.md`
3. **Tag Release**: Create git tag `git tag v1.0.0`
4. **CI/CD**: Automated build and release
5. **Documentation**: Update release notes

## 🤝 Code of Conduct

### Our Pledge
We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards
- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

### Enforcement
Instances of abusive behavior may be reported to the project maintainers.

## 📄 License

By contributing to Titan Browser, you agree that your contributions will be licensed under the MIT License.

## 🆘 Getting Help

- **GitHub Discussions**: Use GitHub Discussions for questions
- **Issues**: Create issues for bugs and feature requests
- **Email**: Contact maintainers at dev@titan-browser.com

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Annual contributor highlights

Thank you for contributing to Titan Browser! 🎉