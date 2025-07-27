# Mouse Jiggler

![jiggle](https://github.com/user-attachments/assets/80ede37f-942a-44d8-a4a0-1c5e02558659)


A simple and effective mouse jiggler application built with PowerShell and Windows Forms to prevent your computer from going idle.

## Features

- **Prevents computer from going idle** by simulating mouse movement
- **Customizable idle timeout** - set how long to wait before jiggling (default: 5 minutes)
- **Visual countdown timer** - shows time remaining until next jiggle
- **Multiple jiggle modes**:
  - Mouse movement in a circular pattern
  - Shift key press (invisible to most applications)
- **Clean GUI interface** built with Windows Forms
- **System tray integration** for minimized operation
- **Compiled executable** - no PowerShell required to run

## Files

- `MouseJiggler.ps1` - The main PowerShell script
- `MouseJiggler.exe` - Compiled executable (ready to run)
- `PS2EXE-master/` - PS2EXE tool used for compilation

## Usage

### Running the Executable
Simply double-click `MouseJiggler.exe` to run the application. No additional software required.

### Running the PowerShell Script
1. Open PowerShell as Administrator
2. Set execution policy: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
3. Run the script: `powershell -ExecutionPolicy Bypass -STA -File "MouseJiggler.ps1"`

## Configuration

- **Idle Timeout**: Adjustable from 1 minute to 60 minutes
- **Jiggle Method**: Choose between mouse movement or shift key press
- **Auto-minimize**: Option to minimize to system tray

## Requirements

- Windows operating system
- .NET Framework (for the executable version)
- PowerShell 5.1+ (for the script version)

## Building from Source

The executable was built using PS2EXE with the following parameters:
```powershell
Invoke-ps2exe -inputFile "MouseJiggler.ps1" -outputFile "MouseJiggler.exe" -noConsole -STA -title "Mouse Jiggler" -description "Prevents computer from going idle by moving mouse cursor" -version "1.0.0"
```

## License

This project is open source. Feel free to modify and distribute.

## Author

Created with PowerShell and Windows Forms.
Compiled using PS2EXE by Markus Scholtes.
