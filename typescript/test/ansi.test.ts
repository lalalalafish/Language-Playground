import assert from 'assert';
import { colorize } from '../ansi';

// 测试默认白色
assert.strictEqual(
  colorize('Hello'),
  '\x1b[37mHello\x1b[0m',
  '默认应为白色'
);