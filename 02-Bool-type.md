
# 🔬2 探索Perl 6中的Bool类型，第1部分


今天，我们将使用GatHub上提供的[Rakudo源代码]( https://github.com/rakudo/rakudo/blob/master/src/core/Bool.pm6)深入了解Bool类型。

Perl 6是用Perl 6和NQP（Not Quite Perl 6）语言编写的，这使得读取源代码变得相对容易。当然，有很多东西不容易理解，或者没有在Perl 6公开文档中有提中。到截至目前，还有很多细节在已经公开出版地[Perl 6书]( http://allperlbooks.com/tag/perl6.0)中还无法找到详细解释。无论如何，通过对Perl 6的底层做些探索，这仍然是可能的。

好的，回到src/core/Bool.pm文件。它以几个BEGIN阶段开始，为Bool类添加一些方法和multi_method方法。下次我们将讨论元模型和类结构的细节。今天，对我们要说地是Bool类的方法都做了些什么？

## gist和perl

.gist和.perl方法返回对象的字符串形式表达：当变量被字符串化时，用.gist会被隐式调，.perl则是需要明确调用。他们对Perl 6中的任何对象都适用。那么他们应该是在某处定义这些行为地。就在这个文件中（Bool.pm6）：
```
Bool.^add_method('gist', my proto method gist(|) {*});
Bool.^add_multi_method('gist', my multi method gist(Bool:D:) { 
    self ?? 'True' !! 'False'
});
Bool.^add_multi_method('gist', my multi method gist(Bool:U:) {
    '(Bool)'
});

Bool.^add_method('perl', my proto method perl(|) {*});
Bool.^add_multi_method('perl', my multi method perl(Bool:D:) {
    self ?? 'Bool::True' !! 'Bool::False'
});
Bool.^add_multi_method('perl', my multi method perl(Bool:U:) {
    'Bool' 
});

```

我们试着调用一下简单方法：

```
my Bool $b = True;
say $b;      # True
say "[$b]";  # [True]
$b.perl.say; # Bool::True
```
和我们预期地一样，True字符串由gist方法返回，而perl方法返回`Bool :: True`。

两种方法都是`multi_method`，在上面的示例中，我们使用了具有已定义参数的版本。如果查看函数地签名，我们会看到方法与指定参数的方式不同：`Bool:D:`或`Bool:U:`。字母D和U相对应保留定义和未定义。第一个冒号为该类型添加一个属性，而第二个冒号表示该参数实际上是一个调用者。

因此，根据它们可用于已定义的和未定义的布尔变量上调用，对应触发不同版本的方法。要演示其他两个变体方法的行为，只需从代码中删除变量初始化部分：

```
my Bool $b;
say $b;      # (Bool)
$b.perl.say; # Bool

```
由于变量$ b有一个类型，Perl 6知道对象的类型，它应该调用方法。然后它被分派到参数为（`Bool:U:`)签名的版本，因为该变量尚未定义。
当字符串中出现未定义的变量时，例如，`say "[$b]"`，则不会调用`gist`方法。而是触发一条编译错误。

```
Use of uninitialized value $b of type Bool in string context.
Methods .^name, .perl, .gist, or .say can be used to stringify it to something meaningful.
 in block  at bool-2.pl line 3
[]

```
错误消息显示Perl已经知道了该变量的类型，由于为初始化，无法调用其字符串化方法。

今天就到这里。下一次，我们将介绍Bool数据类型定义的其他方法。
