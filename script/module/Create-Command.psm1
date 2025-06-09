<#
.SYNOPSIS
    快速命令创建抽象模板模块
.DESCRIPTION
    提供创建快速命令（函数别名）的抽象模板，用于生成便捷的命令快捷方式
.AUTHOR
    Yujie Liu
.DATE
    2025/06/08
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    创建快速命令函数
.DESCRIPTION
    为指定的脚本创建快速命令函数，支持参数传递和错误处理
.PARAMETER CommandName
    快速命令的名称
.PARAMETER ScriptPath
    目标脚本的绝对路径
.PARAMETER Description
    命令描述
.OUTPUTS
    String 生成的函数代码
.EXAMPLE
    $funcCode = New-FastCommand -CommandName "new" -ScriptPath "e:\project-playground\script\New.ps1" -Description "创建新文件"
#>
function New-FastCommand {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description
    )
    
    # 验证脚本路径是否存在
    if (-not (Test-Path $ScriptPath)) {
        throw "脚本路径不存在: $ScriptPath"
    }
    
    # 生成函数代码
    $functionCode = @"
<#
.SYNOPSIS
    $Description
.DESCRIPTION
    快速命令，调用 $ScriptPath 脚本
.PARAMETER FileName
    文件名参数
.PARAMETER args
    其他所有参数
.EXAMPLE
    $CommandName hello-world
.EXAMPLE
    $CommandName -ts hello-world
#>
function $CommandName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true, Position = 0)]
        [string]`$FileName,
        
        [Parameter(ValueFromRemainingArguments = `$true)]
        [string[]]`$args
    )
    
    try {
        # 构建参数列表
        `$allArgs = @(`$FileName)
        if (`$args) {
            `$allArgs += `$args
        }
        
        # 调用原始脚本
        & "$ScriptPath" @allArgs
    }
    catch {
        Write-Error "执行 $CommandName 命令失败: `$(`$_.Exception.Message)"
        throw
    }
}
"@
    
    return $functionCode
}

<#
.SYNOPSIS
    创建快速命令模块
.DESCRIPTION
    生成包含多个快速命令的 PowerShell 模块代码
.PARAMETER Commands
    命令配置哈希表数组，每个元素包含 Name、ScriptPath、Description
.PARAMETER ModuleName
    模块名称
.PARAMETER ModuleDescription
    模块描述
.OUTPUTS
    String 完整的模块代码
.EXAMPLE
    $commands = @(
        @{ Name = "new"; ScriptPath = "e:\path\New.ps1"; Description = "创建新文件" },
        @{ Name = "open"; ScriptPath = "e:\path\Open.ps1"; Description = "打开文件" }
    )
    $moduleCode = New-FastCommandModule -Commands $commands -ModuleName "FastCommands" -ModuleDescription "快速命令模块"
#>
function New-FastCommandModule {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable[]]$Commands,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleDescription
    )
    
    # 生成模块头部
    $currentDate = Get-Date -Format "yyyy/MM/dd"
    $moduleHeader = @"
# filepath: $ModuleName.psm1
<#
.SYNOPSIS
    $ModuleDescription
.DESCRIPTION
    $ModuleDescription，提供便捷的快速命令
.AUTHOR
    Yujie Liu
.DATE
    $currentDate
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

"@
    
    # 生成所有命令函数
    $allFunctions = @()
    $exportedFunctions = @()
    
    foreach ($command in $Commands) {
        $functionCode = New-FastCommand -CommandName $command.Name -ScriptPath $command.ScriptPath -Description $command.Description
        $allFunctions += $functionCode
        $exportedFunctions += "'$($command.Name)'"
    }
    
    # 生成模块尾部（导出函数）
    $moduleFooter = @"

# 导出函数
Export-ModuleMember -Function @(
    $($exportedFunctions -join ",`n    ")
)
"@
    
    # 组合完整模块代码
    $fullModuleCode = $moduleHeader + "`n`n" + ($allFunctions -join "`n`n") + $moduleFooter
    
    return $fullModuleCode
}

<#
.SYNOPSIS
    验证命令配置
.DESCRIPTION
    验证快速命令配置是否正确
.PARAMETER Commands
    命令配置数组
.OUTPUTS
    Boolean 验证结果
.EXAMPLE
    $isValid = Test-CommandConfiguration -Commands $commands
#>
function Test-CommandConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable[]]$Commands
    )
    
    foreach ($command in $Commands) {
        # 检查必需的键
        $requiredKeys = @('Name', 'ScriptPath', 'Description')
        foreach ($key in $requiredKeys) {
            if (-not $command.ContainsKey($key) -or [string]::IsNullOrEmpty($command[$key])) {
                Write-Error "命令配置缺少必需的键: $key"
                return $false
            }
        }
        
        # 检查脚本路径是否存在
        if (-not (Test-Path $command.ScriptPath)) {
            Write-Error "脚本路径不存在: $($command.ScriptPath)"
            return $false
        }
        
        # 检查命令名称是否为有效的 PowerShell 函数名
        if ($command.Name -notmatch '^[a-zA-Z_][a-zA-Z0-9_-]*$') {
            Write-Error "无效的命令名称: $($command.Name)"
            return $false
        }
    }
    
    return $true
}

# 导出函数
Export-ModuleMember -Function @(
    'New-FastCommand',
    'New-FastCommandModule',
    'Test-CommandConfiguration'
)