# K Framework SPLS Talk (July 2022)

This repository contains K definitions to go along with my talk at the [July 2022
edition of SPLS][spls].

To follow along, first set up your development environment to build the K
framework[^1] following the [README here][build]. Then, build the K framework with:
```shell
git submodule update --init --recursive
make deps
```

You can build the full set of semantics I mention with:
```shell
make
```
once K itself is built. These are:
* Two tiny definitions used to demonstrate K basics
* A simple imperative language with account balance state
* A variant of the pi-calculus

The `examples/` directory contains a set of examples you can run with (for
example):
```shell
make examples/in.one.run
```
for the file `examples/in.one`.

[^1]: Note that if you have difficulty building from source, you can instead
  install K from your system package manager following the instructions on the
  same page, and setting `SYSTEM_K=1` when you run `make` later on.

[spls]: https://spls-series.github.io/meetings/2022/july/
[build]: https://github.com/runtimeverification/k#the-long-version
