load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//motoko:versions.bzl", "MOC")

MOC_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["moc", "mo-doc"])
"""

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
        "motoko_version": attr.string(doc = "The motoko compiler version."),
    },
)

def rules_motoko_dependencies(motoko_version):
    _moc(name = "build_bazel_rules_motoko_toolchain", motoko_version = motoko_version)
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "f7be3474d42aae265405a592bb7da8e171919d74c16f082a5457840f06054728",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz",
        ],
    )
