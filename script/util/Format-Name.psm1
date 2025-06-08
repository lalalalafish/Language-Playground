<#
.SYNOPSIS
    字符串格式化模块，用于转换字符串到不同的命名格式
.DESCRIPTION
    支持多种命名格式转换：kebab-case, camel-case, pascal-case, snake-case, verb-noun
.AUTHOR
    Yujie Liu
.DATE
    2025-06-08
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

# 导入配置模块
Import-Module "$PSScriptRoot\Config.psm1" -Force

<#
.SYNOPSIS
    格式化字符串名称
.DESCRIPTION
    根据指定的类型格式化字符串，支持动态参数
.PARAMETER Name
    要格式化的字符串
.EXAMPLE
    Format-Name -Type kebab-case -Name "hello_World123"
.EXAMPLE
    Format-Name -Type camel-case -Name "hello-world-123"
#>
function Format-Name {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Type
    )
    
    Process {
        try {
            # 验证类型是否支持
            $supportedFormats = Get-SupportedStringFormats
            if (-not $supportedFormats -contains $Type) {
                throw "不支持的格式化类型: $Type. 支持的类型: $($supportedFormats -join ', ')"
            }
            
            # 调试信息
            Write-Verbose "未处理的字符串: $Name"
            Write-Verbose "输出类型: $Type"
            
            # 第一步：分割字符串为单词数组
            $words = Split-StringToWords -InputString $Name
            Write-Verbose "分割后的单词: $($words -join ', ')"
            
            # 第二步：根据类型格式化单词
            $processedName = switch ($Type) {
                'kebab-case' { 
                    ($words | ForEach-Object { $_.ToLower() }) -join '-'
                }
                'camel-case' {
                    $result = @()
                    for ($i = 0; $i -lt $words.Count; $i++) {
                        if ($i -eq 0) {
                            $result += $words[$i].ToLower()
                        } else {
                            $result += (Get-Culture).TextInfo.ToTitleCase($words[$i].ToLower())
                        }
                    }
                    $result -join ''
                }
                'pascal-case' {
                    ($words | ForEach-Object { 
                        (Get-Culture).TextInfo.ToTitleCase($_.ToLower())
                    }) -join ''
                }
                'snake-case' {
                    ($words | ForEach-Object { $_.ToLower() }) -join '_'
                }
                'verb-noun' {
                    ($words | ForEach-Object { 
                        (Get-Culture).TextInfo.ToTitleCase($_.ToLower())
                    }) -join '-'
                }
                default {
                    throw "未实现的格式化类型: $Type"
                }
            }
            
            Write-Verbose "处理后的字符串: $processedName"
            return $processedName
            
        } catch {
            Write-Error "格式化字符串时发生错误: $($_.Exception.Message)"
            return $null
        }
    }
}

<#
.SYNOPSIS
    将字符串分割为单词数组
.DESCRIPTION
    识别各种分隔符和大写字母作为分割点，将字符串分割为不含特殊符号的单词数组
.PARAMETER InputString
    要分割的输入字符串
.OUTPUTS
    String[] 单词数组
#>
function Split-StringToWords {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )
    
    # 移除首尾空白
    $cleanString = $InputString.Trim()
    
    # 第一步：用非字母数字字符分割
    $parts = $cleanString -split '[^a-zA-Z0-9]+' | Where-Object { $_ -ne '' }
      $words = @()
    foreach ($part in $parts) {
        # 第二步：处理驼峰命名和数字字母边界
        # 改进的正则表达式来更好地处理连续大写字母
        $matches = [regex]::Matches($part, '([A-Z]+(?=[A-Z][a-z]|\b|[0-9])|[A-Z][a-z]+|[a-z]+|[0-9]+)')
        
        foreach ($match in $matches) {
            if ($match.Value -ne '') {
                $words += $match.Value
            }
        }
    }
    
    # 过滤空字符串并返回
    return $words | Where-Object { $_.Length -gt 0 }
}

# 导出公共函数
Export-ModuleMember -Function @(
    'Format-Name',
    'Split-StringToWords'
)