---
date: 2020-10-08 08:31:40+0300
title: "Microsoft .NET"
---

## CSharp

### Game Development

- [Game Development with .NET](https://devblogs.microsoft.com/dotnet/game-development-with-net/) (article)
- [Available game engines](https://dotnet.microsoft.com/apps/games/engines?WT.mc_id=gamedev-blog-abhamed)

## FSharp

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
```

### Articles

- [Get started with F# with the .NET Core CLI](https://docs.microsoft.com/en-us/dotnet/fsharp/get-started/get-started-command-line)
- [F# Style Guide](https://docs.microsoft.com/en-us/dotnet/fsharp/style-guide/)
- [.NET Core application deployment](https://docs.microsoft.com/en-us/dotnet/core/deploying/)
- [paket generate-load-scripts](https://fsprojects.github.io/Paket/paket-generate-load-scripts.html)
- [An attempt at encoding GADTs](http://www.fssnip.net/mp/title/An-attempt-at-encoding-GADTs)

### Presentations

- [Don Syme - Keynote - F# Code I Love](https://www.youtube.com/watch?v=MGLxyyTF3OM)

### Templates

- [ProjectScaffold](https://github.com/fsprojects/ProjectScaffold): template for new projects
- [MiniScaffold](https://github.com/TheAngryByrd/MiniScaffold)

### Tools 

- [Forge](https://github.com/ionide/Forge/): for creating projects
- [Paket](https://fsprojects.github.io/Paket/): for Nuget dependencies management
- [FAKE](https://fake.build/): build management

### Libraries

- [Expecto](https://github.com/haf/expecto#installing): unit testing

### Samples

- [zerosharp](https://github.com/MichalStrehovsky/zerosharp): "demo of the potential of C# for systems programming with the .NET native ahead-of-time compilation technology"
