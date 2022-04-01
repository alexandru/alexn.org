---
title: "VSCode workplace recommended extensions"
feed_guid: /snippets/2021/08/29/vscode-recommended-extensions-vscode-extensions-json/
redirect_from:
  - /snippets/2021/08/29/vscode-recommended-extensions-vscode-extensions-json/
  - /snippets/2021/08/29/vscode-recommended-extensions-vscode-extensions-json.html
image: /assets/media/snippets/recommended-extensions.png
image_hide_in_post: true
tags:
  - Programming
  - Scala
  - Snippet
last_modified_at: 2022-04-01 19:14:15 +03:00
---

You can recommend the required [VSCode](https://code.visualstudio.com/){:target="_blank",rel="nofollow"} extensions per repository to your fellow programmers. This is what VSCode calls "[workspace recommended extensions](http://go.microsoft.com/fwlink/?LinkId=827846){:target="_blank"}".

For example, if your project is a [Scala](https://www.scala-lang.org/){:target="_blank"} project, maybe you want to recommend the extension for syntax highlighting, [Metals](https://scalameta.org/metals/), and others.

Add `.vscode/extensions.json` to your repository:

```javascript
// .vscode/extensions.json
{
  // See http://go.microsoft.com/fwlink/?LinkId=827846
  // for the documentation about the extensions.json format
  "recommendations": [
    // Scala IDE: https://scalameta.org/metals/
    "scalameta.metals",

    // This package is already included by Metals (above), but if people
    // don't like Metals, then at least recommend syntax highlighting
    "scala-lang.scala",

    // Scaladex search for software dependencies
    "baccata.scaladex-search",
  ]
}
```

On opening the workspace, VSCode will recognize the file and ask if you want to install the recommended extensions:

<figure>
  <img src="{% link assets/media/snippets/recommended-extensions.png %}" />
  <figcaption>VSCode asking you if you want to install the recommended extensions.</figcaption>
</figure>
