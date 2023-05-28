---
title: "Automatic Releases to Maven Central with Travis and SBT"
tags:
  - sbt
  - Scala
description:
  Enabling automatic releases for your open source Scala project with Travis and SBT.
image: /assets/media/articles/sbt.png
---

<p class="intro" markdown='1'>Builds and deployments of new versions and snapshots is a pain. This article is an explanation to how I automated this process for [monix.io](https://monix.io), an open source Scala library that's making use of [SBT](http://www.scala-sbt.org/) as the build tool and [travis-ci.org](https://travis-ci.org/) as the continuous integration.</p>

What this setup does is to trigger a `publish` script that
automatically deploys packages on Maven Central:

1. whenever you tag a release by pushing a version tag in Git, like
   `v1.10.0`
2. whenever you push into the `snapshot` branch, the result being
   hashed versions, e.g. `1.10.0-36fa3d3`, where the hash appended
   as a suffix is the Git commit hash; these hashed versions are like
   snapshot releases, but better because people can rely on them to
   remain in Maven Central and thus less volatile

After you read this article, you can use the setup of these projects
for inspiration:

- [github.com/monix/shade](https://github.com/monix/shade/)
- [github.com/monix/monix](https://github.com/monix/monix/)

**WARNING:** with this process you'll have to
trust [Travis-ci.org](https://travis-ci.org/) with your PGP private
key for signing the published binaries. If that's an acceptable risk
or not, that's up to you. See below.

## Generating a PGP Key Pair

For deployments to Sonatype / Maven Central the built packages need to
be signed. If you don't have an existing PGP key, one can be easily
generated.

**WARNING:** do not give out your personal PGP private key that you
use to sign emails or for online transactions. Generate a special PGP
key pair just for your project.

I'm currently using a MacOS machine, so for managing PGP
keys I'm using the open source [GPG Suite](https://gpgtools.org/),
coming with a nice GUI interface.

As far as I know GPG comes installed by default on all major Linux
operating systems and for Windows checkout this
[download page on gnupg.org](https://www.gnupg.org/download/index.en.html).

With the GPG command line tools installed you can generate a PGP key pair
like this:

```
$ gpg --gen-key
```

Steps:

- accept the default `RSA` for the kind of key
- enter the desired key size, the bigger the better, so enter `4096`
- for expiration, I preferred a key that doesn't expire, although this might not be wise
- for an email address, enter a valid one
- I recommend encrypting your private key with a generous passphrase
  that you then store in 1Password / LastPass ;-)

To get the ID of the newly generated key you can do:

```
$ gpg --list-secret-keys --keyid-format LONG
```

To export this newly generated key, assuming that `2673B174C4071B0E`
is the key ID, you'll need both the public key and the private one,
but they can be dumped in the same file:

```
gpg -a --export 2673B174C4071B0E > my-key.asc
gpg -a --export-secret-keys 2673B174C4071B0E >> my-key.asc
```

I also keep these in 1Password btw.

To configure SBT to sign your packages with a key living in the
project's repository you'll need a PGP key ring. Such a key ring is
basically a database of multiple PGP keys. You need to have one to
keep in the repository of your project. Normally these keys are kept
in:

- `$HOME/.gnupg/pubring.gpg` for the public keys
- `$HOME/.gnupg/secring.gpg` for the private keys

In the `$PROJECT` root we need a custom key ring containing just the
key we need, like this:

- `$PROJECT/project/.gnupg/pubring.gpg` for the public keys
- `$PROJECT/project/.gnupg/secring.gpg` for the private keys

These files are going to be encrypted, to provide minimal protection.
To generate this ring in your project, go to you're project's root
directory and then:

```
gpg --no-default-keyring \
  --primary-keyring `pwd`/project/.gnupg/pubring.gpg \
  --secret-keyring `pwd`/project/.gnupg/secring.gpg \
  --keyring `pwd`/project/.gnupg/pubring.gpg \
  --fingerprint \
  --import path/to/my-key.asc
```

The `my-key.asc` file is the one that you've created in the previous step.

After you create these files, make sure to delete any junk from
`$PROJECT/project/.gnupg`, so verify the newly created files with
`git status`.

NOTE: check the newly created files, because the `gpg` command line
tools might generate junk. We only want those 2 files (`pubring.gpg`
and `secring.gpg`), so check your project directory with `git status`
and delete anything extra.

## Configuring SBT

Curently in [monix.io](https://monix.io) I'm using the following plugins:

- [sbt-pgp](https://github.com/sbt/sbt-pgp) for signing packages with PGP
- [sbt-git](https://github.com/sbt/sbt-git) for making use of Git from
  SBT, relevant here if you want to do Git-enabled version hashes
- [sbt-sonatype](https://github.com/xerial/sbt-sonatype) for automatically
  publishing artifacts to Maven Central

For PGP the configuration is as follows:

```scala
useGpg := false
usePgpKeyHex("2673B174C4071B0E")
pgpPublicRing := baseDirectory.value / "project" / ".gnupg" / "pubring.gpg"
pgpSecretRing := baseDirectory.value / "project" / ".gnupg" / "secring.gpg"
pgpPassphrase := sys.env.get("PGP_PASS").map(_.toArray)
```

Explanation:

- `useGpg := false` says that we do not want to use the GPG tools
  installed on your computer, but rather the implementation that
  `sbt-pgp` ships with; in my experience this is a must, otherwise
  depending on the GPG tools you have, you won't be able to make it
  use a different pgp ring
- `usePgpKeyHex` forces a certain key to be used for signing by
  specifying its key
- `pgpPublicRing` and `pgpPublicRing` specify the path to a GPG ring
  that contains the key you want, instead of the default one which is
  usually `$HOME/.gnupg/pubring.gpg` and `$HOME/.gnupg/secring.gpg`
- `pgpPassphrase` is a GPG passphrase for the used key, that's taken
  from the env variable named `PGP_PASS`; Travis has the ability to
  set such env variables to be available in your build

For publishing to Sonatype, we'll need these settings:

```scala
sonatypeProfileName := organization.value

credentials += Credentials(
  "Sonatype Nexus Repository Manager",
  "oss.sonatype.org",
  sys.env.getOrElse("SONATYPE_USER", ""),
  sys.env.getOrElse("SONATYPE_PASS", "")
)

isSnapshot := version.value endsWith "SNAPSHOT"

publishTo := Some(
  if (isSnapshot.value)
    Opts.resolver.sonatypeSnapshots
  else
    Opts.resolver.sonatypeStaging
)
```

In addition to these options, for Sonatype we also need the required
artifact info (e.g. license, homepage, authors). Here's what I have
for Shade, adjust accordingly:

```scala
licenses := Seq("MIT" -> url("https://opensource.org/licenses/MIT"))
homepage := Some(url("https://github.com/monix/shade"))

scmInfo := Some(
  ScmInfo(
    url("https://github.com/monix/shade"),
    "scm:git@github.com:monix/shade.git"
  ))

developers := List(
  Developer(
    id="alexelcu",
    name="Alexandru Nedelcu",
    email="noreply@alexn.org",
    url=url("https://alexn.org")
  ))
```

TIP, to find out the ID of a license type, see this cool list:
[spdx.org/licenses/](https://spdx.org/licenses/).

You'll need those two environment variables set in Travis's settings,
more details below.

And then to enable Git versioning for snapshots (e.g. `3.0.0-9d94d3d`)
you can do:

```scala
enablePlugins(GitVersioning)

/* The BaseVersion setting represents the in-development (upcoming) version,
 * as an alternative to SNAPSHOTS.
 */
git.baseVersion := "3.0.0"

val ReleaseTag = """^v([\d\.]+)$""".r
git.gitTagToVersionNumber := {
  case ReleaseTag(v) => Some(v)
  case _ => None
}

git.formattedShaVersion := {
  val suffix = git.makeUncommittedSignifierSuffix(git.gitUncommittedChanges.value, git.uncommittedSignifier.value)

  git.gitHeadCommit.value map { _.substring(0, 7) } map { sha =>
    git.baseVersion.value + "-" + sha + suffix
  }
}
```

Now test your setup with this command:

```
$ PGP_PASS="xxxxxx" sbt publishLocalSigned
```

Replace `xxxxxx` with your passphrase. If this command works, then we
are good thus far.

## Configuring Travis

In `build.sbt` I configured these 2 commands:

```scala
addCommandAlias("ci-all",  ";+clean ;+compile ;+test ;+package")
addCommandAlias("release", ";+publishSigned ;sonatypeReleaseAll")
```

Then the `.travis.yml` file has something like this:

```yml
language: scala
sudo: required
dist: trusty
group: edge

matrix:
  include:
    - jdk: oraclejdk8
      scala: 2.12.3
      env: COMMAND=ci-all PUBLISH=true

script:
  - sbt -J-Xmx6144m ++$TRAVIS_SCALA_VERSION $COMMAND

after_success:
  - ./project/publish
```

And then the `project/publish` script, which I've built with Ruby
(since I don't know Bash well :)):

```ruby
#!/usr/bin/env ruby

def exec(cmd)
  abort("Error encountered, aborting") unless system(cmd)
end

puts "CI=#{ENV['CI']}"
puts "TRAVIS_BRANCH=#{ENV['TRAVIS_BRANCH']}"
puts "TRAVIS_PULL_REQUEST=#{ENV['TRAVIS_PULL_REQUEST']}"
puts "PUBLISH=#{ENV['PUBLISH']}"
puts

unless ENV['CI'] == 'true'
  abort("ERROR: Not running on top of Travis, aborting!")
end

unless ENV['PUBLISH'] == 'true'
  puts "Publish is disabled"
  exit
end

branch = ENV['TRAVIS_BRANCH']
version = nil

unless branch =~ /^v(\d+\.\d+\.\d+)$/ ||
  (branch == "snapshot" && ENV['TRAVIS_PULL_REQUEST'] == 'false')

  puts "Only triggering deployment on the `snapshot` branch, or for version tags " +
       "and not for pull requests or other branches, exiting!"
  exit 0
else
  version = $1
  puts "Version branch detected: #{version}" if version
end

# Forcing a change to the root directory, if not there already
Dir.chdir(File.absolute_path(File.join(File.dirname(__FILE__), "..")))

# Go, go, go
exec("sbt release")
```

Give execution permissions to this script:

```
$ chmod +x ./project/publish
```

Remember to push your changes:

```
$ git add .
$ git commit -am 'Build changes for automatic releases'
$ git push
```

### Setting environment variables

As a final step we need to set the following environment variables in Travis:

- `PGP_PASS`: the passphrase we used to encrypt our private PGP key
- `SONATYPE_USER`: a user to login to Sonatype, used by SBT to publish and deploy releases on Sonatype
- `SONATYPE_PASS`: a password to login to Sonatype, used by SBT to publish and deploy releases on Sonatype

See the article on
[adding environment variables to Travis](https://docs.travis-ci.com/user/environment-variables/).

NOTE: to get a `SONATYPE_USER` and a `SONATYPE_PASS` go to the
[User Profile on Sonatype](https://oss.sonatype.org/#profile;User%20Token) page
and access the "*User Token*", or generate a new one.

Here's a screenshot of how my setup currently looks like:

<figure>
  <img src="{% link /assets/media/articles/travis-env-vars.png %}" />
</figure>

### Alternative Env with Travis Encryption

As an alternative to setting those environment variables in Travis's
UI, you can use Travis's mechanism for encrypting stuff to set these
values in `.travis.yml`. See
the [Encryption Keys](https://docs.travis-ci.com/user/encryption-keys)
document.

First install the `travis` command line tool:

```
$ gem install travis
```

And then do the following, replacing `xxxxx` with your key:

```
$ travis encrypt 'PGP_PASS=xxxxx' --add

$ travis encrypt 'SONATYPE_USER=xxxxx' --add

$ travis encrypt 'SONATYPE_PASS=xxxxx' --add
```

NOTE: if your env values have special chars, they might need to be
escaped for Bash to not trigger any errors. See document above.

These commands will modify your `.travis.yml` file, adding a section
that resembles the following:

```
env:
  global:
  - secure: GRdfKNrJn/zqjaDWE+16HCfuCSf/wsDpL...
  - secure: SPSIblLKFVns7pVY1x3SEs4/16htY5HUz...
  - secure: YVx2BSSsqF7LdYTwinf6o8nqJiYL9FeFA...
```

Now this can be committed in your repository and Travis will take care
of decrypting those values.

## Publishing

For publishing hashed snapshot versions, we need a `snapshot` branch,
as that's what the script above looks for.

So create this branch by forking `master` and pushing it, like so:

```
$ git checkout master

$ git checkout -b snapshot
$ git push --set-upstream origin snapshot
```

If everything goes well, we should have a new hashed version published,
but watch the output of Travis for any problems.

## Extra Resources

I've written this document while preparing the Shade project for
automatic deployments. So here's for inspiration:

- [commits in monix/shade](https://github.com/monix/shade/compare/1c373f8714e92b48a8bb2337158f61e5650d260a...d712897f122642835cbcd32d159e917c59e7685c)
- [snapshot release sample](https://travis-ci.org/monix/shade/jobs/265215531)
  (that published `1.10.0-d712897` on Maven Central)
- [release of v1.10.0](https://travis-ci.org/monix/shade/jobs/265221087)
  (that published the final `1.10.0` on Maven Central)

## In Closing

So that's about it. Pretty painful if you ask me, but hopefully we
don't have to do this too often.

I've written this article for myself actually, because I keep
forgetting what I did the first time.
