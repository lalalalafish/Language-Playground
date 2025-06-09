<#
.SYNOPSIS
    快速命令模块
.DESCRIPTION
    快速命令模块，提供便捷的快速命令
.AUTHOR
    Yujie Liu
.DATE
    2025/06/08
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    创建新文件
.DESCRIPTION
    快速命令，调用 e:\project-playground\script\New.ps1 脚本
.PARAMETER FileName
    文件名参数
.PARAMETER args
    其他所有参数
.EXAMPLE
    new hello-world
.EXAMPLE
    new -ts hello-world
#>
function new {
    [CmdletBinding()]
    param(
        [switch]$ts,
        [switch]$js, 
        [switch]$py,
        [switch]$ja,
        [switch]$rs,
        [switch]$ps,
        
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FileName
    )
    
    try {
        # 构建参数哈希表
        $scriptParams = @{
            FileName = $FileName
        }
        
        # 添加激活的语言开关
        if ($ts) { $scriptParams.ts = $true }
        if ($js) { $scriptParams.js = $true }
        if ($py) { $scriptParams.py = $true }
        if ($ja) { $scriptParams.ja = $true }
        if ($rs) { $scriptParams.rs = $true }
        if ($ps) { $scriptParams.ps = $true }
        
        # 调用原始脚本
        & "e:\project-playground\script\New.ps1" @scriptParams
    }
    catch {
        Write-Error "执行 new 命令失败: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    打开文件
.DESCRIPTION
    快速命令，调用 e:\project-playground\script\Open.ps1 脚本
.PARAMETER FileName
    文件名参数
.PARAMETER args
    其他所有参数
.EXAMPLE
    open hello-world
.EXAMPLE
    open -ts hello-world
#>
function open {
    [CmdletBinding()]
    param(
        [switch]$ts,
        [switch]$js, 
        [switch]$py,
        [switch]$ja,
        [switch]$rs,
        [switch]$ps,
        
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FileName
    )
    
    try {
        # 构建参数哈希表
        $scriptParams = @{
            FileName = $FileName
        }
        
        # 添加激活的语言开关
        if ($ts) { $scriptParams.ts = $true }
        if ($js) { $scriptParams.js = $true }
        if ($py) { $scriptParams.py = $true }
        if ($ja) { $scriptParams.ja = $true }
        if ($rs) { $scriptParams.rs = $true }
        if ($ps) { $scriptParams.ps = $true }
        
        # 调用原始脚本
        & "e:\project-playground\script\Open.ps1" @scriptParams
    }
    catch {
        Write-Error "执行 open 命令失败: $($_.Exception.Message)"
        throw
    }
}

# 导出函数
Export-ModuleMember -Function @(
    'new',
    'open'
)