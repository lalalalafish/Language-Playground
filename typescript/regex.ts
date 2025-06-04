/**
 * @FileName regex.ts
 * @Author Yujie Liu
 * @Description 正则表达式的语法归纳和练习合集
 * @Date 2025/06/04 21:21
 */

//语法合集
const GrammerCollection = () => {
    const grammerMap = {
        basics: "🚀Regex是一种声明式的规则，它只关注它要匹配什么，无需关注匹配的过程。"
    }
    Object.entries(grammerMap).forEach(([key, value]) => {
        console.log(`${key}: ${value}`);
    })
}

GrammerCollection();

