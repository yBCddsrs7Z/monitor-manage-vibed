# Documentation Index

Complete guide to all monitor-manage documentation.

## Quick Navigation

### 🚀 Getting Started
- **[README.md](README.md)** - Start here! Installation, quick start, basic usage
- **[CONFIGURATION.md](CONFIGURATION.md)** - Complete configuration reference

### 📚 Core Documentation
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design and architecture
- **[API_REFERENCE.md](API_REFERENCE.md)** - Complete function reference
- **[CONFIGURATION.md](CONFIGURATION.md)** - Configuration guide

### 👩‍💻 Development
- **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** - Contributing and development workflow
- **[TESTING.md](TESTING.md)** - Comprehensive testing guide

### 🔧 Troubleshooting & Support
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Problem-solving guide
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes

### 📁 Additional Resources
- **[tests/README.md](tests/README.md)** - Test suite overview

---

## Documentation by Topic

### Installation & Setup

**Getting Started**:
1. [README.md § Installation](README.md#installation-and-setup) - Installation steps
2. [README.md § First-Time Setup](README.md#first-time-setup-guide) - Initial configuration
3. [README.md § Verify Installation](README.md#verify-installation) - Validation

**Troubleshooting**:
- [TROUBLESHOOTING.md § Installation Issues](TROUBLESHOOTING.md#installation-issues)

### Configuration

**Complete Reference**:
- [CONFIGURATION.md](CONFIGURATION.md) - Everything about configuration

**Topics**:
- [Profiles](CONFIGURATION.md#profiles) - Monitor/audio profiles
- [Hotkeys](CONFIGURATION.md#hotkeys) - Keyboard shortcuts
- [Overlay](CONFIGURATION.md#overlay) - Appearance settings
- [Settings](CONFIGURATION.md#settings) - Global settings
- [Examples](CONFIGURATION.md#examples) - Real-world configs

**Related**:
- [README.md § Configuration Reference](README.md#configuration-reference)
- [TROUBLESHOOTING.md § Configuration Issues](TROUBLESHOOTING.md#configuration-issues)

### Usage

**Basic Usage**:
- [README.md § Default Hotkeys](README.md#default-hotkeys)
- [README.md § Configuring Profiles](README.md#configuring-profiles)
- [README.md § Switching Behaviour](README.md#switching-behaviour)

**Advanced**:
- [README.md § Run on Startup](README.md#run-on-startup-optional)
- [CONFIGURATION.md § Examples](CONFIGURATION.md#examples)

### Architecture & Design

**System Overview**:
- [ARCHITECTURE.md](ARCHITECTURE.md) - Complete architecture documentation

**Topics**:
- [Component Breakdown](ARCHITECTURE.md#component-breakdown)
- [Data Flow](ARCHITECTURE.md#data-flow)
- [Configuration Schema](ARCHITECTURE.md#configuration-schema)
- [State Management](ARCHITECTURE.md#state-management)
- [Error Handling](ARCHITECTURE.md#error-handling-strategy)
- [Performance](ARCHITECTURE.md#performance-considerations)
- [Security](ARCHITECTURE.md#security-considerations)
- [Extensibility](ARCHITECTURE.md#extensibility-points)

### API Reference

**Function Documentation**:
- [API_REFERENCE.md](API_REFERENCE.md) - All functions documented

**By Component**:
- [AutoHotkey Functions](API_REFERENCE.md#autohotkey-functions)
  - [Core Functions](API_REFERENCE.md#core-profile-management)
  - [Configuration](API_REFERENCE.md#configuration)
  - [Hotkey Management](API_REFERENCE.md#hotkey-management)
  - [UI Functions](API_REFERENCE.md#ui-functions)
  - [Utility Functions](API_REFERENCE.md#utility-functions)
- [PowerShell Functions](API_REFERENCE.md#powershell-functions)
  - [switch_profile.ps1](API_REFERENCE.md#switch_profileps1)
  - [configure_profiles.ps1](API_REFERENCE.md#configure_profilesps1)
  - [export_devices.ps1](API_REFERENCE.md#export_devicesps1)
  - [Validate-Config.ps1](API_REFERENCE.md#validate-configps1)

### Development

**Getting Started with Development**:
1. [DEVELOPER_GUIDE.md § Development Setup](DEVELOPER_GUIDE.md#development-setup)
2. [DEVELOPER_GUIDE.md § Project Structure](DEVELOPER_GUIDE.md#project-structure)
3. [DEVELOPER_GUIDE.md § Coding Standards](DEVELOPER_GUIDE.md#coding-standards)

**Contributing**:
- [DEVELOPER_GUIDE.md § Contributing](DEVELOPER_GUIDE.md#contributing)
- [DEVELOPER_GUIDE.md § Pull Request Guidelines](DEVELOPER_GUIDE.md#pull-request-guidelines)

**Common Tasks**:
- [DEVELOPER_GUIDE.md § Adding New Profile Field](DEVELOPER_GUIDE.md#adding-a-new-profile-field)
- [DEVELOPER_GUIDE.md § Adding New Hotkey Action](DEVELOPER_GUIDE.md#adding-a-new-hotkey-action)
- [DEVELOPER_GUIDE.md § Performance Optimization](DEVELOPER_GUIDE.md#performance-optimization)

### Testing

**Running Tests**:
- [TESTING.md § Running Tests](TESTING.md#running-tests)
- [README.md § Testing](README.md#testing)

**Writing Tests**:
- [TESTING.md § Writing Tests](TESTING.md#writing-tests)
- [TESTING.md § Testing Best Practices](TESTING.md#testing-best-practices)

**Test Coverage**:
- [TESTING.md § Test Suite Structure](TESTING.md#test-suite-structure)
- [TESTING.md § Test Coverage](TESTING.md#test-coverage)
- [tests/README.md](tests/README.md) - Test suite overview

**CI/CD**:
- [TESTING.md § Continuous Integration](TESTING.md#continuous-integration)

### Troubleshooting

**By Issue Type**:
- [Installation Issues](TROUBLESHOOTING.md#installation-issues)
- [Display Issues](TROUBLESHOOTING.md#display-issues)
- [Audio Issues](TROUBLESHOOTING.md#audio-issues)
- [Hotkey Issues](TROUBLESHOOTING.md#hotkey-issues)
- [Configuration Issues](TROUBLESHOOTING.md#configuration-issues)
- [Performance Issues](TROUBLESHOOTING.md#performance-issues)

**Diagnostics**:
- [Logging and Diagnostics](TROUBLESHOOTING.md#logging-and-diagnostics)
- [Quick Reference](TROUBLESHOOTING.md#quick-reference)

**Getting Help**:
- [TROUBLESHOOTING.md § Getting Help](TROUBLESHOOTING.md#getting-help)

---

## Documentation by Role

### 👤 End User

If you just want to **use** monitor-manage:

**Must Read**:
1. [README.md](README.md) - Installation and basic usage
2. [README.md § First-Time Setup](README.md#first-time-setup-guide) - Initial configuration
3. [README.md § Default Hotkeys](README.md#default-hotkeys) - Keyboard shortcuts

**Nice to Have**:
- [CONFIGURATION.md](CONFIGURATION.md) - If you want to customize
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - When things don't work

**Skip**:
- Developer Guide, API Reference, Testing, Architecture (unless curious!)

### 🔧 Power User

If you want to **customize** and **configure** extensively:

**Essential**:
1. [README.md](README.md) - Basic understanding
2. [CONFIGURATION.md](CONFIGURATION.md) - Complete config reference
3. [README.md § Configuration Reference](README.md#configuration-reference) - Quick reference

**Recommended**:
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Self-service problem solving
- [ARCHITECTURE.md § Configuration Schema](ARCHITECTURE.md#configuration-schema) - Deep dive

**Optional**:
- [API_REFERENCE.md](API_REFERENCE.md) - If you want to understand internals

### 👩‍💻 Contributor

If you want to **contribute code** or **fix bugs**:

**Must Read**:
1. [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - Development workflow
2. [ARCHITECTURE.md](ARCHITECTURE.md) - System design
3. [API_REFERENCE.md](API_REFERENCE.md) - Function reference
4. [TESTING.md](TESTING.md) - Testing guide

**Before First PR**:
- [DEVELOPER_GUIDE.md § Coding Standards](DEVELOPER_GUIDE.md#coding-standards)
- [DEVELOPER_GUIDE.md § Contributing](DEVELOPER_GUIDE.md#contributing)
- [TESTING.md § Writing Tests](TESTING.md#writing-tests)

**Reference**:
- [CONFIGURATION.md](CONFIGURATION.md) - Config structure
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Known issues
- [CHANGELOG.md](CHANGELOG.md) - Project history

### 🏗️ System Administrator

If you're **deploying** or **supporting** monitor-manage:

**Deployment**:
1. [README.md § Installation](README.md#installation-and-setup)
2. [README.md § Requirements](README.md#requirements)
3. [ARCHITECTURE.md § Deployment Architecture](ARCHITECTURE.md#deployment-architecture)

**Support**:
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem resolution
- [TROUBLESHOOTING.md § Diagnostics](TROUBLESHOOTING.md#logging-and-diagnostics) - Log collection
- [README.md § Testing](README.md#testing) - Validation

**Configuration**:
- [CONFIGURATION.md](CONFIGURATION.md) - Config management
- [ARCHITECTURE.md § Configuration Schema](ARCHITECTURE.md#configuration-schema) - Schema details

---

## Documentation Completeness

### ✅ Fully Documented

These areas have comprehensive documentation:

- ✅ **Installation & Setup** - README, Troubleshooting
- ✅ **Configuration** - Complete reference guide
- ✅ **Usage** - Hotkeys, profiles, switching behavior
- ✅ **Architecture** - System design, data flow, components
- ✅ **API** - All functions documented with examples
- ✅ **Development** - Coding standards, workflow, common tasks
- ✅ **Testing** - Writing tests, running tests, CI/CD
- ✅ **Troubleshooting** - Common issues, diagnostics, solutions
- ✅ **AutoHotkey v2 Migration** - Syntax changes documented

### 📝 Areas for Expansion

Potential future documentation topics:

- 🔄 **Migration Guides** - Upgrading from older versions
- 🎯 **Use Case Guides** - Specific scenarios (gaming, streaming, etc.)
- 🎨 **Customization Gallery** - Example configs with screenshots
- 📊 **Performance Tuning** - Advanced optimization
- 🔐 **Security Best Practices** - Hardening and security
- 🌐 **Integration Guides** - Steam Input, external tools
- 📱 **Remote Control** - Mobile app integration ideas

---

## Quick Links by Question

### "How do I...?"

**...install monitor-manage?**
→ [README.md § Installation](README.md#installation-and-setup)

**...configure my first profile?**
→ [README.md § First-Time Setup](README.md#first-time-setup-guide)

**...change hotkeys?**
→ [CONFIGURATION.md § Hotkeys](CONFIGURATION.md#hotkeys)

**...customize the overlay?**
→ [CONFIGURATION.md § Overlay](CONFIGURATION.md#overlay)

**...run on startup?**
→ [README.md § Run on Startup](README.md#run-on-startup-optional)

**...troubleshoot display issues?**
→ [TROUBLESHOOTING.md § Display Issues](TROUBLESHOOTING.md#display-issues)

**...contribute to the project?**
→ [DEVELOPER_GUIDE.md § Contributing](DEVELOPER_GUIDE.md#contributing)

**...run tests?**
→ [TESTING.md § Running Tests](TESTING.md#running-tests)

**...understand the architecture?**
→ [ARCHITECTURE.md](ARCHITECTURE.md)

**...find function documentation?**
→ [API_REFERENCE.md](API_REFERENCE.md)

### "Where is...?"

**...the configuration file?**
→ `config.json` in project root ([CONFIGURATION.md](CONFIGURATION.md))

**...the log file?**
→ `monitor-toggle.log` in project root ([TROUBLESHOOTING.md § Logging](TROUBLESHOOTING.md#logging-and-diagnostics))

**...the device snapshot?**
→ `devices_snapshot.json` in project root ([API_REFERENCE.md](API_REFERENCE.md))

**...the test suite?**
→ `tests/` directory ([TESTING.md](TESTING.md))

**...the PowerShell scripts?**
→ `scripts/` directory ([ARCHITECTURE.md § Project Structure](ARCHITECTURE.md#component-breakdown))

### "What is...?"

**...a profile?**
→ Monitor/audio configuration ([README.md § Overview](README.md#overview))

**...the overlay?**
→ On-screen summary display ([CONFIGURATION.md § Overlay](CONFIGURATION.md#overlay))

**...a hotkey descriptor?**
→ Human-readable hotkey format ([CONFIGURATION.md § Hotkey Descriptor Format](CONFIGURATION.md#hotkey-descriptor-format))

**...the panic button?**
→ Enable-all hotkey (Alt+Shift+8) ([README.md § Default Hotkeys](README.md#default-hotkeys))

**...device snapshot?**
→ Hardware inventory JSON ([API_REFERENCE.md § export_devices.ps1](API_REFERENCE.md#export_devicesps1))

---

## Contributing to Documentation

### Documentation Standards

- **Markdown**: Use GitHub Flavored Markdown
- **Formatting**: Follow existing style
- **Examples**: Include practical examples
- **Links**: Use relative links between docs
- **TOC**: Include table of contents for long docs

### How to Improve Documentation

1. **Found an error?** - Open an issue
2. **Want to clarify?** - Submit a PR
3. **Missing information?** - Request in Discussions
4. **Have examples?** - Add to relevant doc

### Documentation Review Checklist

When updating documentation:
- [ ] Information accurate and up-to-date
- [ ] Code examples tested
- [ ] Links work (relative links preferred)
- [ ] Spelling and grammar checked
- [ ] Consistent with other docs
- [ ] Added to this index if new file
- [ ] Updated CHANGELOG.md if significant

---

## Version History

| Version | Date | Documentation Changes |
|---------|------|----------------------|
| Current | 2025-10-11 | Complete documentation overhaul |
| 1.0.0 | 2025-10-03 | Added CHANGELOG, test docs, CI/CD docs |
| 0.1.0 | 2025-09-28 | Initial README, configuration docs |

---

## Feedback

Have suggestions for documentation improvements?
- 💬 [Open a Discussion](https://github.com/yBCddsrs7Z/monitor-manage-vibed/discussions)
- 🐛 [Report Documentation Issue](https://github.com/yBCddsrs7Z/monitor-manage-vibed/issues)
- 📧 Contact maintainers (see README)

---

**Last Updated**: 2025-10-11  
**Documentation Version**: 1.1  
**Project Version**: Current
