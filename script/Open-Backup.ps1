<#
.SYNOPSIS
    打开指定语言的文件
.DESCRIPTION
    根据语言类型和文件名打开对应的文件，默认使用 VS Code 打开，支持动态语言参数
.PARAMETER FileName
    要打开的文件名（不含扩展名）
.EXAMPLE
    .\Open.ps1 ansi
    # 默认打开 typescript/ansi.ts 文件
.EXAMPLE
    .\Open.ps1 -ts ansi
    # 打开 typescript/ansi.ts 文件
.EXAMPLE
    .\Open.ps1 -py ansi
    # 打开 python/ansi.py 文件
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string]$FileName
)

DynamicParam {
    try {
        # 导入抽象模块
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
        Import-Module "$scriptRoot\module\Create-Script.psm1" -Force
        
        # 使用抽象函数创建动态参数
        return New-LanguageDynamicParameters
    }
    catch {
        Write-Verbose "创建动态参数失败: $($_.Exception.Message)"
        return New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    }
}

Process {
    # 严格模式，提高代码质量
    Set-StrictMode -Version Latest
    
    try {
        # 导入抽象模块
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
        Import-Module "$scriptRoot\module\Create-Script.psm1" -Force
        
        # 使用抽象函数执行打开操作
        Invoke-ScriptAction -FileName $FileName -BoundParameters $PSBoundParameters -ScriptAction "open"
    }
    catch {
        Write-Error "打开文件失败: $($_.Exception.Message)"
        exit 1
    }
}