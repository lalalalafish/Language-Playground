<#
.SYNOPSIS
    配置管理模块，用于读取和管理语言配置
.DESCRIPTION
    从config.json文件中读取配置信息，提供安全的配置访问接口
.AUTHOR
    Yujie Liu
.DATE
    2025/06/07
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

# 配置文件路径
$script:ConfigPath = Join-Path $PSScriptRoot "config.json"
$script:ConfigData = $null

<#
.SYNOPSIS
    初始化配置数据
.DESCRIPTION
    从config.json文件中读取配置数据并验证
#>
function Initialize-Config {
    [CmdletBinding()]
    param()
    
    try {
        # 检查配置文件是否存在
        if (-not (Test-Path $script:ConfigPath)) {
            throw "配置文件不存在: $script:ConfigPath"
        }
        
        # 读取并解析JSON配置文件
        $jsonContent = Get-Content $script:ConfigPath -Raw -Encoding UTF8
        $script:ConfigData = $jsonContent | ConvertFrom-Json
        
        # 验证配置结构
        if (-not $script:ConfigData.languages) {
            throw "配置文件缺少 'languages' 节点"
        }
        
        if (-not $script:ConfigData.defaults) {
            throw "配置文件缺少 'defaults' 节点"
        }
        
        Write-Verbose "配置文件加载成功"
    }
    catch {
        Write-Error "初始化配置失败: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    获取支持的语言列表
.DESCRIPTION
    返回所有支持的编程语言简写列表
.OUTPUTS
    String[] 语言简写数组
#>
function Get-SupportedLanguages {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    
    # 确保配置已初始化
    if ($null -eq $script:ConfigData) {
        Initialize-Config
    }
    
    return $script:ConfigData.languages.PSObject.Properties.Name
}

<#
.SYNOPSIS
    获取指定语言的配置信息
.DESCRIPTION
    根据语言简写获取对应的完整配置信息
.PARAMETER Language
    语言简写 (如: ts, js, py 等)
.OUTPUTS
    PSCustomObject 语言配置对象
#>
function Get-LanguageConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Language
    )
    
    # 确保配置已初始化
    if ($null -eq $script:ConfigData) {
        Initialize-Config
    }
    
    $Language = $Language.ToLower()
      # 检查语言是否支持
    if (-not $script:ConfigData.languages.PSObject.Properties.Name -contains $Language) {
        $supportedLangs = Get-SupportedLanguages
        throw "不支持的语言: $Language. 支持的语言: $($supportedLangs -join ', ')"
    }
    
    return $script:ConfigData.languages.$Language
}

<#
.SYNOPSIS
    获取默认配置
.DESCRIPTION
    获取defaults节点中的默认配置信息
.OUTPUTS
    PSCustomObject 默认配置对象
#>
function Get-DefaultConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    # 确保配置已初始化
    if ($null -eq $script:ConfigData) {
        Initialize-Config
    }
    
    return $script:ConfigData.defaults
}

<#
.SYNOPSIS
    获取作者信息
.DESCRIPTION
    从默认配置中获取作者信息
.OUTPUTS
    String 作者名称
#>
function Get-Author {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    $defaults = Get-DefaultConfig
    return $defaults.author
}

<#
.SYNOPSIS
    获取支持的消息类型数组
.DESCRIPTION
    返回所有支持的消息类型简写列表
.OUTPUTS
    String[] 消息类型简写数组
#>
function Get-SupportedMessageTypes {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    
    # 确保配置已初始化
    if ($null -eq $script:ConfigData) {
        Initialize-Config
    }
    
    return $script:ConfigData.messageTypes.PSObject.Properties.Name
}

<#
.SYNOPSIS
    获取指定消息类型的配置
.DESCRIPTION
    根据消息类型简写获取对应的配置信息
.PARAMETER Type
    消息类型简写 (如: n, s, e 等)
.OUTPUTS
    PSCustomObject 消息类型配置对象
#>
function Get-MessageTypeConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Type
    )
    
    # 确保配置已初始化
    if ($null -eq $script:ConfigData) {
        Initialize-Config
    }
    
    $messageTypes = Get-SupportedMessageTypes
    
    if (-not $messageTypes -contains $Type) {
        throw "不支持的消息类型: $Type. 支持的类型: $($messageTypes -join ', ')"
    }
    
    return $script:ConfigData.messageTypes.$Type
}

<#
.SYNOPSIS
    显示配置信息摘要
.DESCRIPTION
    显示当前加载的配置信息概览
#>
function Show-ConfigSummary {
    [CmdletBinding()]
    param()
    
    # 确保配置已初始化
    if ($null -eq $script:ConfigData) {
        Initialize-Config
    }
      Write-Host "=== 配置信息摘要 ===" -ForegroundColor Cyan
    Write-Host "配置文件路径: $script:ConfigPath" -ForegroundColor Gray
    Write-Host "默认作者: $(Get-Author)" -ForegroundColor Gray
    Write-Host "支持的语言: $((Get-SupportedLanguages) -join ', ')" -ForegroundColor Gray
    Write-Host "支持的消息类型: $((Get-SupportedMessageTypes) -join ', ')" -ForegroundColor Gray
    Write-Host "========================" -ForegroundColor Cyan
}

# 导出公共函数
Export-ModuleMember -Function @(
    'Get-SupportedLanguages',
    'Get-LanguageConfig', 
    'Get-DefaultConfig',
    'Get-Author',
    'Get-SupportedMessageTypes',
    'Get-MessageTypeConfig',
    'Show-ConfigSummary'
)

# 模块加载时自动初始化配置
Initialize-Config