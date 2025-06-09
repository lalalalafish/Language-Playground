<#
.SYNOPSIS
    创建指定语言的新文件
.DESCRIPTION
    根据语言类型和文件名创建对应的文件，如果文件已存在则直接打开，如果不存在则创建并注入模板后打开，默认使用 VS Code 打开，支持动态语言参数
.PARAMETER FileName
    要创建的文件名（不含扩展名）
.EXAMPLE
    .\New.ps1 hello-world
    # 默认创建 typescript/hello-world.ts 文件
.EXAMPLE
    .\New.ps1 -ts hello-world
    # 创建 typescript/hello-world.ts 文件
.EXAMPLE
    .\New.ps1 -py hello-world
    # 创建 python/hello_world.py 文件
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
        
        # 使用抽象函数执行创建操作
        Invoke-ScriptAction -FileName $FileName -BoundParameters $PSBoundParameters -ScriptAction "create"
    }
    catch {
        Write-Error "创建文件失败: $($_.Exception.Message)"
        exit 1
    }
}