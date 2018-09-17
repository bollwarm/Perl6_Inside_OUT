🔬5 潜伏在Perl 6中的插值

在前面的文章中，我们已经看到未定义的值不能在字符串中轻松插入，因为会触发一个编译时异常。今天，我们的目标是探索Rakudo源代码中相关的代码。
之前，我们以布尔值的定义为例来说的，所以我们延续这个传统。在REPL模式下打开perl6并创建一个变量：

```
$ perl6
To exit type 'exit' or '^D'
> my $b
(Any)
```
由于该变量$b未定义，当我们将其做插值时候会抛出一个异常：
```
> "$b"
Use of uninitialized value $b of type Any in string context.
Methods .^name, .perl, .gist, or .say can be used to stringify it to something meaningful.
  in block <unit> at <unknown file> line 1
```
对插值的解析使用到了`Str`方法。对于未定义的值，Bool类中不不提供此方法，所以会抛出异常报错。
让我们追溯到Mu类，在那里我们可以看到下面的基本方法集合：

```
proto method Str(|) {*}

multi method Str(Mu:U \v:) {
   my $name = (defined($*VAR_NAME) ?? $*VAR_NAME !! try v.VAR.?name) // '';
   $name ~= ' ' if $name ne '';
 
   warn "Use of uninitialized value {$name}of type {self.^name} in string"
      ~ " context.\nMethods .^name, .perl, .gist, or .say can be"
      ~ " used to stringify it to something meaningful.";
   ''
}

multi method Str(Mu:D:) {
    nqp::if(
        nqp::eqaddr(self,IterationEnd),
        "IterationEnd",
        self.^name ~ '<' ~ nqp::tostr_I(nqp::objectid(self)) ~ '>'
    )
}

```
上面的原型定义给出了`Str`方法的模式。签名中的竖线表示`proto`不验证参数的类型，也可以捕获更多参数。
在` Str(Mu:U)`方法中，我们看到我们熟悉的错误消息的文本。对于未定义的变量会调用这个方法。在我们的例子中，使用布尔变量，Bool类中没有` Str(Bool:U)`方法，因此将会将调用转发到Mu类的方法。

注意下，函数是如何获得变量名称的：
` my $name = (defined($*VAR_NAME) ?? $*VAR_NAME !! try v.VAR.?name) // '';
`
它尝试动态变量` $*VAR_NAME`或`VAR`对象的名称方法。

为了可以清晰追踪到使用的条件分支，我们需要向Mu类添加一些打印指令并重新编译Rakudo：
```
proto method Str(|) {*}
multi method Str(Mu:U \v:) {
    warn "VAR_NAME=$*VAR_NAME" if defined $*VAR_NAME;
    warn "v.VAR.name=" ~ v.VAR.name if v.VAR.?name;
    . . .

```
现在执行上面同样的操作
```
> my $b ;
(Any)
> "$b"
VAR_NAME=$b
  in block  at  line 1
```
显然，该名称取自`$ * VAR_NAME`的变量。

那么，第二个多方法` Str(Mu:D:)`呢？重要的是要理解它不会对已定义的布尔对象调用，因为Bool类定义中已经提供了其变体函数。

