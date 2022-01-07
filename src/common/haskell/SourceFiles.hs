{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
module SourceFiles where

import GHC.Generics

import qualified Data.Aeson as A
import qualified Data.Aeson.Encode.Pretty as P
import qualified Data.Text as T
import qualified Data.Map as M
import qualified Data.ByteString.Lazy as B

data SourceFile = SourceFile {
  name :: T.Text
, hash :: Maybe T.Text
, extraAttrs :: Maybe (M.Map T.Text A.Value)
} deriving (Generic, Show)

show :: [SourceFile] -> B.ByteString
show = P.encodePretty' P.Config {
  P.confIndent = P.Spaces 2
, P.confCompare = P.keyOrder [
    "name", "hash", "extraAttrs"
  , "pname", "version", "extent", "geom", "year", "url"
  ]
, P.confNumFormat = P.Generic
, P.confTrailingNewline = False
}

fromListText :: T.Text -> [(T.Text, T.Text)] -> SourceFile
fromListText name extraAttrs =
  SourceFile {
    name = name
  , hash = Nothing
  , extraAttrs = Just $ M.map A.String $ M.fromList extraAttrs
  }

instance A.ToJSON SourceFile
instance A.FromJSON SourceFile

--showSourceFile :: SourceFile -> [T.Text]
--showSourceFile SourceFile{name=n, url=u, extraAttrs=a} =
--  [ "\"" <> n <> "\": {"
--  , "  \"url\": \"" <> u <> "\""
--  , ", \"sha256\": \"0000000000000000000000000000000000000000000000000000000000000000\""
--  ]
--  ++
--  (map (\(k, v) -> ", \"" <> k <> "\": \"" <> v <> "\"") (M.toList a))
--  ++
--  [ "}" ]
--
--showSourceFiles :: [SourceFile] -> [T.Text]
--showSourceFiles sourceFiles =
--  [ "{" ]
--  ++
--  (map (\x -> "  " <> x) (showSourceFile (head sourceFiles)))
--  ++
--  (concatMap (\x -> [ ", " <> (head x) ] ++ (map (\y -> "  " <> y) (tail x)) ) (map showSourceFile (tail sourceFiles)))
--  ++
--  [ "}" ]
--
--print :: [SourceFile] -> IO ()
--print sourceFiles = do
--  putStr $ T.unpack $ T.unlines $ showSourceFiles sourceFiles
