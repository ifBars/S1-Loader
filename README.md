# S1 Loader - Advanced Branch Manager

## 📋 Overview

The **S1 Loader** is a batch script tool designed to manage dual installations of **Schedule I** across both **IL2CPP** and **Mono** Unity backend branches. This tool enables developers and modders to seamlessly switch between different game versions while maintaining full Steam integration and update capabilities.

Unlike traditional approaches that require manual file copying with lose Steam integration, this tool uses advanced directory junction techniques and manifest swapping to provide a integrated development environment for Schedule I modding and testing.

---

## 🎯 Key Features

- **Dual Branch Management**: Maintain separate IL2CPP and Mono installations simultaneously
- **Steam Integration**: Preserve Steam's ability to update each branch independently
- **Developer-Friendly**: Integrated workflow for mod development with conditional compilation
- **Safety First**: Backup creation and integrity verification
- **Zero Downtime**: Instant switching between branches without re-downloading
- **Automated Setup**: Guided configuration process for first-time users

---

## 🧠 Why IL2CPP vs Mono for Schedule I?

Schedule I, like many Unity-based games, offers different backend compilation options:

### IL2CPP Branch (Production)
- **Debugging**: Harder to debug and analyze
- **Modding**: Less accessible for modding
- **Distribution**: Standard release branch for end users

### Mono Branch (Development)
- **Debugging**: Easier to debug and analyze
- **Modding**: More accessible for reverse engineering and modding
- **Tool Compatibility**: Better compatibility with debugging and analysis tools (dotTrace)

Having both branches available allows developers to:
- Test mods against both runtime environments
- Debug issues with dotTrace on Mono
- Develop mods that work across both versions

---

## ⚙️ How It Works

The Schedule I Loader uses a combination of Windows directory junctions and Steam manifest manipulation:

### Technical Implementation
1. **Directory Structure**: Creates separate folders for each branch (`Schedule I_il2cpp`, `Schedule I_mono`)
2. **Manifest Backup**: Preserves Steam's app manifest files for each branch version
3. **Junction Links**: Uses `mklink /J` to create seamless directory switching
4. **Atomic Operations**: Ensures Steam always sees a consistent game state

### Steam Integration
- Steam tracks installations via game folders and manifest files (`appmanifest_<ID>.acf`)
- The tool swaps these components atomically to switch active branches
- Each branch maintains its own update state and Steam integration
- No loss of achievements, cloud saves, or Steam features

---

## 🚀 Quick Start

### Prerequisites
- Windows 10/11
- Schedule I installed via Steam
- Administrator privileges (for junction creation)
- At least 2x the game's disk space for dual installation

### Initial Setup
1. **Download the Script**: Place `s1-loader.bat` in a dedicated folder
2. **Run as Administrator**: Right-click → "Run as administrator"
3. **Choose Option 1**: "Initial Setup (First Time)"
4. **Follow the Wizard**: The script will guide you through the entire process

The setup process will:
- Detect your Steam installation automatically
- Create safety backups of your current installation
- Set up branch folders and manifest backups
- Guide you through Steam branch switching
- Verify the complete setup

---

## 🛠️ Developer Workflow with Conditional Compilation

The Schedule I Loader integrates seamlessly with Visual Studio and MSBuild for mod development. Use conditional compilation to build different versions of your mods for each branch:

### MSBuild Configuration

Add these PropertyGroups to your `.csproj` file:

```xml
<PropertyGroup Condition="'$(Configuration)' == 'Il2cpp'">
    <DefineConstants>$(DefineConstants);IL2CPP</DefineConstants>
    <AssemblyName>YourMod_Il2CPP</AssemblyName>
    <ModsDir>D:\SteamLibrary\steamapps\common\Schedule I_il2cpp\Mods</ModsDir>
</PropertyGroup>

<PropertyGroup Condition="'$(Configuration)' == 'Mono'">
    <DefineConstants>$(DefineConstants);MONO</DefineConstants>
    <AssemblyName>YourMod_Mono</AssemblyName>
    <ModsDir>D:\SteamLibrary\steamapps\common\Schedule I_mono\Mods</ModsDir>
</PropertyGroup>

<Target Name="PostBuild" AfterTargets="PostBuildEvent">
    <Exec Command="COPY &quot;$(TargetPath)&quot; &quot;$(ModsDir)&quot;" />
</Target>
```

### Code Example with Conditional Compilation

```csharp
using System;
using UnityEngine;

#if IL2CPP
using Il2CppInterop.Runtime;
using Il2CppInterop.Runtime.InteropTypes.Arrays;
#endif

namespace YourMod
{
    public class ModManager
    {
        public void Initialize()
        {
#if IL2CPP
            // IL2CPP-specific initialization
            Il2CppInteropManager.Initialize();
            Console.WriteLine("Mod initialized for IL2CPP backend");
#elif MONO
            // Mono-specific initialization
            AppDomain.CurrentDomain.AssemblyResolve += OnAssemblyResolve;
            Console.WriteLine("Mod initialized for Mono backend");
#endif
        }

#if MONO
        private Assembly OnAssemblyResolve(object sender, ResolveEventArgs args)
        {
            // Mono-specific assembly resolution
            return null;
        }
#endif
    }
}
```

### Build Configurations

Create the following build configurations in Visual Studio:
- **Il2cpp**: Builds for IL2CPP branch with appropriate preprocessor directives
- **Mono**: Builds for Mono branch with appropriate preprocessor directives

---

## 📁 Directory Structure

After setup, your Schedule I installation will look like this:

```
SteamLibrary/steamapps/
├── common/
│   ├── Schedule I/                    # Active branch (junction link)
│   ├── Schedule I_il2cpp/            # IL2CPP branch files
│   ├── Schedule I_mono/              # Mono branch files
│   └── ...
├── appmanifest_3164500.acf          # Active manifest
├── appmanifest_3164500.acf_il2cpp   # IL2CPP manifest backup
├── appmanifest_3164500.acf_mono     # Mono manifest backup
└── ...
```

---

## 🔧 Advanced Usage

### Command Line Options
The script supports several advanced features:

1. **Initial Setup**: Complete first-time configuration
2. **Repair/Verify**: Check and repair existing setup
3. **Update All Branches**: Update both branches independently
4. **Launch with Steam**: Start the game through Steam
5. **Launch Locally**: Direct game execution
6. **Backup Management**: Create and restore game backups

### Branch Switching
Switching between branches is instantaneous and preserves:
- Game saves and progress
- Steam achievements and stats
- Custom settings and configurations
- Mod installations (per branch)

### Backup Management
The tool includes comprehensive backup features:
- Automatic backup creation during setup
- Manual backup creation and restoration
- Backup integrity verification
- Metadata tracking for backup organization

---

## 🔍 Troubleshooting

### Common Issues

**"Could not locate Steam installation"**
- Ensure Steam is installed in the default location
- Run the script as Administrator
- Manually specify Steam path if needed

**"Game folder not found"**
- Verify Schedule I is installed via Steam
- Check that the game name matches exactly
- Ensure the game is in the default Steam library

**"Junction creation failed"**
- Run the script as Administrator
- Check available disk space
- Verify NTFS file system (junctions require NTFS)

**"Steam not recognizing game"**
- Restart Steam after branch switching
- Verify manifest files are present
- Run Steam Library verification if needed

### Recovery Options
If something goes wrong, the tool provides several recovery mechanisms:
- Restore from automatic backups
- Repair setup integrity
- Reset to original Steam installation
- Manual cleanup procedures

---

## 🛡️ Safety Features

- **Automatic Backups**: Original installation is always preserved
- **Integrity Checks**: Verification of all setup components
- **Rollback Capability**: Easy restoration to original state
- **Non-Destructive**: Never modifies original Steam files
- **Error Recovery**: Comprehensive error handling and recovery options

---

## 📋 Requirements

### System Requirements
- **OS**: Windows 10/11
- **File System**: NTFS (required for directory junctions)
- **Privileges**: Administrator access for junction creation
- **Disk Space**: 2x game size (for dual installation)

### Software Requirements
- **Steam**: Latest version
- **Schedule I**: Installed via Steam
- **PowerShell**: Version 5.0 or later (included with Windows)

---

## 🤝 Contributing

This tool is designed to be extensible and maintainable. When contributing:

1. **Follow PowerShell best practices**
2. **Maintain backward compatibility**
3. **Add comprehensive error handling**
4. **Update documentation for new features**
5. **Test with different Steam configurations**

---

## ⚠️ Important Notes

- **Administrative Privileges**: Required for directory junction creation
- **Disk Space**: Ensure adequate space for dual installations
- **Steam Integration**: Tool works with official Steam installations
- **Backup Strategy**: Always maintain backups of important saves
- **Antivirus**: Some antivirus software may flag junction operations

---

## 📜 License

This tool is provided as-is for educational and development purposes. Use at your own discretion and always maintain backups of important data.

---

## 🎮 Happy Modding!

The Schedule I Loader streamlines the development workflow for Schedule I modding and testing. Whether you're developing mods, analyzing game behavior, or testing across different Unity backends, this tool provides a professional foundation for your development environment.

For support, issues, or feature requests, please refer to the documentation or community resources.
