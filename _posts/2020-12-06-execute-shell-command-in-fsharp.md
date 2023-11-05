---
title: "Execute shell commands in F#"
tags:
  - Shell
  - dotNet
  - FSharp
  - Snippet
feed_guid: /snippets/2020/12/06/execute-shell-command-in-fsharp/
redirect_from:
  - /snippets/2020/12/06/execute-shell-command-in-fsharp/
  - /snippets/2020/12/06/execute-shell-command-in-fsharp.html
image: /assets/media/snippets/execute-shell-command-fsharp.png
image_hide_in_post: true
description: >
  Snippet in plain F# with no dependencies. Features a neat shebang.
last_modified_at: 2023-11-05 19:26:44 +02:00
---

```fsharp
#!/usr/bin/env -S dotnet fsi

open System
open System.Diagnostics
open System.Threading.Tasks

type CommandResult =
  { ExitCode: int
    StandardOutput: string
    StandardError: string }

let executeCommand executable args =
  async {
    let! ct = Async.CancellationToken

    let startInfo = ProcessStartInfo()
    startInfo.FileName <- executable
    startInfo.RedirectStandardOutput <- true
    startInfo.RedirectStandardError <- true
    startInfo.UseShellExecute <- false
    startInfo.CreateNoWindow <- true
    for a in args do
      startInfo.ArgumentList.Add(a)

    use p = new Process()
    p.StartInfo <- startInfo
    p.Start() |> ignore

    let outTask =
      Task.WhenAll([|
        p.StandardOutput.ReadToEndAsync(ct);
        p.StandardError.ReadToEndAsync(ct) |])

    do! p.WaitForExitAsync(ct) |> Async.AwaitTask
    let! out = outTask |> Async.AwaitTask

    return
      { ExitCode = p.ExitCode
        StandardOutput = out.[0]
        StandardError = out.[1] }
  }

let executeShellCommand command =
  executeCommand "/usr/bin/env" [ "-S"; "bash"; "-c"; command ]

// Invocation sample
let r = executeShellCommand "ls -alh" |> Async.RunSynchronously

if r.ExitCode = 0 then
  printfn "%s" r.StandardOutput
else
  eprintfn "%s" r.StandardError
  Environment.Exit(r.ExitCode)
```

If you create the file `test.fsi` with the code above, under Linux you can make it executable:

```sh
# Make it executable
chmod +x ./test.fsi

# Execute it
./test.fsi
```

Also, see: [Execute Shell Commands in Java/Scala/Kotlin](./2022-10-03-execute-shell-commands-in-java-scala-kotlin.md).
