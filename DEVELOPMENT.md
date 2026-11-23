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
