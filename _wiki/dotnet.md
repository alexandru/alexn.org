---
date: 2020-10-08 08:31:40 +03:00
last_modified_at: 2023-11-14 11:49:36 +02:00
---

# Microsoft .NET (dotNET)

## .NET Core

To build self-contained executables, add this in `.csproj`/`.fsproj`:

```xml
<PropertyGroup>
    <SelfContained>true</SelfContained>
    <PublishTrimmed>true</PublishTrimmed>
    <PublishSingleFile>true</PublishSingleFile>
</PropertyGroup>
```

For NativeAOT:

- [zerosharp](https://github.com/MichalStrehovsky/zerosharp): "demo of the potential of C# for systems programming with the .NET native ahead-of-time compilation technology";

### Libraries (General)

Database migrations:

- [DbUp](https://github.com/DbUp/DbUp);
- [Fluent Migrator](https://github.com/fluentmigrator/fluentmigrator).

## C# (CSharp)

### Game Development

- [Game Development with .NET](https://devblogs.microsoft.com/dotnet/game-development-with-net/) (article)
- [Available game engines](https://dotnet.microsoft.com/apps/games/engines?WT.mc_id=gamedev-blog-abhamed)

## F# (FSharp)

### Start New Project

```sh
# Starting a new solution
dotnet new sln -o AdventOfCode

# Start a console applicatin
cd AdventOfCode/
dotnet new console -lang "F#" -o App

# Add project to the solution
dotnet sln add App/App.fsproj

# Restore NuGet dependencies
dotnet restore

# Build the project
dotnet build

# Run the project
cd ./App
dotnet run

# Build for release
dotnet publish --configuration Release
```

### Articles

- [Get started with F# with the .NET Core CLI](https://docs.microsoft.com/en-us/dotnet/fsharp/get-started/get-started-command-line)
- [F# Style Guide](https://docs.microsoft.com/en-us/dotnet/fsharp/style-guide/)
- [.NET Core application deployment](https://docs.microsoft.com/en-us/dotnet/core/deploying/)
- [paket generate-load-scripts](https://fsprojects.github.io/Paket/paket-generate-load-scripts.html)
- [An attempt at encoding GADTs](http://www.fssnip.net/mp/title/An-attempt-at-encoding-GADTs)

Native AOT:

- [Native AOT deployment](https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/);
- [F# 7 release notes](https://devblogs.microsoft.com/dotnet/announcing-fsharp-7/#f-self-contained-deployments-native-aot);

### Presentations

- [Don Syme - Keynote - F# Code I Love](https://www.youtube.com/watch?v=MGLxyyTF3OM)

### Templates

- [ProjectScaffold](https://github.com/fsprojects/ProjectScaffold): template for new projects
- [MiniScaffold](https://github.com/TheAngryByrd/MiniScaffold)

### Tools (F#)

- [Forge](https://github.com/ionide/Forge/): for creating projects
- [Paket](https://fsprojects.github.io/Paket/): for Nuget dependencies management
- [FAKE](https://fake.build/): build management

### Libraries (F#)

Unit testing:

- [Expecto](https://github.com/haf/expecto#installing).

Database access:

- [EFCore Sharp](https://github.com/efcore/EFCore.FSharp): F# migrations (design-time) support for EF Core.
