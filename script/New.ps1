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
    $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    
    try {
        # 导入配置模块
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
        Import-Module "$scriptRoot\util\Config.psm1" -Force
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
    }
    catch {
        Write-Verbose "无法获取动态参数: $($_.Exception.Message)"
    }
    return $paramDictionary
}

Process {
    # 严格模式，提高代码质量
    Set-StrictMode -Version Latest    # 导入必要的模块
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    Import-Module "$scriptRoot\util\Format-Message.psm1" -Force
    Import-Module "$scriptRoot\util\Format-Template.psm1" -Force
    Import-Module "$scriptRoot\util\Config.psm1" -Force

    try {
        # 确定语言类型
        $Language = 'ts'  # 默认类型
        
        # 检查哪个动态开关参数被激活
        foreach ($paramName in $PSBoundParameters.Keys) {
            if ($paramName -ne 'FileName' -and $PSBoundParameters[$paramName]) {
                $Language = $paramName
                break
            }
        }
        # 显示加载动画
        $loadingJob = Show-Loading -Text "正在处理文件..." -AsJob
        
        # 获取语言配置
        $config = Get-LanguageConfig -Language $Language
        
        # 使用Format-Template格式化模板内容
        $templateContent = Format-Template -Language $Language -FileName $FileName
        
        # 构建文件路径
        $projectRoot = Split-Path -Parent $scriptRoot
        $languageFolder = $config.name
        $fileExtension = $config.extension
        $filePath = Join-Path $projectRoot "$languageFolder\$FileName$fileExtension"
        
        Stop-Loading $loadingJob
        # 检查文件是否存在
        if (Test-Path $filePath) {
            # 文件已存在，直接调用Open.ps1打开
            Format-Message -mi "文件已存在，正在打开: $filePath"
            
            # 构建参数哈希表
            $openParams = @{ $Language = $true; FileName = $FileName }
            & "$scriptRoot\Open.ps1" @openParams
        }
        else {
            # 文件不存在，创建文件并注入模板
            Format-Message -mi "文件不存在，正在创建: $filePath"
            
            # 确保目录存在
            $directory = Split-Path $filePath -Parent
            if (-not (Test-Path $directory)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }
            
            # 创建文件并写入模板内容
            Set-Content -Path $filePath -Value $templateContent -Encoding UTF8
            
            # 显示成功消息
            Format-Message -ms "成功创建文件: $filePath"
            
            # 构建参数哈希表并调用Open.ps1打开文件
            $openParams = @{ $Language = $true; FileName = $FileName }
            & "$scriptRoot\Open.ps1" @openParams
        }
        
    }
    catch {
        # 停止任何运行中的加载动画
        if ($loadingJob -and $loadingJob.State -eq 'Running') {
            Stop-Loading $loadingJob
        }
        
        Format-Message -mr "创建文件时发生错误: $($_.Exception.Message)"
        exit 1
    }
}