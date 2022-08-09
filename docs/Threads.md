[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Threads](https://libxml-raku.github.io/LibXML-raku/Threads)

Notes on Raku LibXML Threading and Concurrency
==============================================

Concurrency and Parsing
-----------------------

Parsing, including, validation and the Reader pull-parser can be run concurrently.

```raku
my @docs = @files.hyper.map: -> $file { LibXML::Parse: :$file }
```

However, the Raku LibXML bindings will protect these with a commonly library lock, defeating concurrency, if the libxml library has not been compiled with threading enabled. Threading can be checked using the [LibXML::Config](https://libxml-raku.github.io/LibXML-raku/Config) `threads` method.

```raku
unless LibXML::Config.threads { ... }
```

### Concurrency and Input Callbacks

Input callbacks may be set globally, without affecting concurrency.

```raku
my LibXML::InputCallback $input-callbacks .= new: @callbacks;
LibXML::Config.input-callbacks = $input-callbacks;
```

They may also be set at the parser level. However, this is not thread safe. The LibXML library requires that you also enable the `parser-locking` flag, which limits concurrent parsing.

```raku
LibXML::Config.parser-locking = True;
my LibXML::InputCallback $input-callbacks .= new: :callbacks{
        :&match, :&read, :&open, :&close
}
LibXML::Config.parser-locking = True;
my LibXML:D $parser .= new: :$input-callbacks;
```

DOM Concurrency
---------------

### Parallel Construction

Document fragments and element sub-trees, may be constructed in parallel provided that they remain independent of each other. They then need to be assembled sequentially to create the final document:

```raku
my LibXML::Document $doc .= parse: :string("<doc/>");
my @frags = @files.hyper.map: -> $file { LibXML::DocumentFragment.parse: :balanced, :$file}
$doc.addChild($_) for @frags;
```

### DOM Updates and Concurrency

It is not thread-safe to read and modify DOM nodes concurrently.

However, each node has a `protect` method that can be used to limit concurrency.

```raku
$elem.protect: { $elem.appendChild: LibXML::Element.new('foo') }
```

Be careful with nesting `protect` calls, to avoid potential deadlocks.

