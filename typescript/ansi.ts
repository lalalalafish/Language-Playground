/**
 * @FileName format-message.ts
 * @Author Yujie Liu
 * @Description 工具函数：美化命令行输出信息
 * @Date 2025/06/04 21:48
 */


//背景：
// 1. 在计算机历史早期，终端其实是一个真实的物理设备，
//    现在我们还能看到的terminal软件实际上是终端设备模拟器。
//    虽然终端设备已经彻底作古，但是终端的通信控制协议还依旧发挥着作用
// 2. ANSI转义序列就是终端上通用的通信控制协议，支持我们在终端设备里
//    显示下划线，斜体，不同文字颜色等等多彩内容。
// 3. 现代的命令行几乎都原生支持ANSI转义序列，但是Windows的cmd需要开启setConsoleMode才能够支持

//ANSI语法结构: \x1b[${参数1};${参数2};...${功能字母}
//常用功能字母：图形渲染m, 光标定位H, 清屏J, 清除行K, 保存光标位置s, 恢复光标位置u

type Colors = 'white' | 'blue' | 'red' | 'green' | 'gray' | 'orange' | 'yellow' | 'purple';
const COLOR_MAP: Record<Colors, string> = {
    white: `\x1b[37m`,        
    blue: `\x1b[34m`,         
    red: `\x1b[31m`,          
    green: `\x1b[32m`,   
    gray: `\x1b[38;5;232m`,  
    orange: `\x1b[38;5;208m`, 
    yellow: `\x1b[33m`, 
    purple: `\x1b[38;5;129m`, 
};
const RESET =  `\x1b[0m`;

/**
 * @param message 要被渲染的字符串
 * @param color 颜色名称
 * @returns 带ANSI颜色的字符串
 */
export function colorize(message: string, color: Colors = "white"){
    const colorPattern = COLOR_MAP[color];
    return colorPattern + message + RESET;
}

//colorize测试
// console.log(colorize("你好你好你好", "red"));
// console.log(colorize("你好你好你好", "white"));
// console.log(colorize("你好你好你好", "blue"));
// console.log(colorize("你好你好你好", "orange"));
// console.log(colorize("你好你好你好", "green"));
// console.log(colorize("你好你好你好", "gray"));
// console.log(colorize("你好你好你好", "yellow"));
// console.log(colorize("你好你好你好", "purple"));
// console.log(colorize("你好你好你好"));


/**
 * 动态进度条生成器
 */
export function progressBar(
    percent: number,
    width: number= 20,
){
    const validPercent = Math.max(0, Math.min(1, percent));
    
    const filledCount = Math.floor(validPercent * width);
    const emptyCount = width - filledCount;
    const progressChar = '=';

    //\r：移动到行首；\x1b[K: 清除行尾
    const progress = `\r\x1b[K\x1b[32m` + 
        progressChar.repeat(filledCount) + 
        '\x1b[0m' + 
        progressChar.repeat(emptyCount) +
        `${Math.round(validPercent * 100)}%`;
    process.stdout.write(progress);
}
//模拟进度条
let progress = 0;
// setInterval(()=>{
//     progressBar(progress)
//     if(progress > 1) process.exit();
//     progress += 0.01;
// },100)


// 加载动画类型定义
type LoaderType = 'dots' | 'spin' | 'bar';

/**
 * 创建加载动画
 * @param type 动画类型 ('dots' | 'spin' | 'bar')
 * @param message 加载文字 (默认"加载中")
 * @param speed 刷新速度ms (默认200)
 * @returns 停止动画的函数
 */
export function createLoader(
  type: LoaderType = 'dots',
  message = "加载中",
  speed = 300
): () => void {
  const frames = {
    dots: ['   ', '.  ', '.. ', '...'],
    spin: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
    bar: ['[    ]', '[=   ]', '[==  ]', '[=== ]', '[====]']
  };

  const startTime = Date.now();
  let counter = 0;
  
  // 隐藏光标
  process.stdout.write('\x1b[?25l');
  
  const timer = setInterval(() => {
    counter = (counter + 1) % frames[type].length;
    const frame = frames[type][counter];
    
    // 计算运行时间
    const seconds = ((Date.now() - startTime) / 1000).toFixed(1);
    
    // 蓝色动画 + 灰色消息
    process.stdout.write(
      `\r\x1b[36m${frame}\x1b[0m ${message} \x1b[90m(${seconds}s)\x1b[0m`
    );
  }, speed);

  // 返回停止函数
  return () => {
    clearInterval(timer);
    // 清行 + 显示光标
    process.stdout.write('\r\x1b[K\x1b[?25h');
  };
}

// 使用示例
const stopDotsLoader = createLoader('dots', '正在初始化');
const stopSpinLoader = createLoader('spin', '处理数据');
const stopBarLoader = createLoader('bar', '处理数据');

// 5秒后停止
setTimeout(() => {
  stopDotsLoader();
  stopSpinLoader();
  stopBarLoader();
  console.log(colorize('\n✔ 全部完成!', 'green'));
}, 5000);



