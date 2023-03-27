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
            url = "https://github.com/dfinity/motoko/releases/download/0.8.5/motoko-linux64-0.8.5.tar.gz",
            sha256 = "a48da001e85077fea41029bebe4ec30b2dd9f4e31039b54852270a48f41f084f",
        )
    elif os_name == "mac os x":
        repository_ctx.download_and_extract(
            url = "https://github.com/dfinity/motoko/releases/download/0.8.5/motoko-macos-0.8.5.tar.gz",
            sha256 = "ab9c78b0c8d96ed9b6a1618c5643d1d9829e4716db58ee875c461ba0444d17ef",
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
