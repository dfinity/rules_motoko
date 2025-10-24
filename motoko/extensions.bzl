"""Bzlmod module extensions for rules_motoko.

This provides an extension that sets up the Motoko toolchain repository
so users don't need to write WORKSPACE code when using Bazel modules.
"""

load("//motoko:repositories.bzl", "DEFAULT_VERSION", "motoko_register_toolchain")

# Users invoke from their MODULE.bazel like:
#   motoko = use_extension("@rules_motoko//motoko:extensions.bzl", "motoko")
#   motoko.toolchain(version = "0.8.7")  # optional, defaults to DEFAULT_VERSION
#   use_repo(motoko, "build_bazel_rules_motoko_toolchain")

def _motoko_ext_impl(module_ctx):
    # Default to our repositories.bzl DEFAULT_VERSION, allow overrides via tags.
    version = DEFAULT_VERSION
    for mod in module_ctx.modules:
        for tag in getattr(mod.tags, "toolchain", []):
            if tag.version:
                version = tag.version

    # Create the toolchain repo with a stable, well-known name
    # so existing labels like @build_bazel_rules_motoko_toolchain continue to work.
    motoko_register_toolchain(motoko_version = version)

motoko = module_extension(
    implementation = _motoko_ext_impl,
    tag_classes = {
        "toolchain": tag_class(
            attrs = {
                "version": attr.string(doc = "Motoko compiler version to install (defaults to repositories.bzl DEFAULT_VERSION)."),
            },
            doc = "Configure the Motoko toolchain repository created by rules_motoko.",
        ),
    },
)
