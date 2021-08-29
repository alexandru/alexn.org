---
title: "VSCode workplace recommended extensions"
date: 2021-08-29 11:46:24+0300
image: /assets/media/snippets/recommended-extensions.png
tags:
  - IDE
  - Programming
---

You can recommend the required [VS Code](https://code.visualstudio.com/){:target="_blank",rel="nofollow"} extensions per repository to your fellow programmers. This is what VS Code calls "[workspace recommended extensions](http://go.microsoft.com/fwlink/?LinkId=827846){:target="_blank"}".

For example, if your project is a [Scala](https://www.scala-lang.org/){:target="_blank"} project,add this `$PROJECT_ROOT/.vscode/extensions.json` file to your repository:

```javascript
{
  // See http://go.microsoft.com/fwlink/?LinkId=827846
  // for the documentation about the extensions.json format
  "recommendations": [
    // Scala language syntax
    "scala-lang.scala",

    // Scala IDE: https://scalameta.org/metals/
    "scalameta.metals",
  ]
}
```

On opening the workspace, VS Code will recognize the file and ask if you want the recommended extensions:

<figure>
  <img src="{% link assets/media/snippets/recommended-extensions.png %}" />
  <figcaption>Screenshot of VS Code asking you if you want to install the recommended extensions.</figcaption>
</figure>
