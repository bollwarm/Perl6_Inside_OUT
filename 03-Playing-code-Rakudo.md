
#🔬 3.玩转Rakudo Perl 6的代码

昨天，我们介绍了返回字符串的Bool类的两个方法。函数生成的字符串表示形式在源代码中硬编码指定了。
今天我们来就用他来研究并且试着修改这些显示文本。
所以，下面是我们要修改的代码片段：
```
Bool.^add_multi_method('gist', my multi method gist(Bool:D:) {
    self ?? 'True' !! 'False'
});

```
这个gist方法用于对已定义的变量进行字符串化。
要使更改生效，我们需要在计算机上安装Rakudo的源代码，然后编译它们。

## 编译rakudo

首先从GitHub克隆项目：

`$ git clone https://github.com/rakudo/rakudo.git`

使用MoarVM编译：
```
$ cd rakudo
$ perl Configure.pl --gen-moar --gen-nqp --backends=moar
$ make
```

完成以上操作后，我们在rakudo目录中将得到perl6的可执行文件。

## 修改Perl 6默认行为 

现在，打开`src/core/Bool.pm`文件并更改.gist方法的字符串以便支持使用`Unicode thumb`而不是纯文本：
```
Bool.^add_multi_method('gist', my multi method gist(Bool:D:) {
    self ?? ' ' !! ' '
});

```
保存文件后，需要重新编译Rakudo。 Bool.pm位于要在Makefile中编译的文件列表中：
```
M_CORE_SOURCES = \
    src/core/core_prologue.pm\
    src/core/traits.pm\
    src/core/Positional.pm\
    . . .
    src/core/Bool.pm\
    . . .

```
运行make并获取得到修改过地perl6。现在结果为：
```
:~/rakudo$ ./perl6
To exit type 'exit' or '^D'
> my Bool $b = True;
 
> $b = !$b; 
 
>

```
作为练习，让我们通过为未定义的值添加.gist方法来改进本地Perl 6。默认情况下是无法这样显示地，我们昨天的例子中我们已经知道了。在字符串中插入未定义的变量会触发一个编译时错误。
插入值使用的是Str方法。它类似于gist和perl，因此你可以随意修改。
这就是Perl 6中默认的内容：

```
Bool.^add_multi_method('Str', my multi method Str(Bool:D:) {
    self ?? 'True' !! 'False'
});
```

下面是我们需要添加的内容：
```
Bool.^add_multi_method('Str', my multi method Str(Bool:U:) {
    '¯\_(ツ)_/¯'
});

```
请注意，在第二个变体中不需要self（也不能使用self）。
重新编译并运行perl6：
```
$ ./perl6
To exit type 'exit' or '^D'
> my Bool $b;
(Bool)
> "Here is my variable: $b"
Here is my variable: ¯\_(ツ)_/¯
>

```
一切符合我们的预期工作。
恭喜你，你刚刚改变了Perl 6的行为！
怎么样？很简单吧。
