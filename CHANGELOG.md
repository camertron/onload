## 1.0.3
* Fix Bootsnap issue causing `NoMethodError`.
  - Onload started out using `alias_method` to override certain Zeitwerk and Bootsnap methods. When it was extracted into a gem, I chose to use `Module#prepend` instead. I forgot to convert one of the method calls to `super`, hence the error.

## 1.0.2
* Add support for Rails 7.1.
* Add support for Zeitwerk 2.6.12.

## 1.0.1
* Fix bug causing compiled C extensions (i.e. .bundle and .so files) to be passed to `Kernel.load` when `require`d, which tries to evaluate them as text/Ruby code.

## 1.0.0

* Birthday!
