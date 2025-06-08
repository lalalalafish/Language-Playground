<#
.SYNOPSIS
    New.ps1脚本的测试文件
.DESCRIPTION
    测试New.ps1脚本的各种语言文件创建功能
.AUTHOR
    Yujie Liu
.DATE
    2025-06-08
#>

# 严格模式，提高代码质量
Set-StrictMode -Version Latest

Write-Host "开始测试New.ps1脚本..." -ForegroundColor Cyan

# 获取脚本路径
$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$newScript = Join-Path $scriptRoot "New.ps1"
$projectRoot = Split-Path -Parent $scriptRoot

# 测试用例
$testCases = @(
    @{ Language = 'ts'; FileName = 'test-new-script'; ExpectedPath = 'typescript\test-new-script.ts' },
    @{ Language = 'js'; FileName = 'testNewScript'; ExpectedPath = 'javascript\test-new-script.js' },
    @{ Language = 'py'; FileName = 'TestNewScript'; ExpectedPath = 'python\test_new_script.py' },
    @{ Language = 'rs'; FileName = 'test-new-script'; ExpectedPath = 'rust\test_new_script.rs' },
    @{ Language = 'ps'; FileName = 'testNewScript'; ExpectedPath = 'powershell\Test-New-Script.ps1' }
)

$testPassed = 0
$testFailed = 0

foreach ($testCase in $testCases) {
    $language = $testCase.Language
    $fileName = $testCase.FileName
    $expectedPath = Join-Path $projectRoot $testCase.ExpectedPath
    
    Write-Host "`n测试语言: $language, 文件名: $fileName" -ForegroundColor Yellow
    
    try {
        # 确保文件不存在（清理之前的测试）
        if (Test-Path $expectedPath) {
            Remove-Item $expectedPath -Force
            Write-Host "  清理了已存在的测试文件" -ForegroundColor Gray
        }
        
        # 执行New.ps1脚本
        if ($language -eq 'ts') {
            # 默认情况，不需要语言参数
            $result = & $newScript $fileName 2>&1
        } else {
            # 指定语言参数
            $result = & $newScript "-$language" $fileName 2>&1
        }
        
        # 检查文件是否创建
        if (Test-Path $expectedPath) {
            Write-Host "  ✓ 文件创建成功: $expectedPath" -ForegroundColor Green
            
            # 检查文件内容是否包含模板
            $content = Get-Content $expectedPath -Raw
            if ($content -and $content.Length -gt 0) {
                Write-Host "  ✓ 文件包含内容" -ForegroundColor Green
                
                # 检查是否包含作者和日期
                if ($content -match "Yujie Liu" -and $content -match "\d{4}-\d{2}-\d{2}") {
                    Write-Host "  ✓ 模板变量替换正确" -ForegroundColor Green
                    $testPassed++
                } else {
                    Write-Host "  ✗ 模板变量替换失败" -ForegroundColor Red
                    $testFailed++
                }
            } else {
                Write-Host "  ✗ 文件为空" -ForegroundColor Red
                $testFailed++
            }
        } else {
            Write-Host "  ✗ 文件创建失败" -ForegroundColor Red
            $testFailed++
        }
        
    } catch {
        Write-Host "  ✗ 发生错误: $($_.Exception.Message)" -ForegroundColor Red
        $testFailed++
    }
}

# 测试文件已存在的情况
Write-Host "`n测试文件已存在的情况..." -ForegroundColor Yellow
$existingFile = Join-Path $projectRoot "typescript\existing-test.ts"

try {
    # 先创建一个文件
    "// 现有文件内容" | Set-Content $existingFile -Encoding UTF8
    
    # 尝试再次创建同名文件
    $result = & $newScript "existing-test" 2>&1
    
    # 检查文件内容是否被覆盖
    $content = Get-Content $existingFile -Raw
    if ($content -eq "// 现有文件内容") {
        Write-Host "  ✓ 现有文件未被覆盖" -ForegroundColor Green
        $testPassed++
    } else {
        Write-Host "  ✗ 现有文件被意外覆盖" -ForegroundColor Red
        $testFailed++
    }
    
    # 清理
    Remove-Item $existingFile -Force
    
} catch {
    Write-Host "  ✗ 发生错误: $($_.Exception.Message)" -ForegroundColor Red
    $testFailed++
}

# 清理测试文件
Write-Host "`n清理测试文件..." -ForegroundColor Gray
foreach ($testCase in $testCases) {
    $expectedPath = Join-Path $projectRoot $testCase.ExpectedPath
    if (Test-Path $expectedPath) {
        Remove-Item $expectedPath -Force
        Write-Host "  已删除: $expectedPath" -ForegroundColor Gray
    }
}

# 输出测试结果
Write-Host "`n测试完成!" -ForegroundColor Cyan
Write-Host "通过: $testPassed" -ForegroundColor Green
Write-Host "失败: $testFailed" -ForegroundColor Red

if ($testFailed -eq 0) {
    Write-Host "所有测试通过! ✓" -ForegroundColor Green
    exit 0
} else {
    Write-Host "有测试失败! ✗" -ForegroundColor Red
    exit 1
}