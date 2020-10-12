---
tags:
  - Fun
  - Haskell
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
