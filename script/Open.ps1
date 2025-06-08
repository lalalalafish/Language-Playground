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
    } catch {
        Write-Verbose "无法获取动态参数: $($_.Exception.Message)"
    }
      return $paramDictionary
}

Process {
    # 严格模式，提高代码质量
    Set-StrictMode -Version Latest
    
    # 导入必要的模块
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    Import-Module "$scriptRoot\util\Format.psm1" -Force
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
        $loadingJob = Show-Loading -Text "正在查找文件..." -AsJob
          # 获取语言配置
        $config = Get-LanguageConfig -Language $Language
        
        # 构建文件路径
        $projectRoot = Split-Path -Parent $scriptRoot
        $languageFolder = $config.name
        $fileExtension = $config.extension
        $filePath = Join-Path $projectRoot "$languageFolder\$FileName$fileExtension"
        
        Stop-Loading $loadingJob
        
        # 使用 VS Code 打开文件
        Start-Process "code" -ArgumentList "`"$filePath`"" -NoNewWindow
        
        # 显示成功消息
        Format-Message -ms "成功打开文件: $filePath"
        
    } catch {
        # 停止任何运行中的加载动画
        if ($loadingJob -and $loadingJob.State -eq 'Running') {
            Stop-Loading $loadingJob
        }
        
        Format-Message -mi "打开文件时发生错误"
        exit 1
    }
}