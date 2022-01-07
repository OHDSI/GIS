{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
module CalculateHashes where

import System.Environment
import GHC.Generics

import qualified SourceFiles as S

import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as B
import qualified Data.Text as T
import qualified Data.Map as M

--toKeysList = toListOf $ members . asIndex

main = do
  args <- getArgs
  x <- B.readFile $ head args
  sources <- A.decode <$> (B.readFile $ head args) :: IO (Maybe [S.SourceFile])
  print $ sources
  --print $ (A.decode "{\"name\":\"hi\",\"hash\":\"me\",\"optionalAttrs\":{}}" :: Maybe S.SourceFile)
  --print $ (A.encode (S.SourceFile {S.name = "xx", S.hash = Just "bb", S.optionalAttrs = Nothing}))
