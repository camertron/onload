## onload

![Tests](https://github.com/camertron/onload/actions/workflows/test.yml/badge.svg?branch=main)

A preprocessor system for Ruby.

## Intro

Onload makes it possible to preprocess Ruby files before they are loaded into the interpreter. It works with plain 'ol Ruby code, within Rails, or wherever Zeitwerk is used.

### What is preprocessing?

Preprocessing has been around for a long time in the C world. The idea is to be able to compile the code differently depending on operating system, architecture, etc. In interpreted languages, preprocessing is most useful for transpilation, i.e. converting code from one dialect to another. Maybe the most familiar example of this is translating TypeScript to JavaScript. The JavaScript interpreters inside web browsers and Node.js can't run TypeScript directly - it has to be converted into JavaScript first.

In the JavaScript ecosystem it's very common for your code to pass through a build step, but not so in Ruby. That's where onload comes in.

### Why onload

Onload lets you transform Ruby code just before it's loaded into the Ruby interpreter. You give it a file extension and a callable object, and it does the rest. Onload is the transpilation system behind [rux](https://github.com/camertron/rux), a tool that let's you write HTML tags inside your [view components](https://viewcomponent.org) (think if it like jsx for Ruby).

## Usage

Let's write an (admittedly contrived) preprocessor that upcases literal strings in Ruby files. We'll use the file extension .up to indicate which files to process.

Preprocessors can be any Ruby object that responds to the `#call` method.

```ruby
class UpcasePreprocessor
  def self.call(source)
    source.gsub(/(\"\w+\")/, '\1.upcase')
  end
end
```

Next we'll tell onload about our preprocessor.

```ruby
Onload.register(".up", UpcasePreprocessor)
```

Finally, we'll load the necessary monkeypatches by "installing" onload into the interpreter. In Rails environments you can skip this step, as it is done for you via the included railtie.

```ruby
Onload.install!
```

Now, the contents of any file with a .up file extension will be passed to `UpcasePreprocessor.call`. The return value will be written to a separate Ruby file and loaded instead of the original .up file.

## Running Tests

`bundle exec appraisal rake` should do the trick.

## License

Licensed under the MIT license. See LICENSE for details.

## Authors

* Cameron C. Dutro: http://github.com/camertron
