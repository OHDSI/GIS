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

showSingle :: SourceFile -> B.ByteString
showSingle = P.encodePretty' P.Config {
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

updateHash sourceFile h =
  SourceFile {
    name = name sourceFile
  , hash = Just h
  , extraAttrs = extraAttrs sourceFile
  }

instance A.ToJSON SourceFile
instance A.FromJSON SourceFile
