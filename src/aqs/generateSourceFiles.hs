{-# LANGUAGE OverloadedStrings #-}
module Main where

import qualified SourceFiles as S

import Network.HTTP.Simple
import Data.Text.Encoding (decodeUtf8)

import qualified Data.Text as T
import qualified Data.Map as M
import qualified Data.ByteString.Lazy.Char8 as B

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

  B.putStrLn $ S.show $
    map (\file ->
      S.fromListText
        (head $ T.splitOn "." file)
        [("url", "https://aqs.epa.gov/aqsweb/airdata/" <> file)
        ]
    )
    fileList
