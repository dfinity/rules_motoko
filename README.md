[![CI](https://github.com/dfinity/rules_motoko/actions/workflows/ci.yml/badge.svg)](https://github.com/dfinity/rules_motoko/actions/workflows/ci.yml)

# Rules Motoko

This repository provides rules for building [Motoko](https://smartcontracts.org/docs/language-guide/motoko.html) projects with [Bazel](http://bazel.build/).

## Using with Bazel modules (bzlmod)

If you're using Bazel 6+ with bzlmod, prefer declaring a module dependency instead of WORKSPACE macros.

1) In your root `MODULE.bazel`:

```
bazel_dep(name = "rules_motoko", version = "<release>")

motoko = use_extension("@rules_motoko//motoko:extensions.bzl", "motoko")
# Optional: pin the Motoko compiler version; defaults to the rules' DEFAULT_VERSION.
motoko.toolchain(version = "0.8.7")
use_repo(motoko, "build_bazel_rules_motoko_toolchain")
```

2) Load and use the rules in your BUILD files as usual (no WORKSPACE setup is required for the toolchain):

```
load("@rules_motoko//motoko:defs.bzl", "motoko_binary", "motoko_library", "motoko_test")
```

Notes:
- Bazel 6 requires `--enable_bzlmod`; Bazel 7 enables bzlmod by default.
- Third-party Motoko libraries you previously fetched via `http_archive` in WORKSPACE should be migrated via your own module extension(s) or replaced with proper Bazel modules when available.

## Legacy (WORKSPACE) setup

If you aren't on bzlmod yet, you can still set up the toolchain and dependencies via a WORKSPACE macro:

```
load("@rules_motoko//motoko:repositories.bzl", "rules_motoko_dependencies")
rules_motoko_dependencies(motoko_version = "0.8.7")
```

Then load the rules in your BUILD files:

```
load("@rules_motoko//motoko:defs.bzl", "motoko_binary", "motoko_library", "motoko_test")
```
