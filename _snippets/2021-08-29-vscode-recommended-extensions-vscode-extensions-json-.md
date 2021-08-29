---
title: "VSCode workplace recommended extensions"
date: 2021-08-29 11:46:24+0300
image: /assets/media/snippets/recommended-extensions.png
tags:
  - IDE
  - Programming
  - Scala
---

You can recommend the required [VSCode](https://code.visualstudio.com/){:target="_blank",rel="nofollow"} extensions per repository to your fellow programmers. This is what VSCode calls "[workspace recommended extensions](http://go.microsoft.com/fwlink/?LinkId=827846){:target="_blank"}".

For example, if your project is a [Scala](https://www.scala-lang.org/){:target="_blank"} project, add this `$PROJECT_ROOT/.vscode/extensions.json` file to your repository:

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
  ]
}
```

On opening the workspace, VSCode will recognize the file and ask if you want the recommended extensions:

<figure>
  <img src="{% link assets/media/snippets/recommended-extensions.png %}" />
  <figcaption>VSCode asking you if you want to install the recommended extensions.</figcaption>
</figure>
