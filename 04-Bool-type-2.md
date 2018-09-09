
# 🔬  04.探索Perl 6中的Bool类型，第2部分

今天，我们继续阅读Bool类的源代码：src/core/Bool.pm，并探索计算后一个或前一个值的方法，或者实现对这些值递增和递减。对于布尔型，貌似这很简单，但是仍然许多需要注意的边缘用例下的行为。

## pred和succ

在Perl 6中，有两种对应的方法：pred和succ，它们分别返回前面和后面的值。这是为Bool类型中它们的定义：
```
Bool.^add_method('pred', my method pred() { Bool::False });
Bool.^add_method('succ', my method succ() { Bool::True });

```
如上所示，这些方法是常规（不是multi）方法，没有区分已定义或未定义的参数。结果不取决于它的值。
如果你接受两个布尔变量，一个设置为False而另一个设置为True，则.prec方法为两个变量返回False：

```
my Bool $f = False;
my Bool $t = True;
my Bool $u;

say $f.pred;    # False
say $t.pred;    # False
say $u.pred;    # False
say False.pred; # False
say True.pred;  # False

```

类似的，succ方法总是返回True：
```
say $f.succ;    # True
say $t.succ;    # True
say $u.succ;    # True
say False.succ; # True
say True.succ;  # True

```

## 递增和递减

因为要考虑做为前缀或后缀的，++和--操作的函数变体更多。

首先，两种前缀形式：

```
multi sub prefix:<++>(Bool $a is rw) { $a = True; }
multi sub prefix:<-->(Bool $a is rw) { $a = False; 
```
当你阅读这些源代码时，你就开始慢慢地理解这种语言的许多奇怪的行为了，都可以在他们的源码中得到很好的解释。开发人员必须考虑参数，变量，位置等的大量的组合，甚至可能一些你永远用不到不会想的一些组合。
前缀形式只是将变量的值设置为True或False，并且它适用于已定义和未定义的变量。is rw 表示允许修改参数。
接着是后缀形式的定义，在这种情况下，变量的状态则很重要。

```
multi sub postfix:<++>(Bool:U $a is rw --> False) { $a = True }
multi sub postfix:<-->(Bool:U $a is rw) { $a = False; }

```
我们看到了一个新的语法元素——在子签名中的箭头后面指出其返回值 `(Bool:U $a is rw --> False)`

处理已定义变量的函数主体部分更加冗长。如果仔细查看代码，可以看到它避免了将新值赋给变量，例如，如果包含True的变量递增。

```
multi sub postfix:<++>(Bool:D $a is rw) {
    if $a {
        True
    }
    else {
        $a = True;
        False
    }
}


multi sub postfix:<-->(Bool:D $a is rw) {
    if $a {
        $a = False;
        True
    }
    else {
        False
    }
}

```
如上所示，操作符后变量的值变更可能与操作符返回的值不同。