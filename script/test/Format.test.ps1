# 工具模块测试脚本
Import-Module "$PSScriptRoot\..\util\Format.psm1" -Force

Format-Message -mm "工具模块功能测试"

# 测试各种消息类型
Format-Message -mn "这是一个普通注释"
Format-Message -mi "这是信息提示"
Format-Message -ms "这是成功消息"
Format-Message -mr "这是错误提示"
Format-Message -mp "这是部分标题"
Format-Message -md "这是基本内容"

Write-Host ""
Format-Message -mi "测试简化的进度条功能..."

# 测试简化的进度条
1..5 | ForEach-Object {
    Show-Progress -Current $_ -Total 5 -TaskName "处理文件"
    Start-Sleep -Milliseconds 400
}

Write-Host ""
Format-Message -mi "测试新的加载动画功能..."

# 测试成功状态的加载动画
Show-Loading -Text "加载数据中" -Duration 2 -Success

# 测试失败状态的加载动画
Show-Loading -Text "连接服务器" -Duration 2 -Failed

# 测试普通加载动画
Show-Loading -Text "处理中" -Duration 1

# 测试默认参数（应该使用content类型）
Format-Message "这是默认类型的消息"

Format-Message -ms "所有测试完成！"
