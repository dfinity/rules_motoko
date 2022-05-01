load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

MOC_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["moc", "mo-doc"])
"""

def _moc_impl(repository_ctx):
    os_name = repository_ctx.os.name
    if os_name == "linux":
        repository_ctx.download_and_extract(
            url = "https://github.com/dfinity/motoko/releases/download/0.6.25/motoko-linux64-0.6.25.tar.gz",
            sha256 = "9bfe7ca3c179c11af5ab7f2fab980abcfcaefb927f86e6b539d240d9385d24a8",
        )
    elif os_name == "mac os x":
        repository_ctx.download_and_extract(
            url = "https://github.com/dfinity/motoko/releases/download/0.6.25/motoko-macos-0.6.25.tar.gz",
            sha256 = "ea3bdd1d3b8410ee9442bcc3508381e568c86a96ee8a1aa82870e479ece48f05",
        )
    else:
        fail("Unsupported operating system: " + os_name)

    repository_ctx.file("BUILD.bazel", MOC_BUILD, executable = False)

_moc = repository_rule(
    implementation = _moc_impl,
    attrs = {},
)

def rules_motoko_dependencies():
    _moc(name = "build_bazel_rules_motoko_toolchain")
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "f7be3474d42aae265405a592bb7da8e171919d74c16f082a5457840f06054728",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz",
        ],
    )
