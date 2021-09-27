{-# LANGUAGE OverloadedStrings #-}
module Main where

import Utils as Utils

import Network.HTTP.Simple
import Data.Text.Encoding (decodeUtf8)

import qualified Data.Text as T
import qualified Data.Map as M

getFileList = do
  response <- httpBS "https://aqs.epa.gov/aqsweb/airdata/file_list.csv"
  return $
    filter (not . T.null) $
    map (T.strip . head . T.splitOn ",") $
    tail $ T.splitOn "\n" $
    decodeUtf8 $ getResponseBody response

main :: IO ()
main = do
  fileList <- getFileList

  Utils.showNixSourceFiles $
    map (\file ->
      SourceFile {
        Utils.name = head $ T.splitOn "." file,
        url = "https://aqs.epa.gov/aqsweb/airdata/" <> file,
        extraAttrs = M.empty
      }
    )
    fileList
