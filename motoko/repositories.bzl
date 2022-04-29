MOC_BUILD = """
package(default_visibility = ["//visibility:public"])

exports_files(["moc", "mo-doc"])
"""

def _moc_impl(repository_ctx):
    os_name = repository_ctx.os.name
    if os_name == 'linux':
        repository_ctx.download_and_extract(
            url = "https://github.com/dfinity/motoko/releases/download/0.6.25/motoko-linux64-0.6.25.tar.gz",
            sha256 = "9bfe7ca3c179c11af5ab7f2fab980abcfcaefb927f86e6b539d240d9385d24a8",
        )
    elif os_name == 'mac os x':
        repository_ctx.download_and_extract(
            url = "https://github.com/dfinity/motoko/releases/download/0.6.25/motoko-macos-0.6.25.tar.gz",
            sha256 = "ea3bdd1d3b8410ee9442bcc3508381e568c86a96ee8a1aa82870e479ece48f05",
        )
    else:
        fail("Unsupported operating system: " + os_name)

    repository_ctx.file("BUILD.bazel", MOC_BUILD, executable=False)


_moc = repository_rule(
    implementation = _moc_impl,
    attrs = {}
)

def rules_motoko_dependencies():
    _moc(name = "build_bazel_rules_motoko_toolchain")
