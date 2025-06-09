<#
.SYNOPSIS
    PowerShell 脚本创建抽象模板模块
.DESCRIPTION
    提供创建 PowerShell 脚本的抽象模板，包含动态参数生成、配置管理等通用功能
.AUTHOR
    Yujie Liu
.DATE
    2025/06/08
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

# 导入必要的模块
Import-Module "$PSScriptRoot\Config.psm1" -Force
Import-Module "$PSScriptRoot\Format-Message.psm1" -Force
Import-Module "$PSScriptRoot\Format-Name.psm1" -Force
Import-Module "$PSScriptRoot\Format-Template.psm1" -Force

<#
.SYNOPSIS
    创建语言动态参数字典
.DESCRIPTION
    为支持的编程语言创建动态参数，用于 PowerShell 脚本的 DynamicParam 块
.OUTPUTS
    System.Management.Automation.RuntimeDefinedParameterDictionary
.EXAMPLE
    $paramDict = New-LanguageDynamicParameters
#>
function New-LanguageDynamicParameters {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.RuntimeDefinedParameterDictionary])]
    param()
    
    try {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        # 获取支持的语言配置
        $supportedLanguages = Get-SupportedLanguages
        
        # 为每个语言类型创建开关参数
        foreach ($langKey in $supportedLanguages) {
            $paramAttribute = New-Object System.Management.Automation.ParameterAttribute
            $paramAttribute.Mandatory = $false
            
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($paramAttribute)
            
            # 创建开关参数
            $runtimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter($langKey, [switch], $attributeCollection)
            $paramDictionary.Add($langKey, $runtimeParam)
        }
        
        return $paramDictionary
    }
    catch {
        Write-Error "创建动态参数失败: $($_.Exception.Message)"
        return New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    }
}

<#
.SYNOPSIS
    获取激活的语言类型
.DESCRIPTION
    从 PSBoundParameters 中检测哪个语言参数被激活，如果没有则使用默认语言
.PARAMETER BoundParameters
    PowerShell 绑定参数哈希表 ($PSBoundParameters)
.OUTPUTS
    String 激活的语言键
.EXAMPLE
    $activeLanguage = Get-ActiveLanguage -BoundParameters $PSBoundParameters
#>
function Get-ActiveLanguage {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParameters
    )
    
    try {
        $supportedLanguages = Get-SupportedLanguages
        
        # 查找被激活的语言参数
        foreach ($langKey in $supportedLanguages) {
            if ($BoundParameters.ContainsKey($langKey) -and $BoundParameters[$langKey]) {
                return $langKey
            }
        }
        
        # 如果没有指定语言，使用默认语言
        $defaultLanguage = Get-DefaultLanguage
        Write-Verbose "使用默认语言: $defaultLanguage"
        return $defaultLanguage
    }
    catch {
        Write-Error "获取激活语言失败: $($_.Exception.Message)"
        return "ts" # 安全回退
    }
}

<#
.SYNOPSIS
    构建文件完整路径
.DESCRIPTION
    根据语言配置和文件名构建完整的文件路径
.PARAMETER Language
    编程语言键
.PARAMETER FileName
    文件名（不含扩展名）
.OUTPUTS
    String 完整的文件路径
.EXAMPLE
    $filePath = Build-FilePath -Language "ts" -FileName "hello-world"
#>
function Build-FilePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Language,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )
    try {
        # 获取语言配置
        $langConfig = Get-LanguageConfig -Language $Language
        
        # 格式化文件名
        $formattedFileName = Format-Name -Type $langConfig.filename_type -Name $FileName
        
        # 构建完整路径
        $fullFileName = "${formattedFileName}$($langConfig.extension)"
        $fullPath = Join-Path $langConfig.name $fullFileName
        
        return $fullPath
    }
    catch {
        Write-Error "构建文件路径失败: $($_.Exception.Message)"
        return ""
    }
}

<#
.SYNOPSIS
    执行脚本操作的通用流程
.DESCRIPTION
    提供创建/打开文件操作的通用抽象流程
.PARAMETER FileName
    文件名
.PARAMETER BoundParameters
    PowerShell 绑定参数
.PARAMETER ScriptAction
    脚本操作类型 ('create' 或 'open')
.EXAMPLE
    Invoke-ScriptAction -FileName "hello" -BoundParameters $PSBoundParameters -ScriptAction "create"
#>
function Invoke-ScriptAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParameters,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('create', 'open')]
        [string]$ScriptAction
    )
    
    try {
        # 获取激活的语言
        $activeLanguage = Get-ActiveLanguage -BoundParameters $BoundParameters
        Format-Message -mi "检测到语言: $activeLanguage"
        
        # 构建文件路径
        $filePath = Build-FilePath -Language $activeLanguage -FileName $FileName
        Format-Message -mi "目标文件路径: $filePath"
        
        # 检查文件是否存在
        $fileExists = Test-Path $filePath
        
        if ($ScriptAction -eq 'create') {
            if ($fileExists) {
                Format-Message -mn "文件已存在，直接打开: $filePath"
            }
            else {
                # 创建目录（如果不存在）
                $directory = Split-Path $filePath -Parent
                if (-not (Test-Path $directory)) {
                    New-Item -ItemType Directory -Path $directory -Force | Out-Null
                    Format-Message -ms "创建目录: $directory"
                }
                
                # 生成模板内容
                $templateContent = Format-Template -Language $activeLanguage -FileName $FileName
                
                # 创建文件并写入模板内容
                Set-Content -Path $filePath -Value $templateContent -Encoding UTF8
                Format-Message -ms "创建新文件: $filePath"
            }
        }
        elseif ($ScriptAction -eq 'open') {
            if (-not $fileExists) {
                Format-Message -mr "文件不存在: $filePath"
                return
            }
        }
        
        # 使用 VS Code 打开文件
        Format-Message -mi "正在使用 VS Code 打开文件..."
        Start-Process -FilePath "code" -ArgumentList $filePath -NoNewWindow
        Format-Message -ms "文件已在 VS Code 中打开"
    }
    catch {
        Format-Message -mr "操作失败: $($_.Exception.Message)"
        Write-Error $_.Exception
    }
}

# 导出函数
Export-ModuleMember -Function @(
    'New-LanguageDynamicParameters',
    'Get-ActiveLanguage', 
    'Build-FilePath',
    'Invoke-ScriptAction'
)