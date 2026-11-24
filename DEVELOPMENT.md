# Development

## Prerequisites

- make and git
- .NET 10 SDK, 10.0.1xx band (pinned in `global.json`)

On RHEL-based machines (RHEL, AlmaLinux, Rocky):

```bash
sudo dnf install -y make git dotnet-sdk-10.0
```

## Common tasks

| Command         | What it does                                              |
| --------------- | --------------------------------------------------------- |
| `make`          | Everything CI runs: lock files, format, licenses, build, test, publish |
| `make fmt`      | Format the code and apply code-style fixes                |
| `make test`     | Restore, build and run the tests                          |
| `make clean`    | Remove `bin/`, `obj/` and `artifacts/`                    |

## Adding or updating a package

Versions live in `Directory.Packages.props`; projects reference packages without a version.

1. Add `<PackageVersion Include="Foo" Version="1.2.3" />` to `Directory.Packages.props`.
2. Add `<PackageReference Include="Foo" />` to the project that uses it.
3. Run `dotnet restore App.slnx` to update that project's `packages.lock.json`.
4. Commit the lock file. `make` fails if a lock file is missing from git or out of date.

If `make` rejects the package's license, read the license before adding its
identifier to `allowed-licenses.json`. A high or critical vulnerability
fails the restore; low and moderate ones are reported as warnings.

## Editor

### VSCodium

`.vscode/extensions.json` recommends `muhammad-sammy.csharp` from Open VSX
for code completion and diagnostics in VSCodium. It is an open-source build of
Microsoft's C# extension: the same Roslyn language server, with Samsung's
netcoredbg in place of Microsoft's debugger, which is licensed for Microsoft's
products only.

The language server uses the .NET SDK installed on the same OS as the editor.
If the editor runs on Windows and you build in WSL, install a 10.0.1xx SDK on
Windows as well, then restart the editor:

```powershell
# List the versions and pick the newest 10.0.1xx
winget show Microsoft.DotNet.SDK.10 --versions
winget install Microsoft.DotNet.SDK.10 --version 10.0.115
```
