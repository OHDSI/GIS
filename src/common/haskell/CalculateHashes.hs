{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
module CalculateHashes where

import System.Environment
import GHC.Generics

import qualified SourceFiles as S

import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy.Char8 as B
import qualified Data.Text as T
import qualified Data.Map as M

import System.Process
import System.Exit

calculateHash sourceFile = do
  (exitcode, stdout, stderr) <- readProcessWithExitCode
    ("nix-prefetch") ["(callPackage (import ./.) {}).\"" ++ (T.unpack $ S.name sourceFile) ++ "\""] ""
  return $
    case exitcode of
      _ -> S.updateHash sourceFile $ (T.strip . T.pack) stdout

main = do
  args <- getArgs
  x <- B.readFile $ head args
  sources <- A.decode <$> (B.readFile $ head args) :: IO (Maybe [S.SourceFile])
  case sources of
    Just a -> do
      sources <- mapM calculateHash a
      B.putStr $ S.show sources
  --B.putStrLn "["
  --case sources of
  --  Just a ->
  --    mapM ( \sourceFile -> do
  --      sourceFileWithHash <- calculateHash sourceFile
  --      B.putStr $ S.showSingle sourceFileWithHash
  --    ) a
  --B.putStr "]"
