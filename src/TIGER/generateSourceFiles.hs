module Main where

import States

import System.Process
import Control.Monad.Extra (concatMapM)
import Data.Char (toUpper)

data SourceFile = SourceFile {
  name :: String
, url :: String
, sha256 :: String
}

nixSourceFiles :: [SourceFile] -> [String]
nixSourceFiles sourceFiles =
  concatMap nixSourceFile sourceFiles

nixSourceFile SourceFile{Main.name=n, url=u, sha256=s} =
  [ n ++ " = {"
  , "  url = \"" ++ u ++ "\";"
  , "  sha256 = \"" ++ s ++ "\";"
  , "};"
  ]

getSources :: Int -> IO [SourceFile]
getSources year = do
  nationSources <- getNationSources year
  stateSources <- concatMapM (getStateSources year) states
  return stateSources

getNationSources year =
  let
    nation_geoms = 
      [ "aiannh"
      , "aitsn"
      , "cbsa"
      , "csa"
      , "county"
      , "metdiv"
      , "state"
      , "tbg"
      , "ttract"
      ]
      ++
      case year of
        year | year > 2011 -> ["zcta5"]
        _ -> []
   in
    mapM (\geom ->
      getZipSource
        ( "TIGER_" ++ (show year) ++ "_US_" ++ geom )
        ( "https://www2.census.gov/geo/tiger/TIGER"
          ++ (show year) ++ "/"
          ++ case (geom, year) of
               ("aitsn", year) | year <= 2014 -> "AITS"
               _ -> (map toUpper geom)
          ++ "/"
          ++ "tl_" ++ (show year) ++ "_us_"
          ++ case geom of
               "zcta5" -> "zcta510"
               _ -> geom
          ++ ".zip" )
      )
      nation_geoms

sanatize :: Char -> Char
sanatize ' ' = '_'
sanatize c = c

getStateSources year state = 
  let
    state_geoms =
      [ "bg"
      , "cousub"
      , "tabblock"
      , "tract"
      ]
      ++
      case state of
        State{States.name=_, statefp="02"} -> ["anrc"]
        State{States.name=_, statefp="72"} -> ["subbarrio"]
        _ -> []
      ++ case year of
        2020 -> ["tabblock20"]
        _ -> []
    s_name = map sanatize (States.name state)
  in
    mapM (\geom ->
      getZipSource
        ( "TIGER_" ++ (show year) ++ "_" ++ s_name ++ "_" ++ geom )
        ( "https://www2.census.gov/geo/tiger/TIGER"
          ++ (show year) ++ "/" ++ (map toUpper geom) ++ "/"
          ++ "tl_" ++ (show year) ++ "_" ++ (statefp state) ++ "_"
          ++ case geom of
               "tabblock" -> "tabblock10"
               _ -> geom
          ++ ".zip"
        )
      )
      state_geoms

getZipSource n u = do
  s <- readProcess ("nix-prefetch-url") ["--unpack", "--name", n, u] ""
  return $ SourceFile {Main.name = n, url = u, sha256 = s}

indent strings =
  map (\string -> "  " ++ string) strings

main = do
  sources <- concatMapM getSources [2011..2020]
  putStrLn "# Do not modify manually, auto generated with `generateSourceFiles.hs`"
  putStrLn "{"
  putStr $ unlines $ indent $ nixSourceFiles sources
  putStrLn "}"
