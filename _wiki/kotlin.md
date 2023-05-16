---
date: 2023-04-30 16:07:39 +03:00
last_modified_at: 2023-05-16 14:46:16 +03:00
---

# Kotlin

## Resources

Kotlin-specific:

- [Arrow](https://arrow-kt.io/learn/): Functional companion to Kotlin's Standard Library;
- [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization): Kotlin multiplatform / multi-format serialization;
- [Ktor](https://ktor.io/): HTTP client/server library;
- [SQLDelight](https://github.com/cashapp/sqldelight): Generates type-safe Kotlin APIs from SQL;
- [kotlinx-gettext](https://github.com/kropp/kotlinx-gettext/tree/main): I18N library;

Kotlin/JS:

- [kotlin-wrappers](https://github.com/JetBrains/kotlin-wrappers/): wrappers for popular JavaScript libraries;
- [kvision](https://kvision.io/): web UI framework for Kotlin, alternative to React;
  - [kvision-io (GitHub)](https://github.com/rjaros/kvision-io/): source code for a presentation website built in Kotlin, useful sample of a [Webpack](https://webpack.js.org/) configuration that integrates [Sass](https://en.wikipedia.org/wiki/Sass_(style_sheet_language)) and [Bulma](https://bulma.io/);

Samples:

- [Uncancelable, like in Cats-Effect](https://gist.github.com/alexandru/7527f83da03a32dbb46c281e95429ed6);
  - Using [UncancellableRegion](https://github.com/nomisRev/arrow-fx-coroutines-utils/blob/main/src/commonMain/kotlin/io/github/nomisrev/UncancellableRegion.kt);

## Kotlin/JS — FAQ

### Integrate SASS/CSS files in the Webpack build

Declare a `require` function:

```kotlin
@JsName("require")
external fun jsRequire(name: String): dynamic
```

Declare dependencies in `build.gradle.kts`:

```kotlin
implementation(devNpm("sass", "^1.62.1"))
implementation(devNpm("sass-loader", "^13.2.2"))
```

For configuring Webpack, create a file `webpack.config.d/css.js`:

```js
config.module.rules.push({
    test: /\.css$/,
    use: [
        "style-loader",
        {
            loader: "css-loader",
            options: {sourceMap: false}
        }
    ]
});
```

And another file at `webpack.config.d/sass.js`:

```js
config.module.rules.push({
    test: /\.s[ac]ss$/,
    use: [
        "style-loader",
        {
            loader: "css-loader",
            options: {sourceMap: false}
        },
        "sass-loader"
    ]
});
```

We can also declare external dependencies on CSS frameworks, such as [Bulma](https://bulma.io/):

```js
implementation(npm("bulma", "^0.9.4"))
```

Create `src/main/resources/sass/main.scss`:

```scss
@import '~bulma/bulma';

html {
  background-color: antiquewhite;
}
```

Then in `src/main/kotlin/main.kt`:

```kotlin
fun main() {
    jsRequire("./sass/main.scss")
}
```

Reference: [Slack conversation](https://kotlinlang.slack.com/archives/C0B8L3U69/p1684137369719519).

### Custom HTML attributes in the kotlin-react DSL

When using the React DSL from [kotlin-wrappers](https://github.com/JetBrains/kotlin-wrappers/):

```kotlin
import react.dom.html.AnchorHTMLAttributes
import react.dom.html.HTMLAttributes

operator fun HTMLAttributes<*>.get(key: String): String? =
    asDynamic()[key]

operator fun HTMLAttributes<*>.set(key: String, value: String?) {
    if (value == null)
        asDynamic().removeAttribute(key)
    else
        asDynamic()[key] = value
}

var AnchorHTMLAttributes<*>.dataTarget: String?
    get() = this["data-target"]
    set(value) { this["data-target"] = value }

//...
import react.dom.html.ReactHTML as html

html.a {
    dataTarget = "siteNavBar"
    //...
}
```

Reference: [kotlin-wrappers#1788](https://github.com/JetBrains/kotlin-wrappers/issues/1788).
