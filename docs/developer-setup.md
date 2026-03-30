# IKE Developer Setup

This guide covers the one-time environment setup required to build IKE
projects. All IKE artifacts are hosted on the IKE Nexus repository at
`https://nexus.tinkar.org` rather than Maven Central, because Maven Central
does not currently support Maven 4.0 / POM model version 4.1.0.

Access to the IKE Nexus repository is available to **active developers on
IKE projects**. Contact the team to obtain your username and password before
proceeding.

---

## Step 1 — Install Java 25

Download OpenJDK 25 from [adoptium.net](https://adoptium.net) or your
preferred distribution. Verify:

```
java -version
# openjdk version "25.0.2" ...
```

Set `JAVA_HOME` to the JDK root if your tooling requires it.

## Step 2 — Install Maven 4

Download Maven 4.0.0-rc-5 (or later) from
[maven.apache.org](https://maven.apache.org/download.cgi).
Unzip and add the `bin/` directory to your `PATH`. Verify:

```
mvn --version
# Apache Maven 4.0.0-rc-5 ...
```

> **Note:** Maven 3.x will not work — the POMs use features only available
> in Maven 4.

## Step 3 — Configure Git Credentials

All component repos are public on GitHub, so **cloning and fetching require
no credentials**. You only need Git credentials configured if you will be
pushing (i.e., you are an active committer on one of the component repos).

### Single GitHub account (most developers)

The simplest approach is HTTPS with a **Personal Access Token (PAT)**:

1. Generate a PAT at GitHub → Settings → Developer settings → Personal access
   tokens. Grant `repo` scope.
2. Store the PAT in your OS credential store so Git uses it automatically:

   **Windows** — Git for Windows installs the Windows Credential Manager
   helper by default. The first time you `git push`, Git will prompt for your
   GitHub username and the PAT as the password. Windows Credential Manager
   saves it and you won't be prompted again.

   **macOS** — The Git Credential Helper for macOS Keychain ships with Xcode
   Command Line Tools and is usually pre-configured. Confirm with:
   ```bash
   git config --global credential.helper
   # osxkeychain
   ```
   On first push Git prompts once, then stores the token in Keychain.

   **Linux** — Install and enable a credential store (e.g., `libsecret`):
   ```bash
   git config --global credential.helper /usr/lib/git-core/git-credential-libsecret
   ```

### Multiple GitHub accounts on one machine

If you push to repos under different GitHub organisations using different
accounts, embed the account identity in Git's SSH config rather than in
repo URLs.

Create or extend `~/.ssh/config` with a host alias per account:

```
Host github.com-account-one
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_account_one

Host github.com-account-two
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_account_two
```

When cloning or adding a remote for a repo that belongs to `account-two`,
use the alias as the hostname:

```bash
git clone git@github.com-account-two:ikmdev/tinkar-core.git
```

Git resolves the alias through `~/.ssh/config`, uses the correct key, and
your repo URLs stay free of embedded usernames.

## Step 4 — Store Nexus Credentials

Credentials are referenced in `settings.xml` via environment variables so
that no passwords are stored in plain text in version-controlled files.

### Windows

Set user-level environment variables using the built-in `setx` command
in a Command Prompt or PowerShell (no elevation required for user variables):

```bat
setx IKE_USER "your-username"
setx IKE_PWD_RELEASES "your-password"
```

`setx` persists the values in the Windows registry under your user profile.
Close and reopen your terminal after running these commands — `setx` does not
update the current session.

Verify in a new terminal:
```bat
echo %IKE_USER%
```

### macOS

Store in the macOS Keychain and load in your shell profile:

```bash
# Store once
security add-generic-password -a "$USER" -s IKE_USER         -w "your-username"
security add-generic-password -a "$USER" -s IKE_PWD_RELEASES -w "your-password"
```

Add to `~/.zshrc`:
```bash
export IKE_USER="$(security find-generic-password -a "$USER" -s IKE_USER -w 2>/dev/null || true)"
export IKE_PWD_RELEASES="$(security find-generic-password -a "$USER" -s IKE_PWD_RELEASES -w 2>/dev/null || true)"
```

### Linux

Add to `~/.bashrc` or `~/.zshrc`. Use your distribution's secrets manager
if available (e.g., `pass`, GNOME Keyring via `secret-tool`), or set directly:

```bash
export IKE_USER="your-username"
export IKE_PWD_RELEASES="your-password"
```

> If storing directly, restrict file permissions: `chmod 600 ~/.bashrc`

## Step 5 — Configure `~/.m2/settings.xml`

Create or update `~/.m2/settings.xml` with the following. If you already
have a `settings.xml`, merge the `<servers>`, `<profiles>`, and
`<activeProfiles>` sections into your existing file.

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.2.0
                              https://maven.apache.org/xsd/settings-1.2.0.xsd">

  <servers>
    <server>
      <id>ike-public</id>
      <username>${env.IKE_USER}</username>
      <password>${env.IKE_PWD_RELEASES}</password>
    </server>
    <server>
      <id>ike-snapshots</id>
      <username>${env.IKE_USER}</username>
      <password>${env.IKE_PWD_RELEASES}</password>
    </server>
    <server>
      <id>ike-releases</id>
      <username>${env.IKE_USER}</username>
      <password>${env.IKE_PWD_RELEASES}</password>
    </server>
  </servers>

  <profiles>
    <profile>
      <id>use-ike-public</id>
      <repositories>
        <repository>
          <id>ike-public</id>
          <url>https://nexus.tinkar.org/repository/ike-public/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
      <pluginRepositories>
        <pluginRepository>
          <id>ike-public</id>
          <url>https://nexus.tinkar.org/repository/ike-public/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>

  <activeProfiles>
    <activeProfile>use-ike-public</activeProfile>
  </activeProfiles>

</settings>
```

## Step 6 — Verify

Run a quick resolution check from any directory:

```
mvn dependency:get -Dartifact=network.ike:ike-parent:42:pom
```

You should see `BUILD SUCCESS`. If you see authentication errors, double-check
that your terminal session has the `IKE_USER` and `IKE_PWD_RELEASES`
environment variables set (Step 4).

---

> This guide will move to a central IKE-Network location as additional
> workspace repos are added to the organization.
