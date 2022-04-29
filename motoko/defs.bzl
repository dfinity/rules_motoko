MO_FILETYPES = [".mo"]

MotokoActorInfo = provider(
    doc = "Provides information about an IC actor.",
    fields = {
        "wasm": "File: WebAssembly binary of an actor.",
        "didl": "File: Candid interface of an actor.",
    },
)

def _dirname(p):
    """Returns the dirname of a path.
    The dirname is the portion of `p` up to but not including the file portion
    (i.e., the basename). Any slashes immediately preceding the basename are not
    included, unless omitting them would make the dirname empty.
    Args:
      p: The path whose dirname should be returned.
    Returns:
      The dirname of the path.
    """
    prefix, sep, _ = p.rpartition("/")
    if not prefix:
        return sep
    else:
        # If there are multiple consecutive slashes, strip them all out as Python's
        # os.path.dirname does.
        return prefix.rstrip("/")

def _collect_aliases(ctx):
    args = []
    for (alias, location) in ctx.attr.packages.items():
        loc = ctx.expand_location(location)
        dirname = _dirname(loc.split(" ")[0])
        print(dirname)
        args += ["--package", alias, dirname]

    return args

def _motoko_binary_impl(ctx):
    pkg_args = _collect_aliases(ctx)

    moc = ctx.executable._moc
    out_wasm = ctx.actions.declare_file(ctx.label.name + ".wasm")
    out_didl = ctx.actions.declare_file(ctx.label.name + ".did")

    args = ctx.actions.args()
    args.add_all(pkg_args)
    args.add_all(["-o", out_wasm.path, "--idl", ctx.file.entry.path])

    ctx.actions.run(
        executable = moc,
        arguments = [args],
        inputs = ctx.files.srcs + ctx.files.deps + [ctx.file.entry],
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

ATTRS = {
    "entry": attr.label(allow_single_file = MO_FILETYPES),
    "srcs": attr.label_list(allow_files = MO_FILETYPES),
    "packages": attr.string_dict(doc = "dict[string, string]: Package specifications"),
    "deps": attr.label_list(),
    "_moc": MOC,
}

motoko_binary = rule(
    implementation = _motoko_binary_impl,
    attrs = ATTRS,
    provides = [MotokoActorInfo, DefaultInfo],
)

def _motoko_test_impl(ctx):
    pkg_args = _collect_aliases(ctx)

    moc = ctx.executable._moc

    script = " ".join([moc.path] + pkg_args + ["-r", ctx.file.entry.path])

    ctx.actions.write(output = ctx.outputs.executable, content = script)

    runfiles = ctx.runfiles(files = ctx.files.srcs + ctx.files.deps + [ctx.file.entry, moc])

    return [DefaultInfo(runfiles = runfiles)]

motoko_test = rule(
    implementation = _motoko_test_impl,
    attrs = ATTRS,
    test = True,
)
