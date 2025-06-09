<#
.SYNOPSIS
    项目快速命令设置脚本
.DESCRIPTION
    手动导入 Fast-Command.psm1 模块，提供快速命令功能和使用示例
    注意：此脚本需要在项目目录中运行，且导入的命令只在当前会话中有效
.AUTHOR
    Yujie Liu
.DATE
    2025/06/08
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$ShowExamples,
    
    [Parameter()]
    [switch]$Unload
)

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

# 模块路径
$FastCommandModulePath = Join-Path $PSScriptRoot "module\Fast-Command.psm1"

function Write-ColoredMessage {
    param(
        [string]$Message,
        [ConsoleColor]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Banner {
    Write-Host ""
    Write-ColoredMessage "╔══════════════════════════════════════════════════════════════╗" -Color Cyan
    Write-ColoredMessage "║                   项目快速命令设置工具                         ║" -Color Cyan
    Write-ColoredMessage "║                   Project Fast Command Setup                  ║" -Color Cyan
    Write-ColoredMessage "╚══════════════════════════════════════════════════════════════╝" -Color Cyan
    Write-Host ""
}

function Show-Usage {
    Write-ColoredMessage "✨ 快速命令使用说明:" -Color Green
    Write-Host ""
    Write-ColoredMessage "  创建文件命令:" -Color Yellow
    Write-Host "    new hello-world          # 创建默认 TypeScript 文件"
    Write-Host "    new -ts hello-world      # 创建 TypeScript 文件"
    Write-Host "    new -js hello-world      # 创建 JavaScript 文件"
    Write-Host "    new -py hello-world      # 创建 Python 文件"
    Write-Host "    new -java hello-world    # 创建 Java 文件"
    Write-Host "    new -rust hello-world    # 创建 Rust 文件"
    Write-Host "    new -ps hello-world      # 创建 PowerShell 文件"
    Write-Host ""
    Write-ColoredMessage "  打开文件命令:" -Color Yellow
    Write-Host "    open hello-world         # 打开默认 TypeScript 文件"
    Write-Host "    open -ts hello-world     # 打开 TypeScript 文件"
    Write-Host "    open -js hello-world     # 打开 JavaScript 文件"
    Write-Host "    open -py hello-world     # 打开 Python 文件"
    Write-Host "    open -java hello-world   # 打开 Java 文件"
    Write-Host "    open -rust hello-world   # 打开 Rust 文件"
    Write-Host "    open -ps hello-world     # 打开 PowerShell 文件"
    Write-Host ""
}

function Show-Examples {
    Write-ColoredMessage "💡 使用示例:" -Color Green
    Write-Host ""
    Write-ColoredMessage "  示例 1: 创建一个名为 'calculator' 的 TypeScript 文件" -Color Magenta
    Write-Host "    new -ts calculator"
    Write-Host "    # 输出: typescript/calculator.ts"
    Write-Host ""
    Write-ColoredMessage "  示例 2: 创建一个名为 'data-processor' 的 Python 文件" -Color Magenta
    Write-Host "    new -py data-processor"
    Write-Host "    # 输出: python/data_processor.py"
    Write-Host ""
    Write-ColoredMessage "  示例 3: 打开已存在的 Java 文件" -Color Magenta
    Write-Host "    open -java HelloWorld"
    Write-Host "    # 输出: java/HelloWorld.java"
    Write-Host ""
    Write-ColoredMessage "  示例 4: 创建一个 Rust 项目文件" -Color Magenta
    Write-Host "    new -rust my-app"
    Write-Host "    # 输出: rust/my_app.rs"
    Write-Host ""
}

function Import-FastCommands {
    try {
        # 检查模块文件是否存在
        if (-not (Test-Path $FastCommandModulePath)) {
            Write-ColoredMessage "❌ 错误: 找不到快速命令模块文件" -Color Red
            Write-Host "   路径: $FastCommandModulePath"
            return $false
        }
        
        # 导入模块
        Import-Module $FastCommandModulePath -Force -Global
        Write-ColoredMessage "✅ 快速命令模块导入成功!" -Color Green
        Write-Host "   模块路径: $FastCommandModulePath"
        Write-Host ""
        
        # 验证命令是否可用
        $availableCommands = @()
        if (Get-Command -Name "new" -ErrorAction SilentlyContinue) {
            $availableCommands += "new"
        }
        if (Get-Command -Name "open" -ErrorAction SilentlyContinue) {
            $availableCommands += "open"
        }
        
        if ($availableCommands.Count -gt 0) {
            Write-ColoredMessage "📋 可用的快速命令: $($availableCommands -join ', ')" -Color Cyan
        }
        else {
            Write-ColoredMessage "⚠️  警告: 没有检测到可用的快速命令" -Color Yellow
        }
        
        return $true
    }
    catch {
        Write-ColoredMessage "❌ 导入快速命令模块失败: $($_.Exception.Message)" -Color Red
        return $false
    }
}

function Remove-FastCommands {
    try {
        # 移除模块
        Remove-Module "Fast-Command" -Force -ErrorAction SilentlyContinue
        Write-ColoredMessage "✅ 快速命令模块已卸载" -Color Green
        return $true
    }
    catch {
        Write-ColoredMessage "❌ 卸载快速命令模块失败: $($_.Exception.Message)" -Color Red
        return $false
    }
}

function Show-ModuleInfo {
    Write-ColoredMessage "📦 模块信息:" -Color Blue
    Write-Host "   名称: Fast-Command"
    Write-Host "   版本: 1.0.0"
    Write-Host "   作者: Yujie Liu"
    Write-Host "   路径: $FastCommandModulePath"
    Write-Host ""
    Write-ColoredMessage "⚠️  重要提示:" -Color Yellow
    Write-Host "   • 快速命令只在当前 PowerShell 会话中有效"
    Write-Host "   • 关闭 PowerShell 后需要重新运行此脚本"
    Write-Host "   • 建议将此脚本添加到 PowerShell 配置文件中"
    Write-Host ""
}

function Main {
    Show-Banner
    
    if ($Unload) {
        Write-ColoredMessage "🔄 正在卸载快速命令模块..." -Color Yellow
        Remove-FastCommands
        return
    }
    
    Show-ModuleInfo
    
    Write-ColoredMessage "🚀 正在导入快速命令模块..." -Color Yellow
    $importSuccess = Import-FastCommands
    
    if ($importSuccess) {
        Show-Usage
        
        if ($ShowExamples) {
            Show-Examples
        }
        else {
            Write-ColoredMessage "💡 提示: 使用 -ShowExamples 参数查看详细示例" -Color Gray
        }
        
        Write-Host ""
        Write-ColoredMessage "🎉 设置完成！现在您可以使用 'new' 和 'open' 快速命令了！" -Color Green
        Write-Host ""
        Write-ColoredMessage "📝 要卸载快速命令，请运行: .\Setup.ps1 -Unload" -Color Gray
    }
    else {
        Write-ColoredMessage "❌ 设置失败，请检查模块文件是否存在" -Color Red
    }
}

# 执行主函数
Main