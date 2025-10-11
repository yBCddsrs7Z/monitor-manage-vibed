# Documentation Quick Start

**New to monitor-manage?** Start here!

## 📖 Where to Start

### 🎯 I want to USE the software
**Start**: [README.md](README.md)  
**Follow**: [Installation](README.md#installation-and-setup) → [First-Time Setup](README.md#first-time-setup-guide) → [Default Hotkeys](README.md#default-hotkeys)  
**If stuck**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### ⚙️ I want to CONFIGURE it
**Start**: [CONFIGURATION.md](CONFIGURATION.md)  
**Topics**: [Profiles](CONFIGURATION.md#profiles) · [Hotkeys](CONFIGURATION.md#hotkeys) · [Overlay](CONFIGURATION.md#overlay) · [Examples](CONFIGURATION.md#examples)  
**Quick**: Use configurator - Press `Left Alt+Left Shift+9`

### 👨‍💻 I want to CONTRIBUTE
**Start**: [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)  
**Setup**: [Development Setup](DEVELOPER_GUIDE.md#development-setup) → [Coding Standards](DEVELOPER_GUIDE.md#coding-standards) → [Testing](TESTING.md)  
**Reference**: [ARCHITECTURE.md](ARCHITECTURE.md) · [API_REFERENCE.md](API_REFERENCE.md)

### 🔍 I want to UNDERSTAND how it works
**Start**: [ARCHITECTURE.md](ARCHITECTURE.md)  
**Deep Dive**: [Component Breakdown](ARCHITECTURE.md#component-breakdown) → [Data Flow](ARCHITECTURE.md#data-flow) → [API Reference](API_REFERENCE.md)

### 🐛 I have a PROBLEM
**Start**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)  
**By Issue**: [Display](TROUBLESHOOTING.md#display-issues) · [Audio](TROUBLESHOOTING.md#audio-issues) · [Hotkeys](TROUBLESHOOTING.md#hotkey-issues) · [Config](TROUBLESHOOTING.md#configuration-issues)  
**Tools**: [Diagnostics](TROUBLESHOOTING.md#logging-and-diagnostics)

## 📚 Complete Documentation List

| Document | Purpose | Audience |
|----------|---------|----------|
| **[README.md](README.md)** | Installation, usage, getting started | Everyone |
| **[CONFIGURATION.md](CONFIGURATION.md)** | Complete config reference | Users |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Problem solving | Users |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | System design | Developers |
| **[API_REFERENCE.md](API_REFERENCE.md)** | Function documentation | Developers |
| **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** | Contributing | Contributors |
| **[TESTING.md](TESTING.md)** | Test guide | Developers |
| **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** | Navigation hub | Everyone |
| **[CHANGELOG.md](CHANGELOG.md)** | Version history | Everyone |

## ⚡ Quick Answers

**Q: How do I create my first profile?**  
A: Press `Left Alt+Left Shift+9`, select "Add new profile", follow prompts.

**Q: How do I switch profiles?**  
A: Press `Left Alt+Left Shift+1` (for profile 1), or `2`, `3`, etc.

**Q: How do I change hotkeys?**  
A: Edit [config.json hotkeys section](CONFIGURATION.md#hotkeys) or use configurator.

**Q: Why isn't my display working?**  
A: See [Display Issues](TROUBLESHOOTING.md#display-issues) or press `Left Alt+Left Shift+8` (enable all).

**Q: Where are the logs?**  
A: `monitor-toggle.log` in project root. See [Logging](TROUBLESHOOTING.md#logging-and-diagnostics).

**Q: How do I contribute?**  
A: Read [DEVELOPER_GUIDE.md § Contributing](DEVELOPER_GUIDE.md#contributing), then open PR.

**Q: Where's the test suite?**  
A: `tests/` directory. Run with: `pwsh -File tests/run-all-tests.ps1`

**Q: What's the project structure?**  
A: See [ARCHITECTURE.md § Component Breakdown](ARCHITECTURE.md#component-breakdown).

## 🔗 External Links

- **GitHub Repository**: [monitor-manage-vibed](https://github.com/yBCddsrs7Z/monitor-manage-vibed)
- **AutoHotkey v2**: [Download](https://www.autohotkey.com/v2/) · [Docs](https://www.autohotkey.com/docs/v2/)
- **PowerShell**: [Download](https://github.com/PowerShell/PowerShell) · [Docs](https://docs.microsoft.com/powershell/)
- **DisplayConfig Module**: [PowerShell Gallery](https://www.powershellgallery.com/packages/DisplayConfig)
- **AudioDeviceCmdlets Module**: [PowerShell Gallery](https://www.powershellgallery.com/packages/AudioDeviceCmdlets)

## 📝 Documentation Versions

| Version | Date | Changes |
|---------|------|---------|
| 1.1 | 2025-10-11 | Complete documentation overhaul - Added 7 new guides |
| 1.0 | 2025-10-03 | Added CHANGELOG, testing docs, CI/CD |
| 0.1 | 2025-09-28 | Initial README and configuration docs |

## 💡 Pro Tips

- **Browse all docs**: Check [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) for comprehensive navigation
- **Search functionality**: Use `Ctrl+F` within docs or GitHub's search
- **Offline reading**: Clone repo to read docs locally in Markdown viewer
- **Print version**: Convert docs to PDF using Markdown to PDF tools
- **Stay updated**: Check [CHANGELOG.md](CHANGELOG.md) for latest changes

## 🎓 Learning Path

### Beginner Path (1-2 hours)
1. [README.md](README.md) - Overview and installation
2. [README.md § First-Time Setup](README.md#first-time-setup-guide) - Configure first profile
3. [CONFIGURATION.md § Examples](CONFIGURATION.md#examples) - See real configs

### Intermediate Path (2-4 hours)
1. Complete Beginner Path
2. [CONFIGURATION.md](CONFIGURATION.md) - Full config reference
3. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
4. [README.md § Testing](README.md#testing) - Verify setup

### Advanced Path (4-8 hours)
1. Complete Intermediate Path
2. [ARCHITECTURE.md](ARCHITECTURE.md) - System design
3. [API_REFERENCE.md](API_REFERENCE.md) - Function reference
4. [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - Contributing
5. [TESTING.md](TESTING.md) - Testing methodology

---

**Need help?** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)  
**Want to explore?** → [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)  
**Ready to dive in?** → [README.md](README.md)
