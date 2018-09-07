
# 🦋101 proto关键字

今天，我们来专门讲下`proto`关键字。它为编译器提供了创建`multi-subs`的意图指示。

## 例1

考虑如下函数示例，f函数可以颠倒字符串或对整数取反。

```
multi sub f(Int $x) {
    return -$x;
}

multi sub f(Str $x) {
    return $x.flip;
}

say f(42);      # -4
say f('Hello'); # olleH

```
如果要改成带两个参数的函数变体，该怎么做？

```
multi sub f($a, $b) {
    return $a + $b;
}

say f(1, 2); _# 3
_

```

这段代码很有效，但和谐性不好。即函数的名称没有暗示它的功能，我们也希望有一个函数
以某种方式返回其参数的“反射”版本。将两个数字相加的函数不符合这个想法。

所以，是时候祭出`proto`关键字来帮助明确意图。

`proto sub f($x) {*}`

这样，当尝试调用两个参数的函数将会报编译错误：

```
===SORRY!=== Error while compiling proto.pl
Calling f(Int, Int) will never work with proto signature ($x)
at proto.pl:15
------&gt; say ⏏f(1,2)

```
单参数变体的调用非常有效。`proto-definition`为函数f创建了一个模式：它的名字是f，它需要一个标量参数。
`Multi-functions`指定行为并将参数范围缩小为整数或字符串。

## 例2

另一个示例涉及在函数签名中具有两个类型参数的原型定义。

`proto sub g(Int $x, Int $y) {*}`

在上述示例中，函数返回两个整数的和。当其中一个数字比另一个数字大得多时，较小的数字会被忽略，因为它不够重要：

```
multi sub g(Int $x, Int $y) {
   return $x + $y;
}

multi sub g(Int $x, Int $y where {$y &gt; 1_000_000 * $x}) {
   return $y;
}
```

使用整数参数来调用函数，让我们看下Perl 6是如何选择正确的变量的：

```
say g(1, 2);          _# 3_
say g(3, 10_000_000); _# 10000000_
```
不要忘记原型必须是两个整数？如果我们用浮点数呢？

    say g(pi, e);

ok，会发生编译时错误：

```
===SORRY!=== Error while compiling proto-int.pl
Calling g(Num, Num) will never work with proto signature (Int $x, Int $y)
at proto-int.pl:13
------&gt; say ⏏g(pi, e);
```
原型已经捕获到了函数用法中的错误。

如果g函数没有原型会发生什么呢？该函数依然不能调用，但是报错信息不同。
这时报运行时错误：

```
Cannot resolve caller g(3.14159265358979e0, 2.71828182845905e0); none of these signatures match:
 (Int $x, Int $y)
 (Int $x, Int $y where { ... })
 in block &lt;unit&gt; at proto-int.pl line 13
```

我们仍然没有匹配的浮点数签名，但编译器在程序代码运行之前无法捕捉的到。




