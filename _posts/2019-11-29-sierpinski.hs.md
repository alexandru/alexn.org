---
title: 'Haskell Snippet: Sierpinski Triangle'
feed_guid: /snippets/2019/11/29/sierpinski.hs/
redirect_from:
  - /snippets/2019/11/29/sierpinski.hs/
  - /snippets/2019/11/29/sierpinski.hs.html
last_modified_at: 2022-04-01 19:13:24 +03:00
tags:
  - Haskell
  - Snippet
image: /assets/media/snippets/haskell-sierpinski.png
image_hide_in_post: true
description: >
  A fun Haskell sample that draws a Sierpinski triangle via ASCII characters.
---

```haskell
#!/usr/bin/env stack
-- stack --resolver lts-14.14 script
import Data.Bits

main :: IO ()
main = mapM_ putStrLn lines
  where
    n = 32 :: Int
    line i =
      [ if i .&. j /= 0 then ' ' else '*'
      | j <- [0 .. n - 1] ]
    lines = [line i | i <- [0 .. n - 1]]
```

NOTE: the code isn't mine, but I don't remember from where I got it from.
