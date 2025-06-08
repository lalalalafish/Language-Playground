<#
.SYNOPSIS
    Format-Name模块的测试脚本
.DESCRIPTION
    测试Format-Name模块的各种字符串格式化功能
.AUTHOR
    Yujie Liu
.DATE
    2025-06-08
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

# 导入Format-Name模块
$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$scriptRoot\util\Format-Name.psm1" -Force

Write-Host "开始测试Format-Name模块..." -ForegroundColor Cyan

# 测试用例
$testCases = @(
    @{
        Input    = "hello-_World123"
        Expected = @{
            'kebab-case'  = "hello-world-123"
            'camel-case'  = "helloWorld123"
            'pascal-case' = "HelloWorld123"
            'snake-case'  = "hello_world_123"
            'verb-noun'   = "Hello-World-123"
        }
    },
    @{
        Input    = "HelloWorld123"
        Expected = @{
            'kebab-case'  = "hello-world-123"
            'camel-case'  = "helloWorld123"
            'pascal-case' = "HelloWorld123"
            'snake-case'  = "hello_world_123"
            'verb-noun'   = "Hello-World-123"
        }
    },
    @{
        Input    = "test_file_name"
        Expected = @{
            'kebab-case'  = "test-file-name"
            'camel-case'  = "testFileName"
            'pascal-case' = "TestFileName"
            'snake-case'  = "test_file_name"
            'verb-noun'   = "Test-File-Name"
        }
    }, @{
        Input    = "myAPI2Server"
        Expected = @{
            'kebab-case'  = "my-api-2-server"
            'camel-case'  = "myApi2Server"
            'pascal-case' = "MyApi2Server"
            'snake-case'  = "my_api_2_server"
            'verb-noun'   = "My-Api-2-Server"
        }
    }
)

$testPassed = 0
$testFailed = 0

foreach ($testCase in $testCases) {
    Write-Host "`n测试输入: '$($testCase.Input)'" -ForegroundColor Yellow
    
    foreach ($formatType in $testCase.Expected.Keys) {
        $expected = $testCase.Expected[$formatType]
        
        try {
            $result = Format-Name -Name $testCase.Input -Type $formatType -Verbose
            
            if ($result -eq $expected) {
                Write-Host "  ✓ $formatType`: '$result'" -ForegroundColor Green
                $testPassed++
            }
            else {
                Write-Host "  ✗ $formatType`: 期望 '$expected', 得到 '$result'" -ForegroundColor Red
                $testFailed++
            }
        }
        catch {
            Write-Host "  ✗ $formatType`: 发生错误 - $($_.Exception.Message)" -ForegroundColor Red
            $testFailed++
        }
    }
}

# 测试不支持的类型
Write-Host "`n测试不支持的类型..." -ForegroundColor Yellow
try {
    Format-Name -Name "test" -Type "unsupported-type" -ErrorAction Stop
    Write-Host "  ✗ 应该抛出错误但没有抛出" -ForegroundColor Red
    $testFailed++
}
catch {
    Write-Host "  ✓ 正确抛出错误: $($_.Exception.Message)" -ForegroundColor Green
    $testPassed++
}

# 输出测试结果
Write-Host "`n测试完成!" -ForegroundColor Cyan
Write-Host "通过: $testPassed" -ForegroundColor Green
Write-Host "失败: $testFailed" -ForegroundColor Red

if ($testFailed -eq 0) {
    Write-Host "所有测试通过! ✓" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "有测试失败! ✗" -ForegroundColor Red
    exit 1
}
