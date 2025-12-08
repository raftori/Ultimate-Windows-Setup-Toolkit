# Contributing Guide

Thank you for your interest in contributing to the Ultimate Windows Setup Toolkit!

## How to Contribute

### Reporting Bugs

1. Check existing issues to avoid duplicates
2. Create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - Windows version and PowerShell version
   - Screenshots if applicable

### Suggesting Features

1. Check existing issues for similar suggestions
2. Create a new issue with:
   - Clear description of the feature
   - Use case/problem it solves
   - Possible implementation approach

### Submitting Code

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request

## Code Guidelines

### PowerShell Style

- Use approved verbs (`Get-`, `Set-`, `New-`, `Remove-`, etc.)
- Include comment-based help for functions
- Use proper error handling
- Follow PowerShell naming conventions

**Example:**
```powershell
function Get-Something {
    <#
    .SYNOPSIS
        Brief description
    .DESCRIPTION
        Detailed description
    .PARAMETER Name
        Parameter description
    .EXAMPLE
        Get-Something -Name "Test"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        # Implementation
    }
    catch {
        Write-Log "Error: $($_.Exception.Message)" -Level ERROR
    }
}
```

### Module Structure

- Place functions in appropriate modules
- Export public functions with `Export-ModuleMember`
- Keep private/helper functions unexported
- Use consistent parameter names

### Menu Guidelines

- Follow existing menu format
- Use consistent color coding
- Provide clear option descriptions
- Include back/exit options

### Testing

Before submitting:
1. Test on Windows 10 and 11
2. Test with PowerShell 5.1 and 7.x
3. Verify all menu options work
4. Check logs for errors
5. Test both admin and non-admin scenarios

## Adding Applications

To add new applications to the catalog:

1. Edit `configs/apps.json`
2. Follow the existing format:
```json
{
    "Name": "Application Name",
    "WingetId": "Publisher.AppName",
    "ChocoId": "package-name",
    "Description": "Brief description"
}
```
3. Verify the package IDs are correct:
   - Winget: `winget search "app name"`
   - Chocolatey: Search on chocolatey.org
4. Test the installation

## Adding Optimizations

To add new optimizations:

1. Add to appropriate module (SystemOptimizer.psm1)
2. Include registry backup before changes
3. Add logging for all changes
4. Document what the optimization does
5. Consider hardware requirements

## Documentation

- Update README.md for new features
- Update relevant docs in /docs folder
- Include examples where helpful
- Keep language clear and concise

## Pull Request Checklist

- [ ] Code follows style guidelines
- [ ] Functions have proper documentation
- [ ] Changes are tested
- [ ] No hardcoded paths (use environment variables)
- [ ] Errors are handled gracefully
- [ ] Changes are logged appropriately
- [ ] Documentation is updated

## Questions?

Open an issue with the "question" label.

---

Thank you for contributing!
