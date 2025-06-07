<# 
    .SYNOPSIS
    快速创建不同编程语言的一个脚本工具
#>

[cmdletBinding()]
param(
    [ValidationSet("ts","js","j", "rs", "ps")]
    [string]$FileType,

    [Parameter(Mandatory=$true)]
    [string]$FileName
)