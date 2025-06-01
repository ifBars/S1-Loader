# S1 Loader - Advanced Branch Manager

## 📋 Overview

The **S1 Loader** is a batch script tool designed to manage dual installations of **Schedule I** across both **IL2CPP** and **Mono** Unity backend branches. This tool enables developers and modders to seamlessly switch between different game versions while maintaining full Steam integration and update capabilities.

Unlike traditional approaches that require manual file copying, with little to no Steam integration, this tool uses advanced directory junction techniques and manifest swapping to provide a integrated development environment for Schedule I modding and testing.

## 🎯 Key Features

- **Dual Branch Management**: Maintain separate IL2CPP and Mono installations simultaneously
- **Steam Integration**: Preserve Steam's ability to update each branch independently
- **Developer-Friendly**: Integrated workflow for mod development with conditional compilation
- **Safety First**: Backup creation and integrity verification
- **Zero Downtime**: Instant switching between branches without re-downloading
- **Automated Setup**: Guided configuration process for first-time users

Having both branches available allows developers to:
- Debug issues with dotTrace on Mono
- Develop mods that work across both versions

## ⚙️ How It Works

The Schedule I Loader uses a combination of Windows directory junctions and Steam manifest manipulation:

### Technical Implementation
1. **Directory Structure**: Creates separate folders for each branch (`Schedule I_public`, `Schedule I_alternate`)
2. **Manifest Backup**: Preserves Steam's app manifest files for each branch version
3. **Junction Links**: Uses `mklink /J` to create seamless directory switching

### Steam Integration
- Steam tracks installations via game folders and manifest files (`appmanifest_<ID>.acf`)
- The tool swaps these components atomically to switch active branches (Steam won't see a situation where, for example, the directory points to the IL2CPP branch but has the Mono manifest, or vice versa)
- Each branch maintains its own update state and Steam integration
- No loss of achievements, cloud saves, or Steam features

## 🚀 Quick Start

### Prerequisites
- Windows 10/11
- Schedule I installed via Steam
- At least 2x the game's disk space for dual installation

### Initial Setup
1. **Download the Script**: Place `s1-loader.bat` in a dedicated folder
2. **Run the script**: Double-click the script to start it
3. **Choose Option 1**: "Initial Setup (First Time)"
4. **Follow the Wizard**: The script will guide you through the entire process

The setup process will:
- Detect your Steam installation automatically
- Create safety backups of your current installation
- Set up branch folders and manifest backups
- Guide you through Steam branch switching
- Verify the complete setup

## 🛠️ Developer Workflow with Conditional Compilation

The Schedule I Loader can integrate seamlessly with Visual Studio and MSBuild for mod development. Use conditional compilation to build different versions of your mods to each branch folder:

### MSBuild Configuration

Add these PropertyGroups to your `.csproj` file (replace the ModsDir paths with your own):

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

### Build Configurations

Create the following build configurations in Visual Studio:
- **Il2cpp**: Builds for IL2CPP branch with appropriate preprocessor directives
- **Mono**: Builds for Mono branch with appropriate preprocessor directives

## 📁 Directory Structure

After setup, your Schedule I installation will look like this:

```
SteamLibrary/steamapps/
├── common/
│   ├── Schedule I/                    # Active branch (junction link)
│   ├── Schedule I_public/            # IL2CPP branch files
│   ├── Schedule I_alternate/              # Mono branch files
│   └── ...
├── appmanifest_3164500.acf          # Active manifest
├── appmanifest_3164500.acf_public   # IL2CPP manifest backup
├── appmanifest_3164500.acf_alternate     # Mono manifest backup
└── ...
```

## 🔍 Troubleshooting

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
- Restore from backup
- Repair setup integrity

## 📋 Requirements

### System Requirements
- **OS**: Windows 10/11
- **Disk Space**: 2x game size (for dual installation)

### Software Requirements
- **Steam**: Latest version
- **Schedule I**: Installed via Steam

## 📜 License

This tool is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.