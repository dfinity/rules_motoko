"""Module extension for examples' external repos."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

BUILD_FILE_CONTENT = """
filegroup(name = "sources", srcs = glob(["*.mo"]), visibility = ["//visibility:public"])
"""

def _examples_deps_impl(_module_ctx):
    # Create both repos unconditionally; they are cheap and used by examples.
    http_archive(
        name = "motoko_base",
        build_file_content = BUILD_FILE_CONTENT,
        sha256 = "cdb7abfb280bffec3fb0200032d1e5c6f094f209a68219d3c82ce886b2339147",
        strip_prefix = "motoko-base-moc-0.16.3/src",
        urls = [
            "https://github.com/dfinity/motoko-base/archive/refs/tags/moc-0.16.3.zip",
        ],
    )
    http_archive(
        name = "motoko_sha",
        build_file_content = BUILD_FILE_CONTENT,
        sha256 = "38bf0d103bb6969e6061aa0aa349751c2b73591c8725f312c145c53fdea1c810",
        strip_prefix = "motoko-sha-9e2468f51ef060ae04fde8d573183191bda30189/src",
        urls = [
            "https://github.com/enzoh/motoko-sha/archive/9e2468f51ef060ae04fde8d573183191bda30189.zip",
        ],
    )

examples_deps = module_extension(
    implementation = _examples_deps_impl,
)
