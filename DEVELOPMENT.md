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
| `make image`    | Build the container image into `artifacts/image.tar.gz`   |
| `make clean`    | Remove `bin/`, `obj/` and `artifacts/`                    |

## Running the API

```bash
dotnet run --project src/Api
```

The API starts at http://localhost:5200 in the Development environment.
Press Ctrl+C to stop it.

| Path               | Returns                                 |
| ------------------ | --------------------------------------- |
| `/healthz`         | `Healthy` while the API is running      |
| `/openapi/v1.json` | The OpenAPI document (Development only) |

## Versions and releases

The version comes from git tags. `make` stamps it into the assemblies and
uses it as the container image tag:

| Commit                   | Version                     |
| ------------------------ | --------------------------- |
| Tagged `v1.2.0`          | `1.2.0`                     |
| 5 commits after `v1.2.0` | `1.2.0-5-g789abcd`          |
| No `v` tag yet           | `0.0.0-5-g789abcd`          |
| With uncommitted changes | Any of the above + `-dirty` |

To release, tag the commit and push the tag:

```bash
git tag v1.2.0
git push origin v1.2.0
```

CI then pushes the image `1.2.0`. Every commit to the default branch also
gets an image, tagged with its version, such as `1.2.0-5-g789abcd`.

Pick the number by [Semantic Versioning](https://semver.org): bump MAJOR for
breaking API changes, MINOR for new features, and PATCH for fixes. Don't move
or reuse a pushed tag, because an image with that version already exists.

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
