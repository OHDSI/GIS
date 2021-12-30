{-# LANGUAGE OverloadedStrings #-}
module Utils where

import qualified Data.Text as T
import qualified Data.Map as M

data SourceFile = SourceFile {
  name :: T.Text
, url :: T.Text
, extraAttrs :: M.Map T.Text T.Text
}

showSourceFile :: SourceFile -> [T.Text]
showSourceFile SourceFile{name=n, url=u, extraAttrs=a} =
  [ "\"" <> n <> "\": {"
  , "  \"url\": \"" <> u <> "\""
  , ", \"sha256\": \"0000000000000000000000000000000000000000000000000000000000000000\""
  ]
  ++
  (map (\(k, v) -> ", \"" <> k <> "\": \"" <> v <> "\"") (M.toList a))
  ++
  [ "}" ]

showSourceFiles :: [SourceFile] -> [T.Text]
showSourceFiles sourceFiles =
  [ "{" ]
  ++
  (map (\x -> "  " <> x) (showSourceFile (head sourceFiles)))
  ++
  (concatMap (\x -> [ ", " <> (head x) ] ++ (map (\y -> "  " <> y) (tail x)) ) (map showSourceFile (tail sourceFiles)))
  ++
  [ "}" ]

print :: [SourceFile] -> IO ()
print sourceFiles = do
  putStr $ T.unpack $ T.unlines $ showSourceFiles sourceFiles
