# stackql-windows-installer

Builds, releases and publishes the StackQL packages for Windows:

- `stackql_windows_amd64.msi` - Authenticode signed MSI installer
- `stackql_windows_amd64.zip` - ZIP containing the signed `stackql.exe`
- the `stackql` Chocolatey package, which installs the MSI from the releases proxy

This repo replaces the former `stackql-msi` and `chocolatey-install` repos.

## Prerequisites

- Windows with PowerShell 5.1 or later
- [WiX Toolset](https://wixtoolset.org/) v4 or later (`wix.exe` on the PATH) with the UI extension installed: `wix extension add -g WixToolset.UI.wixext`
- [GitHub CLI](https://cli.github.com/) authenticated with access to the `stackql` org (`gh auth login`)
- The hardware token holding the StackQL Studios code signing certificate, and the token client software (for example Thales SafeNet Authentication Client)
- Chocolatey, only if you want to build or test the Chocolatey package locally

Two things to be aware of when building:

- File versioning does not work if this repo lives in a synced folder (Dropbox, OneDrive and similar)
- AV scanning needs to be suspended temporarily while building

## Release flow

The overall StackQL release is driven from the [stackql](https://github.com/stackql/stackql) repo: a tag is pushed, a GitHub release is created, and the signed platform packages are added to that release as assets. Downloads are served through the releases proxy at `releases.stackql.io`, which is where the Chocolatey package pulls the MSI from.

The Windows part of that flow is the steps below. Run each script from the root of this repo.

### Before you start

Save the unsigned Windows build for the release as `downloaded\stackql_windows_amd64.zip`. The `downloaded`, `bin` and `msi` directories are gitignored.

### Step 1: build and sign the MSI and ZIP

```powershell
.\build.ps1 true
```

Insert the hardware token before running. The script pauses so you can confirm the token is inserted, then prompts for the token password when signing the EXE and again when signing the MSI. Enter the password carefully: the token is locked out after more than 3 incorrect attempts.

The script expands the downloaded ZIP into `bin\`, stamps the version and file properties onto `stackql.exe`, signs it, builds and signs the MSI, then writes the outputs to `msi\`:

- `stackql_<version>_windows_amd64.msi` and `stackql_windows_amd64.msi`
- `stackql_<version>_windows_amd64.zip` and `stackql_windows_amd64.zip`

Running `.\build.ps1` without `true` produces unsigned packages. These are fine for local testing but `release.ps1` will refuse to upload them.

### Step 2: upload the release assets

```powershell
.\release.ps1
```

The script reads the `ProductVersion` from `msi\stackql_windows_amd64.msi` and the file version of the `stackql.exe` inside `msi\stackql_windows_amd64.zip` (nothing is installed), checks that both match and are validly signed, then uploads both files as assets to the `stackql/stackql` release tagged `v<version>`. The release must already exist.

Existing assets are never overwritten. If an asset with the same name is already on the release it is skipped with a warning. To replace an asset, delete it from the release on GitHub first and run the script again. Pass `-AllowUnsigned` to upload unsigned packages.

### Step 3: prepare the Chocolatey package

Wait until the releases proxy is serving the new MSI at `https://releases.stackql.io/stackql/latest/stackql_windows_amd64.msi`, then run:

```powershell
.\publish-prep.ps1 0.11.669
```

The version can be given with or without the leading `v`. The script downloads the latest MSI from the proxy, confirms that its `ProductVersion` matches the version given (nothing is installed) and fails if it does not. It then updates:

- `chocolatey\tools\chocolateyinstall.ps1` - `checksum64` is set to the SHA256 of the downloaded MSI
- `chocolatey\stackql.nuspec` - `version` and `releaseNotes` are set for the release

### Step 4: publish to Chocolatey

Review the changes, then commit and push to `main`:

```powershell
git add chocolatey
git commit -m "v0.11.669"
git push origin main
```

The push triggers the [chocolatey-publish](.github/workflows/chocolatey-publish.yml) workflow, which:

1. reads the version from `chocolatey\stackql.nuspec`
2. checks whether that version already exists on chocolatey.org and stops if it does, so a push that does not bump the version is a no-op
3. runs `choco pack`, test installs the package on the runner, then pushes it to chocolatey.org using the `CHOCOLATEY_API_KEY` repository secret

The workflow can also be started by hand from the Actions tab.

## Building and testing the Chocolatey package locally

From an elevated PowerShell prompt:

```powershell
cd chocolatey
choco pack
choco install stackql -dv -s "'.;https://chocolatey.org/api/v2/'"
choco uninstall stackql
```

## Repository layout

| Path | Purpose |
| --- | --- |
| `build.ps1` | Step 1: builds and signs the MSI and ZIP |
| `release.ps1` | Step 2: uploads the MSI and ZIP to the GitHub release |
| `publish-prep.ps1` | Step 3: updates the Chocolatey package for a release |
| `stackql.wxs`, `en-us.wxl` | WiX source for the MSI |
| `inc\` | Files bundled into the MSI: EULA, icon, installer images, command shell launcher |
| `lib\` | Build tools: `rcedit` (version stamping) and `signtool` (Authenticode signing) |
| `chocolatey\` | Chocolatey package source: `stackql.nuspec` and `tools\` |
| `.github\workflows\chocolatey-publish.yml` | Publishes the Chocolatey package on push to `main` |
| `downloaded\`, `bin\`, `msi\` | Gitignored build input and outputs |
