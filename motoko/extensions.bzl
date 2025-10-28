"""Bzlmod module extensions for rules_motoko.

This provides an extension that sets up the Motoko toolchain repository
so users don't need to write WORKSPACE code when using Bazel modules.
"""

load("//motoko:repositories.bzl", "motoko_register_toolchain")

# Users invoke from their MODULE.bazel like:
#   motoko = use_extension("@rules_motoko//motoko:extensions.bzl", "motoko")
#   motoko.toolchain(version = "0.8.7")
#   use_repo(motoko, "motoko_toolchain")

def _find_modules(module_ctx):
    root = None
    our_module = None
    for mod in module_ctx.modules:
        if mod.is_root:
            root = mod
        if mod.name == "rules_motoko":
            our_module = mod
    if root == None:
        root = our_module
    if our_module == None:
        fail("Unable to find rules_motoko module")

    return root, our_module

def _motoko_ext_impl(module_ctx):
    # Toolchain configuration is only allowed in the root module, or in
    # rules_motoko.
    # See https://github.com/bazelbuild/bazel/discussions/22024 for discussion.
    root, rules_motoko = _find_modules(module_ctx)
    toolchains = root.tags.toolchain or rules_motoko.tags.toolchain or []
    for toolchain in toolchains:
        # Create the toolchain repo with a stable, well-known name
        # so existing labels like @motoko_toolchain continue to work.
        motoko_register_toolchain(motoko_version = toolchain.version)

motoko = module_extension(
    implementation = _motoko_ext_impl,
    tag_classes = {
        "toolchain": tag_class(
            attrs = {
                "version": attr.string(doc = "Motoko compiler version to install."),
            },
            doc = "Configure the Motoko toolchain repository created by rules_motoko.",
        ),
    },
)
