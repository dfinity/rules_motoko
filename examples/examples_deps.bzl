"""Module extension for examples' external repos."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

BUILD_FILE_CONTENT = """
filegroup(name = "sources", srcs = glob(["**/*.mo"]), visibility = ["//visibility:public"])
"""

def _examples_deps_impl(_module_ctx):
    http_archive(
        name = "motoko_core",
        build_file_content = BUILD_FILE_CONTENT,
        sha256 = "219a6e0cdd7798b67c65d5d4a5db317b38f0d52181c95747edee754e2b504248",
        strip_prefix = "motoko-core-2.6.0/src",
        urls = [
            "https://github.com/caffeinelabs/motoko-core/archive/refs/tags/v2.6.0.zip",
        ],
    )

examples_deps = module_extension(
    implementation = _examples_deps_impl,
)
