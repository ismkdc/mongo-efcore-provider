# Releasing

Publishing uses NuGet Trusted Publishing (OIDC). No API key exists in this repository or in GitHub secrets.

1. Set `EF11Version` in `Versions.props` to the EF Core `11.0.x` being targeted.
2. Set `PackageVersion` in `ismkdc.props` to the same `11.0.x`.
3. Update `NOTICE.md` if the base commit changed.
4. Run `dotnet build MongoDB.EFCoreProvider.sln -c Release` and the unit tests.
5. Commit, then `git tag v11.0.x && git push origin ef11 --tags`.
6. The `publish` workflow (`.github/workflows/publish.yml`, environment `production`) exchanges the
   GitHub OIDC token for a short-lived NuGet key and pushes the package.
7. Verify https://www.nuget.org/packages/ismkdc.MongoDB.EntityFrameworkCore and create the GitHub release.

The NuGet policy `ismkdc-mongo-efcore` is bound to this repository, the `publish.yml` file name and the
`production` environment. Renaming any of them requires updating the policy on nuget.org.
New policies stay temporarily active for 7 days; the first successful publish makes them permanent.
