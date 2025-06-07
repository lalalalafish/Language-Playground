<#
.SYNOPSIS
    实用工具模块，提供格式化消息、进度条和加载动画功能
.DESCRIPTION
    包含消息格式化、进度显示和加载动画等常用工具函数
.AUTHOR
    Yujie Liu
.DATE
    2025/06/07
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

# 导入配置模块
Import-Module "$PSScriptRoot\Config.psm1" -Force

<#
.SYNOPSIS
    格式化并输出带颜色的消息
.DESCRIPTION
    根据指定的消息类型格式化并输出彩色消息，支持动态参数（如 -note, -info, -success, -error 等）
.PARAMETER Message
    默认参数，当没有指定类型时，消息内容（默认为basic类型）
.EXAMPLE
    Format-Message -note "这是一个注释"
.EXAMPLE
    Format-Message -success "操作成功"
.EXAMPLE
    Format-Message -info "这是信息提示"
.EXAMPLE
    Format-Message "默认是basic类型"
#>
function Format-Message {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Message
    )
    
    DynamicParam {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        try {
            # 获取支持的消息类型
            $supportedTypes = Get-SupportedMessageTypes
            
            # 为每个消息类型创建开关参数
            foreach ($typeKey in $supportedTypes) {
                $paramAttribute = New-Object System.Management.Automation.ParameterAttribute
                # 不设置特定的参数集，让开关参数在所有参数集中可用
                $paramAttribute.Mandatory = $false
                
                $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection.Add($paramAttribute)
                
                # 创建开关参数
                $runtimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter($typeKey, [switch], $attributeCollection)
                $paramDictionary.Add($typeKey, $runtimeParam)
            }
        } catch {
            Write-Verbose "无法获取动态参数: $($_.Exception.Message)"
        }
        
        return $paramDictionary
    }
    
    Process {
        try {
            # 确定消息类型
            $messageType = 'md'  # 默认类型
            
            # 检查哪个动态开关参数被激活
            foreach ($paramName in $PSBoundParameters.Keys) {
                if ($paramName -ne 'Message' -and $PSBoundParameters[$paramName]) {
                    $messageType = $paramName
                    break
                }
            }
            
            $content = $Message
            
            # 获取配置并输出
            $config = Get-MessageTypeConfig -Type $messageType
            $formattedMessage = $config.format -f $content
            Write-Host $formattedMessage -ForegroundColor $config.color
        }
        catch {
            Write-Error "格式化消息失败: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    显示进度条
.DESCRIPTION
    显示一个简洁的进度条：任务名称: 进度条 百分比(当前/总计)
.PARAMETER Current
    当前进度值
.PARAMETER Total
    总进度值
.PARAMETER TaskName
    任务名称
.PARAMETER Width
    进度条宽度（字符数），默认30
.EXAMPLE
    Show-Progress -Current 30 -Total 100 -TaskName "处理文件"
#>
function Show-Progress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$Current,

        [Parameter(Mandatory = $true, Position = 1)]
        [int]$Total,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$TaskName,        [int]$Width = 30
    )
    
    # 计算百分比
    $percentage = [math]::Min(100, [math]::Max(0, ($Current / $Total) * 100))
    
    # 计算进度条填充长度
    $filledLength = [math]::Floor(($percentage / 100) * $Width)
    
    # 构建进度条 - 使用ASCII字符以确保兼容性
    $progressBar = "[" + ("=" * $filledLength) + (" " * ($Width - $filledLength)) + "]"
    
    # 格式化输出：任务名称: 进度条 百分比(当前/总计)
    $progressText = "$TaskName`: $progressBar $([math]::Round($percentage, 1))% ($Current/$Total)"
    
    # 计算需要清除的长度
    $clearLength = [math]::Max(100, $progressText.Length + 10)
    
    # 清除当前行并输出新的进度
    Write-Host ("`r" + (" " * $clearLength) + "`r") -NoNewline
    Write-Host $progressText -NoNewline -ForegroundColor Cyan
    
    # 如果进度完成，添加换行
    if ($Current -ge $Total) {
        Write-Host ""
    }
}

<#
.SYNOPSIS
    显示加载动画
.DESCRIPTION
    显示一个点状加载动画，支持成功/失败状态显示
.PARAMETER Text
    加载时显示的文本
.PARAMETER Duration
    动画持续时间（秒），默认为无限循环
.PARAMETER Speed
    动画速度（毫秒），默认300ms
.PARAMETER Success
    加载成功时的状态，显示绿色√
.PARAMETER Failed
    加载失败时的状态，显示红色×
.EXAMPLE
    Show-Loading -Text "正在加载数据..." -Duration 5 -Success
.EXAMPLE
    Show-Loading -Text "连接服务器..." -Duration 3 -Failed
#>
function Show-Loading {
    [CmdletBinding()]
    param(
        [string]$Text = "Loading...",
        [int]$Duration = 0,
        [int]$Speed = 300,
        [switch]$Success,
        [switch]$Failed,
        [switch]$AsJob
    )

    $scriptBlock = {
        param($Text, $Duration, $Speed, $Success, $Failed)
        
        $dotChars = @('.', '..', '...', '....', '.....', '......')
        $dotIndex = 0
        $startTime = Get-Date
        
        try {
            while ($true) {
                # 检查是否超时
                if ($Duration -gt 0 -and ((Get-Date) - $startTime).TotalSeconds -ge $Duration) {
                    break
                }
                
                # 显示点状动画
                $dots = $dotChars[$dotIndex % $dotChars.Length]
                Write-Host "`r$(' ' * ($Text.Length + 20))`r" -NoNewline
                Write-Host "$Text$dots" -NoNewline -ForegroundColor Yellow
                
                $dotIndex++
                Start-Sleep -Milliseconds $Speed
            }
        }
        finally {
            # 清除加载动画并显示最终状态
            Write-Host "`r$(' ' * ($Text.Length + 20))`r" -NoNewline
            
            if ($Success) {
                Write-Host "$Text ✓" -ForegroundColor Green
            } elseif ($Failed) {
                Write-Host "$Text ✗" -ForegroundColor Red
            } else {
                Write-Host ""
            }
        }
    }
    
    if ($AsJob) {
        return Start-Job -ScriptBlock $scriptBlock -ArgumentList $Text, $Duration, $Speed, $Success, $Failed
    } else {
        & $scriptBlock $Text $Duration $Speed $Success $Failed
    }
}

<#
.SYNOPSIS
    停止加载动画
.DESCRIPTION
    停止指定的加载动画任务
.PARAMETER Job
    要停止的任务对象
.EXAMPLE
    $loading = Show-Loading "处理中..." -AsJob
    Stop-Loading $loading
#>
function Stop-Loading {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Job]$Job
    )
    
    if ($Job.State -eq 'Running') {
        Stop-Job $Job
        Remove-Job $Job
        
        # 清除可能残留的加载文本
        Write-Host "`r$(' ' * 100)`r" -NoNewline
    }
}

<#
.SYNOPSIS
    显示增强版进度条
.DESCRIPTION
    显示一个功能更丰富的进度条，支持多种样式和自定义选项
.PARAMETER Current
    当前进度值
.PARAMETER Total
    总进度值
.PARAMETER TaskName
    任务名称
.PARAMETER Width
    进度条宽度（字符数），默认40
.PARAMETER Style
    进度条样式：Classic(经典)、Modern(现代)、Minimal(简约)
.PARAMETER ShowETA
    是否显示预计完成时间
.PARAMETER StartTime
    任务开始时间，用于计算ETA
.EXAMPLE
    Show-ProgressAdvanced -Current 50 -Total 100 -TaskName "数据处理" -Style "Modern" -ShowETA
#>
function Show-ProgressAdvanced {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$Current,

        [Parameter(Mandatory = $true, Position = 1)]
        [int]$Total,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$TaskName,

        [int]$Width = 40,
        
        [ValidateSet('Classic', 'Modern', 'Minimal')]
        [string]$Style = 'Classic',
        
        [switch]$ShowETA,
        
        [datetime]$StartTime = (Get-Date)
    )

    # 计算百分比
    $percentage = [math]::Min(100, [math]::Max(0, ($Current / $Total) * 100))
    
    # 计算进度条填充长度
    $filledLength = [math]::Floor(($percentage / 100) * $Width)
    
    # 根据样式构建进度条
    $progressBar = switch ($Style) {
        'Classic' { 
            "[" + ("=" * $filledLength) + (">" * ([math]::Min(1, $Width - $filledLength))) + (" " * ([math]::Max(0, $Width - $filledLength - 1))) + "]"
        }
        'Modern' {
            "│" + ("█" * $filledLength) + ("░" * ($Width - $filledLength)) + "│"
        }
        'Minimal' {
            ("█" * $filledLength) + ("·" * ($Width - $filledLength))
        }
    }
    
    # 构建基本进度文本
    $progressText = "$TaskName`: $progressBar $([math]::Round($percentage, 1))% ($Current/$Total)"
    
    # 计算并添加ETA信息
    if ($ShowETA -and $Current -gt 0) {
        $elapsed = (Get-Date) - $StartTime
        $rate = $Current / $elapsed.TotalSeconds
        if ($rate -gt 0) {
            $remaining = ($Total - $Current) / $rate
            $eta = " ETA: $([math]::Round($remaining))s"
            $progressText += $eta
        }
    }
    
    # 清除当前行并输出新的进度
    $clearLength = [math]::Max(120, $progressText.Length + 10)
    Write-Host ("`r" + (" " * $clearLength) + "`r") -NoNewline
    
    # 根据样式选择颜色
    $color = switch ($Style) {
        'Classic' { 'Green' }
        'Modern' { 'Cyan' }
        'Minimal' { 'Yellow' }
    }
    
    Write-Host $progressText -NoNewline -ForegroundColor $color
      # 如果进度完成，添加换行和完成消息
    if ($Current -ge $Total) {
        Write-Host ""
        Format-Message -success "任务 '$TaskName' 已完成！"
    }
}

# 导出公共函数
Export-ModuleMember -Function @(
    'Format-Message',
    'Show-Progress',
    'Show-Loading',
    'Stop-Loading',
    'Show-ProgressAdvanced'
)
