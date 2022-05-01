load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

MO_FILETYPES = [".mo"]

MotokoActorInfo = provider(
    doc = "Provides information about an IC actor.",
    fields = {
        "wasm": "File: WebAssembly binary of an actor.",
        "didl": "File: Candid interface of an actor.",
    },
)

MotokoPackageInfo = provider(
    doc = "Provides information about a Motoko package.",
    fields = {
        "alias": "string: alias that should be used for importing library sources.",
        "path": "string: path to the package",
        "files": "depset: transitive dependency closure.",
    },
)

MotokoAliasesInfo = provider(
    fields = {
        "aliases": "[(string, string)]: list package aliases",
    },
)

def _common_prefix(l, r):
    if l == r:
        return l

    m = min(len(l), len(r))
    p = m
    for i in range(0, m):
        if l[i] != r[i]:
            p = i
            break

    p = l[0:p].rfind("/")
    if p < 0:
        return ""
    return l[0:p].rstrip("/")

def _longest_common_dirname(ps):
    """Returns a path that is the longest common prefix of a sequence of paths.
    Args:
      ps: A sequence of paths.
    Returns:
      The longest common prefix.
    """
    if not ps:
        return ""
    lcd = paths.dirname(ps[0])
    for p in ps:
        lcd = _common_prefix(lcd, paths.dirname(p))
    return lcd

def _lcd_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "", _longest_common_dirname([]))
    asserts.equals(env, "a/b", _longest_common_dirname(["a/b/c.mo", "a/b/d.mo"]))
    asserts.equals(env, "a", _longest_common_dirname(["a/b/c.mo", "a/c/d.mo"]))
    asserts.equals(env, "", _longest_common_dirname(["a/b/c.mo", "b/c/d.mo"]))
    return unittest.end(env)

lcd_test = unittest.make(_lcd_test_impl)

def lcd_test_suite(name):
    unittest.suite(name, lcd_test)

def _collect_aliases(ctx):
    args = []
    visited = {}
    for dep in ctx.attr.deps:
        alias_info = dep[MotokoAliasesInfo]
        for (alias, path) in alias_info.aliases:
            if alias not in visited:
                args += ["--package", alias, path]
                visited[alias] = path
            elif visited[alias] != path:
                fail("Inconsistent library alias %s can be either %s and %s", visited[alias], path)

    return args

def _motoko_package_aspect_impl(target, ctx):
    if MotokoPackageInfo not in target:
        return None

    pkg_info = target[MotokoPackageInfo]
    aliases = [(pkg_info.alias, pkg_info.path)]
    for dep in ctx.rule.attr.deps:
        info = dep[MotokoAliasesInfo]
        aliases += info.aliases

    return MotokoAliasesInfo(aliases = aliases)

motoko_package_aspect = aspect(
    implementation = _motoko_package_aspect_impl,
    attr_aspects = ["deps"],
)

def _motoko_library_impl(ctx):
    args = _collect_aliases(ctx)

    args.append("--check")
    args += [f.path for f in ctx.files.srcs]

    path = _longest_common_dirname([src.path for src in ctx.files.srcs])

    alias = ctx.label.name
    if ctx.attr.package:
        alias = ctx.attr.package

    dummy_out = ctx.actions.declare_file(ctx.label.name + ".check")

    moc = ctx.executable._moc

    cmd = " ".join([moc.path] + args + ["&&", "touch", dummy_out.path])

    files = depset(
        direct = ctx.files.srcs,
        transitive = [dep[MotokoPackageInfo].files for dep in ctx.attr.deps],
    )

    ctx.actions.run_shell(
        command = cmd,
        outputs = [dummy_out],
        tools = [moc],
        mnemonic = "MotokoCheck",
        progress_message = "Type-checking Motoko package %s" % alias,
        inputs = files.to_list(),
    )

    return [
        DefaultInfo(files = depset([dummy_out])),
        MotokoPackageInfo(
            alias = alias,
            path = path,
            files = files,
        ),
    ]

def _motoko_binary_impl(ctx):
    pkg_args = _collect_aliases(ctx)

    moc = ctx.executable._moc
    out_wasm = ctx.actions.declare_file(ctx.label.name + ".wasm")
    out_didl = ctx.actions.declare_file(ctx.label.name + ".did")

    args = ctx.actions.args()
    args.add_all(pkg_args)
    args.add_all(["-o", out_wasm.path, "--idl", ctx.file.entry.path])

    files = depset(
        direct = ctx.files.srcs + [ctx.file.entry],
        transitive = [dep[MotokoPackageInfo].files for dep in ctx.attr.deps],
    )

    ctx.actions.run(
        executable = moc,
        arguments = [args],
        inputs = files.to_list(),
        outputs = [out_wasm, out_didl],
        tools = [moc],
        mnemonic = "MotokoCompile",
        progress_message = "Compiling Motoko canister %s" % ctx.label.name,
    )

    return [
        MotokoActorInfo(wasm = out_wasm, didl = out_didl),
        DefaultInfo(files = depset([out_wasm, out_didl])),
    ]

MOC = attr.label(
    default = Label("@build_bazel_rules_motoko_toolchain//:moc"),
    executable = True,
    allow_single_file = True,
    cfg = "host",
)

COMMON_ATTRS = {
    "srcs": attr.label_list(allow_files = MO_FILETYPES),
    "deps": attr.label_list(aspects = [motoko_package_aspect]),
    "_moc": MOC,
}

BIN_ATTRS = dict(COMMON_ATTRS.items() + {
    "entry": attr.label(allow_single_file = MO_FILETYPES),
}.items())

motoko_binary = rule(
    implementation = _motoko_binary_impl,
    attrs = BIN_ATTRS,
    provides = [MotokoActorInfo, DefaultInfo],
)

def _motoko_test_impl(ctx):
    args = _collect_aliases(ctx)

    moc = ctx.executable._moc

    script = " ".join([moc.path] + args + ["-r", ctx.file.entry.path])

    ctx.actions.write(output = ctx.outputs.executable, content = script)

    files = depset(
        direct = ctx.files.srcs + [ctx.file.entry, moc],
        transitive = [dep[MotokoPackageInfo].files for dep in ctx.attr.deps],
    )

    runfiles = ctx.runfiles(files = files.to_list())

    return [DefaultInfo(runfiles = runfiles)]

motoko_test = rule(
    implementation = _motoko_test_impl,
    attrs = BIN_ATTRS,
    test = True,
)

motoko_library = rule(
    implementation = _motoko_library_impl,
    attrs = dict(COMMON_ATTRS.items() + {
        "package": attr.string(doc = "string: Package alias; if not specified, it's the same as the rule's label."),
    }.items()),
)
