<#
.SYNOPSIS
    代码模板格式化模块
.DESCRIPTION
    提供代码模板的格式化功能，支持动态替换文件名、作者、日期和函数名等占位符
.AUTHOR
    Yujie Liu
.DATE
    2025-06-08
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

# 导入必要的模块
Import-Module "$PSScriptRoot\Config.psm1" -Force
Import-Module "$PSScriptRoot\Format-Name.psm1" -Force

<#
.SYNOPSIS
    格式化代码模板
.DESCRIPTION
    根据语言配置格式化代码模板，替换占位符
.PARAMETER Language
    编程语言简写 (如: ts, js, py 等)
.PARAMETER FileName
    文件名（无扩展名）
.OUTPUTS
    String 格式化后的代码内容
.EXAMPLE
    Format-Template -Language "ts" -FileName "hello-world" -FunctionName "helloWorld"
#>
function Format-Template {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Language,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName
    )
    
    try {
        # 获取语言配置
        $langConfig = Get-LanguageConfig -Language $Language
        $template = Get-CodeTemplate -Language $Language
        
        # 获取作者和当前日期
        $author = Get-Author
        $currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # 格式化文件名（确保符合语言规范）
        $formattedFileName = Format-Name -Name $FileName -Type $langConfig.filename_type
        $fileNameWithExtension = $formattedFileName + $langConfig.extension
        
        # 格式化函数名(根据文件名来生成函数名)
        $formattedFunctionName = Format-Name -Name $FileName -Type $langConfig.function_name_type
        
        Write-Verbose "模板格式化完成:"
        Write-Verbose "  语言: $Language"
        Write-Verbose "  原始文件名: $FileName"
        Write-Verbose "  格式化文件名: $formattedFileName"
        Write-Verbose "  文件名（含扩展名）: $fileNameWithExtension"
        Write-Verbose "  函数名: $formattedFunctionName"
        Write-Verbose "  作者: $author"
        Write-Verbose "  日期: $currentDate"


        # 格式化模板（支持多个参数）
        # {0} = 文件名（含扩展名）, {1} = 作者, {2} = 日期, {3} = 函数名
        $formattedContent = $template -f $fileNameWithExtension, $author, $currentDate, $formattedFunctionName
        
        return $formattedContent
        
    }
    catch {
        Write-Error "格式化模板时发生错误: $($_.Exception.Message)"
        return $null
    }
}

# 导出公共函数
Export-ModuleMember -Function @(
    'Format-Template'
)
