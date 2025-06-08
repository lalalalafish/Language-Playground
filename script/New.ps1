<#
.SYNOPSIS
    快速创建不同编程语言的文件
.DESCRIPTION
    根据语言类型和文件名创建对应的文件，如果文件不存在则创建文件并注入模板，
    无论文件是否存在都会打开对应的文件
.PARAMETER FileName
    要创建的文件名（不含扩展名）
.EXAMPLE
    .\New.ps1 hello
    # 默认创建 typescript/hello.ts 文件
.EXAMPLE
    .\New.ps1 -ts hello
    # 创建 typescript/hello.ts 文件
.EXAMPLE
    .\New.ps1 -py hello
    # 创建 python/hello.py 文件
#>

<#
.SYNOPSIS
    生成文件模板内容
.DESCRIPTION
    根据语言配置生成包含动态变量的模板内容
.PARAMETER Config
    语言配置对象
.PARAMETER FileName
    格式化后的文件名
.PARAMETER FilePath
    完整文件路径
.OUTPUTS
    String 生成的模板内容
#>
function Generate-FileTemplate {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # 获取模板和动态变量
        $template = $Config.template
        $author = Get-Author
        $dateFormat = Get-DateFormat
        $currentDate = Get-Date -Format $dateFormat
        
        # 生成函数名
        $functionName = Format-Name -Name $FileName -Type $Config.function_name_type
        
        # 获取不含扩展名的文件名（用于Java等需要类名的情况）
        $baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        
        # 替换模板中的占位符
        # {0} = 文件名, {1} = 作者, {2} = 日期, {3} = 函数名, {4} = 基础文件名
        $content = $template -f $FileName, $author, $currentDate, $functionName, $baseFileName
        
        return $content
        
    } catch {
        Write-Error "生成模板时发生错误: $($_.Exception.Message)"
        return ""
    }
}

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
    Import-Module "$scriptRoot\util\Format-Name.psm1" -Force
    
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
        
        # 构建文件路径
        $projectRoot = Split-Path -Parent $scriptRoot
        $languageFolder = $config.name
        $fileExtension = $config.extension
        
        # 根据配置格式化文件名
        $formattedFileName = Format-Name -Name $FileName -Type $config.filename_type
        $filePath = Join-Path $projectRoot "$languageFolder\$formattedFileName$fileExtension"
        
        # 检查文件是否存在
        $fileExists = Test-Path $filePath
        
        if (-not $fileExists) {
            # 文件不存在，创建文件
            Format-Message -mi "文件不存在，正在创建: $filePath"
            
            # 确保目录存在
            $directory = Split-Path -Parent $filePath
            if (-not (Test-Path $directory)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }
            
            # 生成模板内容
            $template = Generate-FileTemplate -Config $config -FileName $formattedFileName -FilePath $filePath
            
            # 创建文件
            Set-Content -Path $filePath -Value $template -Encoding UTF8
            
            Format-Message -ms "文件创建成功: $filePath"
        } else {
            Format-Message -mi "文件已存在: $filePath"
        }
        
        Stop-Loading $loadingJob
          # 使用Open.ps1脚本打开文件
        $openScript = Join-Path $scriptRoot "Open.ps1"
        $openArgs = @($formattedFileName)
        if ($Language -ne 'ts') {
            $openArgs = @("-$Language", $formattedFileName)
        }
        
        & $openScript @openArgs
        
    } catch {
        # 停止任何运行中的加载动画
        if ($loadingJob -and $loadingJob.State -eq 'Running') {
            Stop-Loading $loadingJob
        }
        
        Format-Message -mr "创建文件时发生错误: $($_.Exception.Message)"
        exit 1
    }
}