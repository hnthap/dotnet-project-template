# .NET API template

> Replace this README with your own once you're done setting up your project
> from the template.

A starting point for an HTTP API on ASP.NET Core 10. It builds and tests
with make, and GitLab CI publishes it as a container image.

The API is small on purpose: a health check, ProblemDetails errors and JSON
logs. The rest is build plumbing you'd otherwise set up by hand, such as
locked and audited packages, a license check, formatting enforced in CI, and
a container image built by the .NET SDK and tagged from git.

## Start a new service

1. Copy this repository into a new project.
2. Replace the Hello World endpoint in src/Api/Program.cs.
3. Push. CI builds and tests every push, and publishes an image to the
   project's container registry from the default branch and from v* tags.

To set up a machine, run the API or cut a release, see
[DEVELOPMENT.md](./DEVELOPMENT.md).

## Deployment

The repository stops at a published image on purpose: deployment is better
handled by a separate CD setup that pulls the image from the registry.

The image listens on port 8080, runs as a non-root user and starts in the
Production environment. Settings come from environment variables. Behind a
proxy that isn't on loopback, add the proxy's network so the API trusts its
X-Forwarded-For and X-Forwarded-Proto headers:

```bash
ForwardedHeaders__KnownNetworks__0=10.0.0.0/8
```

To check an image locally before you push:

```bash
make image
docker load -i artifacts/image.tar.gz
docker run --rm -p 8080:8080 api:<version>
```
