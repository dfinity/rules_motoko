"""Repository setup for rules_motoko (WORKSPACE macro and helpers)."""

load("//motoko:versions.bzl", "MOC")

MOC_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["moc", "mo-doc"])
"""

def _moc_impl(repository_ctx):
    os_name = repository_ctx.os.name
    if os_name not in MOC:
        fail("Unsupported operating system: " + os_name)

    arch = repository_ctx.os.arch
    if arch not in MOC[os_name]:
        fail("Unsupported architecture: " + arch + " for OS: " + os_name)

    v = repository_ctx.attr.motoko_version
    moc_versions = MOC[os_name][arch]
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
        "motoko_version": attr.string(doc = "The motoko compiler version."),
    },
)

def motoko_register_toolchain(motoko_version):
    """Creates the Motoko toolchain repository used by rules_motoko.

    Args:
        motoko_version: The Motoko compiler version to download.
    """
    _moc(name = "motoko_toolchain", motoko_version = motoko_version)
