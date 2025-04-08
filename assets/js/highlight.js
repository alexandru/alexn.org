---
layout: null
---
import hljs from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/core.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";

import bash from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/bash.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import csharp from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/csharp.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import fsharp from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/fsharp.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import haskell from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/haskell.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import ini from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/ini.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import java from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/java.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import javascript from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/javascript.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import json from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/json.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import kotlin from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/kotlin.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import ocaml from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/ocaml.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import perl from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/perl.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import python from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/python.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import ruby from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/ruby.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import scala from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/scala.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import sql from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/sql.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import typescript from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/typescript.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import xml from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/xml.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";
import yaml from "{% link /assets/js-managed/@highlightjs/cdn-assets/es/languages/yaml.min.js %}?{{ 'now' | date: '%Y%m%d%H%M' }}";

hljs.registerLanguage("bash", bash);
hljs.registerLanguage("csharp", csharp);
hljs.registerLanguage("fsharp", fsharp);
hljs.registerLanguage("haskell", haskell);
hljs.registerLanguage("ini", ini);
hljs.registerLanguage("java", java);
hljs.registerLanguage("javascript", javascript);
hljs.registerLanguage("js", javascript);
hljs.registerLanguage("json", java);
hljs.registerLanguage("json", json);
hljs.registerLanguage("kotlin", kotlin);
hljs.registerLanguage("ocaml", ocaml);
hljs.registerLanguage("perl", perl);
hljs.registerLanguage("python", python);
hljs.registerLanguage("py", python);
hljs.registerLanguage("ruby", ruby);
hljs.registerLanguage("scala", scala);
hljs.registerLanguage("sh", bash);
hljs.registerLanguage("sql", sql);
hljs.registerLanguage("ts", typescript);
hljs.registerLanguage("typescript", typescript);
hljs.registerLanguage("xml", xml);
hljs.registerLanguage("yaml", yaml);

hljs.highlightAll();