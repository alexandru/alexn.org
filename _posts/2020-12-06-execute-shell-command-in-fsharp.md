---
title: "Execute shell commands in F#"
tags:
  - Bash
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
last_modified_at: 2022-04-01 16:17:48 +03:00
---
  
```fsharp
#!/usr/bin/env -S dotnet fsi

open System
open System.Diagnostics
open System.Threading.Tasks

type CommandResult = { 
  ExitCode: int; 
  StandardOutput: string;
  StandardError: string 
}

let executeCommand executable args =
  async {
    let startInfo = ProcessStartInfo()
    startInfo.FileName <- executable
    for a in args do
      startInfo.ArgumentList.Add(a)
    startInfo.RedirectStandardOutput <- true
    startInfo.RedirectStandardError <- true
    startInfo.UseShellExecute <- false
    startInfo.CreateNoWindow <- true
    use p = new Process()
    p.StartInfo <- startInfo
    p.Start() |> ignore

    let outTask = Task.WhenAll([|
      p.StandardOutput.ReadToEndAsync();
      p.StandardError.ReadToEndAsync()
    |])

    do! p.WaitForExitAsync() |> Async.AwaitTask
    let! out = outTask |> Async.AwaitTask
    return {
      ExitCode = p.ExitCode;
      StandardOutput = out.[0];
      StandardError = out.[1]
    }
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
