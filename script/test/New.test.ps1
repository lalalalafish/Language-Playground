<#
.SYNOPSIS
    New.ps1 的单元测试
.DESCRIPTION
    测试 New.ps1 脚本的功能
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("true", "false")]
    [string]$TestAll
)

Import-Module "$PSScriptRoot\..\util\Format-Message.psm1" -Force

if ($TestAll -eq "false") {
    # 只测试创建单个ts文件的情况
    # 先检查是否有测试文件
    $testFilePath = ".\typescript\test-typescript-new-123.ts"
    if (Test-Path $testFilePath) {
        Remove-Item $testFilePath -Force
    }
    try {
        & ".\script\New.ps1" -FileName "testTypescriptNEW123" -ts

        # 检查路径
        if (Test-Path $testFilePath) {
            Format-Message -ms "测试通过: 创建了文件 $testFilePath"
        }
        else {
            throw "文件 $testFilePath 未成功创建"
        }

        # 检查文件内容: 直接输出
        $fileContent = Get-Content $testFilePath -Raw
        Format-Message "文件内容：`n$fileContent"
    }
    catch {
        Format-Message -mr "测试失败: $_"  
    }
}
else {
    # 如果需要测试全部类型的文件
    $languagesSettings = @(
        @{
            Language         = "ts"
            FileName         = "testTypescriptNEW123"
            ExpectedFilePath = ".\typescript\test-typescript-new-123.ts"
        }
        @{
            Language         = "js"
            FileName         = "testJavascriptNEW123"
            ExpectedFilePath = ".\javascript\test-javascript-new-123.js"
        }
        @{
            Language         = "py"
            FileName         = "testPythonNEW123"
            ExpectedFilePath = ".\python\test_python_new_123.py"
        }
        @{
            Language         = "ja"
            FileName         = "testJavaNEW123"
            ExpectedFilePath = ".\java\TestJavaNew123.java"
        }
        @{
            Language         = "ps"
            FileName         = "testPowershellNEW123"
            ExpectedFilePath = ".\powershell\Test-Powershell-New-123.ps1"
        }
        @{
            Language         = "rs"
            FileName         = "testRustNEW123"
            ExpectedFilePath = ".\rust\test_rust_new_123.rs"
        }
    )

    # 统计测试结果
    $testPassed = 0
    $testNumber = $languagesSettings.Count
    Format-Message -mi "开始测试 $testNumber 个语言的文件创建功能..."

    # 遍历每种语言配置进行测试
    foreach ($langConfig in $languagesSettings) {
        $language = $langConfig.Language
        $fileName = $langConfig.FileName
        $expectedFilePath = $langConfig.ExpectedFilePath

        # 删除可能存在的测试文件
        if (Test-Path $expectedFilePath) {
            Remove-Item $expectedFilePath -Force
        }        try {
            # 构建参数哈希表
            $params = @{
                FileName  = $fileName
                $language = $true
            }
            & ".\script\New.ps1" @params

            # 检查文件是否创建成功
            if (Test-Path $expectedFilePath) {
                Format-Message -ms "测试通过: 创建了文件 $expectedFilePath"
                $testPassed++
            }
            else {
                throw "文件 $expectedFilePath 未成功创建"
            }

            # 检查文件内容: 直接输出
            $fileContent = Get-Content $expectedFilePath -Raw
            Format-Message "文件内容：`n$fileContent"
        }
        catch {
            Format-Message -mr "测试失败: $_"
        }
    }

    # 输出测试结果
    Format-Message -mi "测试完成: $testPassed/$testNumber 个测试通过"
}