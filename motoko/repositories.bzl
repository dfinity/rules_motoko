"""Repository setup for rules_motoko (WORKSPACE macro and helpers)."""

load("//motoko:versions.bzl", "MOC")

MOC_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["moc", "mo-doc"])
"""

DEFAULT_VERSION = "0.8.7"

def _moc_impl(repository_ctx):
    os_name = repository_ctx.os.name
    if os_name not in MOC:
        fail("Unsupported operating system: " + os_name)

    v = repository_ctx.attr.motoko_version
    moc_versions = MOC[os_name]
    if v not in moc_versions:
        fail("Unsupported motoko version: " + v)
    asset = moc_versions[v]

    repository_ctx.download_and_extract(
        url = asset["url"],
        sha256 = asset["sha256"],
    )
    repository_ctx.file("BUILD.bazel", MOC_BUILD, executable = False)

_moc = repository_rule(
    implementation = _moc_impl,
    attrs = {
        "motoko_version": attr.string(doc = "The motoko compiler version.", default = DEFAULT_VERSION),
    },
)

def motoko_register_toolchain(motoko_version = DEFAULT_VERSION):
    """Creates the Motoko toolchain repository used by rules_motoko.

    Args:
        motoko_version: The Motoko compiler version to download.
    """
    _moc(name = "build_bazel_rules_motoko_toolchain", motoko_version = motoko_version)
