# Arkana

noun ‧ secret knowledge[¹](https://en.wiktionary.org/wiki/arkana)

ar‧ka‧na | \är-​ˈkā-​nə\

> Store your keys and secrets away from your source code. Designed for Android and iOS projects.

# Requirements

## **iOS**

Your project must be using Swift Package Manager or Cocoapods as dependency manager (or both). No support for Carthage.

<sub>Note: this gem was only tested in macOS environments.</sub>

## Android

The Java/Kotlin code generator hasn't been implemented yet. Star this project and check back in the future, or help us build it [here](https://github.com/rogerluan/arkana/issues/1).

# Installation

Add this gem to your `Gemfile` if you're using [bundler](https://bundler.io) (recommended):

```ruby
gem 'arkana'
```

And then run `bundle install` to install it.

Alternatively, you can install it in your entire system instead (not recommended):

```ruby
gem install arkana
```

# Usage

Arkana requires the declaration of a YAML config file, named e.g. `.arkana.yml`. See [template.yml](/template.yml) for practical examples.

Once you have create your config file, you can run Arkana:

```sh
Usage: arkana [options]
    -c /path/to/your/.arkana.yml,         Path to your config file. Defaults to '.arkana.yml'
        --config-filepath
    -e /path/to/your/.env,                Path to your dotenv file. Defaults to '.env' if one exists.
        --dotenv-filepath
    -f, --flavor FrostedFlakes       Flavors are useful, for instance, when generating secrets for white-label projects. See the README for more information
```

Note that you have to prepend `bundle exec` before `arkana` if you manage your dependencies via bundler, as recommended.

Arkana only has one command, which parses your config file and env vars, generating all the code needed. Arkana should always be run before attempting to build your project, to make sure the files exist *and* are up-to-date (according to the current config file). This means you might need to add the Arkana run command in your CI/CD scripts, _fastlane_, Xcode Build Phases, or something similar.

Once the Arkana has been run, you need to add it to your codebase:

**Via Swift Package Manager:** add `ArkanaKeys` (or the `import_name` option that you passed in your config file) to your list of dependencies in your `Package.swift` file, like this:

```swift
…
dependencies: [
    …
    .package(name: "ArkanaKeys", path: "path/to/your/dependencies/ArkanaKeys"),
    …
],
…
```

**Via CocoaPods:** add `ArkanaKeys` and `ArkanaKeysInterfaces` (or the `pod_name` option that you passed in your config file) to your list of dependencies in your `Podfile` file, like this:

```ruby
pod "ArkanaKeys", path: "path/to/your/dependencies/ArkanaKeys"
pod "ArkanaKeysInterfaces", path: "path/to/your/dependencies/ArkanaKeysInterfaces"
```

After adding its dependency, you should be able to `import ArkanaKeys` (or the `import_name` option that you passed in your config file).

We recommend you to add your ArkanaKeys directory to your `.gitignore` since it's an auto-generated code that will change every time you run Arkana (since its salt gets generated on each run). For more information, see [How does it work?](#how-does-it-work)

## Continuous Integration

We advise you not to commit your `.env` files, because of security concerns. They should live in secure Environment Variables in your build (CI/CD) server instead.

Following the [template.yml](template.yml) example file, these would be the variables that would need to be added to your build server env vars:

- `FrootLoopsAppStoreAppID`
- `FrootLoopsBackendDomain`
- `FrootLoopsMySecretAPIKey`
- `FrootLoopsMyServiceAPIKeyDebug`
- `FrootLoopsMyServiceAPIKeyRelease`
- `FrostedFlakesAppStoreAppID`
- `FrostedFlakesBackendDomain`
- `FrostedFlakesMySecretAPIKey`
- `FrostedFlakesMyServiceAPIKeyDebug`
- `FrostedFlakesMyServiceAPIKeyRelease`

It's okay to commit your `.env` files if their potential exposure wouldn't be harmful to your project, for instance when Arkana is being used in a white label project to inject variables but that are not necessarily "secrets" (e.g. app tint color, server domain, etc). You can also use `.env` files to store part of your env vars (only the unsecure ones), and keep the secrets in your build server's env vars.

## Options

### `--help`

Will display a list of the available options.

### `--config-file-path`

Usage: `--config-file-path /path/to/your/.arkana.yml`

Indicates where your config file is located at.

Defaults to `.arkana.yml` in the current directory.

### `--dotenv-file-path`

Usage: `--dotenv-file-path /path/to/your/.env`

Indicates where your .env file is located at, if you have any to be loaded.

Defaults to `.env` in the current directory.

### `--flavor`

Usage: `--flavor loremipsum`

Passing a flavor option will change the env var lookup mechanism. Flavors are useful, for instance, when generating secrets for white-label projects.

#### Example

Let's load a flavor called `snowflakes` and load a secret called `MySecretAPIKey`:

Run `bundle exec arkana --flavor snowflakes`

This will change the env var lookup method, to this particular order:

1. Load any `.env` file, if present.
2. Load any `.env.snowflakes`, if present (it will override the keys of `.env` when they conflict)
3. Look up for a `SnowflakesMySecretAPIKey` env var. This could be present anywhere: both in the `.env` file, or in actual env vars (useful for CI environments).
4. If `SnowflakesMySecretAPIKey` didn't exist, look up for a `MySecretAPIKey` env var.
5. If ultimately it couldn't find any env var to populate the key `MySecretAPIKey`, it will throw a validation error.

This means that, if you are working with a white-label project, you can have all your env vars declared in a single `.env` file, or in multiple files like `.env.snowflakes`, `.env.frosties`, etc. This also means that your CI can be configured with the appropriate env vars e.g. `SnowflakesMySecretAPIKey`, `FrostiesMySecretAPIKey`, etc, with no necessity to manage (or git-version) dotenv files at all, which is the ideal way to manage secrets securely in a project.

# FAQ

## How does it work?

Arkana uses code generation to provide your app with its secrets. Secrets are fetched from env vars during Arkana runtime (not your app's runtime), their values are encoded using a salt that is generated on each run, and source code is generated using the provided keys, and the generated encoded values.

During your app's runtime, the encoded value is decoded so your app can use their raw values (the values that were originally stored in your env vars).

This encoding mechanism makes it difficult for attackers to simply just read your secrets in plain text from your app's binary (for instance by using unix [strings](https://man7.org/linux/man-pages/man1/strings.1.html), or other tools like [dumpdecrypted](https://github.com/stefanesser/dumpdecrypted)).

## Is this safe?

Key security is difficult. Right now even the biggest apps get their keys [leaked](https://threatpost.com/twitter-oauth-api-keys-leaked-030713/77597). This is neatly summed up by John Adams of the Twitter Security Team on [Quora](http://www.quora.com/Twitter-1/How-were-the-Twitter-iPhone-and-Android-OAuth-keys-leaked).

> Putting this in the context of, "should you be storing keys in software", is more appropriate. Many companies do this. It's never a good idea.

> When developers do that, other developers can use debuggers and string searching commands to extract those keys from the running application. There are numerous talks on how to do that, but leave that as an exercise to the reader to find those talks.

> Many people believe that obfuscating these keys in code will help. It usually won't because you can just run a debugger and find the fully functional keys.

So in summary, the ideal way to store keys is to not store keys. In reality though most Apps embed keys, and this does that and adds some rudimentary obfuscation to the keys. A well motivated app cracker could probably extract this within a few minutes however.

<sub>This excerpt has been copied in its entirety from https://github.com/orta/cocoapods-keys#security - 100% credit goes to @orta and its maintainers.</sub>

## Why not [`cocoapods-keys`](https://github.com/orta/cocoapods-keys)?

I decided to create this new gem because `cocoapods-keys` wasn't enough for all my (and other `cocoapods-keys` users') needs. The key differences between these two projects are:

- The code generation process generates a more modern interface and protocols, under a friendly and customizable namespace, with unit tests written in the output language, and modularized architecture.
- Flexibility: it's independent from CocoaPods. It's a CLI tool, which may or may not be used alongside CocoaPods, but also supports Swift Package Manager.
- Extensibility: can be extended to generate secrets for Android projects as well as iOS ones.
- Conciseness: built-in support for white-label projects and environment-specific secrets, properly making use of interfaces, and reducing amount of boilerplate configuration code to be written.

## Why not a CocoaPods Plugin?

Because plugins can only be hooked to Podfiles, and not Podspec files. Thus, if you have local CocoaPods and rely only on their podspec files to generate their content, but **_they_** are consuming the secrets, then you're out of luck. The strategy that Arkana uses requires a little bit more manual work (1 LOC), but it's more flexible, reaching more projects with different setups.

If your setup uses CocoaPods, you can add this snippet at the top of your Podfile that would work just like a CocoaPods Plugin:

```ruby
`bundle exec arkana --config-filepath /path/to/your/.arkana.yml --dotenv-filepath /path/to/your/.env`
```

<sub>Note: include the back-ticks above, they're required, so that Ruby interprets the snippet as a shell script.</sub>

By doing this, your Arkana code generation will be executed everytime you run `pod install` or `pod update`.

The only down side of using this strategy is that you wouldn't want to use it if you need to pass in (dynamic) flavors, since it would require you to modify the Podfile on every different flavor you need to build. If that's the case, you should run Arkana before running `pod install` in your build pipeline, and not use this snippet at all.

# References

**Did you know?**

The word arcanum (pluralized as "arcana", here spelled as "Arkana") came from Latin arcanus, meaning "secret", and entered English as the Dark Ages gave way to the Renaissance.[²](https://www.merriam-webster.com/dictionary/arcanum)

Special thanks to @danilobecke for the inspiration and heavy lifting, and to @orta for the creation of https://github.com/orta/cocoapods-keys which this project is based off of.

# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

# Contributing

If you spot something wrong, missing, or if you'd like to propose improvements to this project, please open an Issue or a Pull Request with your ideas and I promise to get back to you within 24 hours! 😇

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

For a list of issues worth tackling check out: https://github.com/rogerluan/arkana/issues

# License

This project is open source and covered by a standard 2-clause BSD license. That means you can use (publicly, commercially and privately), modify and distribute this project's content, as long as you mention **Roger Oba** as the original author of this code and reproduce the LICENSE text inside your app, repository, project or research paper.

# Contact

Twitter: [@rogerluan_](https://twitter.com/rogerluan_)
