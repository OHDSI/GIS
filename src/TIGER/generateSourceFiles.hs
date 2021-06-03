{-# LANGUAGE OverloadedStrings #-}
module Main where

import States

import System.Process
import System.Exit
import qualified Data.Text as T

data SourceFile = SourceFile {
  name :: T.Text
, url :: T.Text
}

showNixSource :: SourceFile -> IO [T.Text]
showNixSource SourceFile{Main.name=n, url=u} = do
  (exitcode, stdout, stderr) <- readProcessWithExitCode ("nix-prefetch-url") ["--unpack", "--name", T.unpack n, T.unpack u] ""
  return
    [ n <> " = {"
    , "  url = \"" <> u <> "\";"
    , "  sha256 = \""
      <> case exitcode of
           ExitSuccess -> (T.strip $ T.pack stdout)
           _ -> "0000000000000000000000000000000000000000000000000000000000000000"
      <> "\";"
    , "};"
    ]

sources =
  concatMap
    (\year ->
      nationSources year
      <> concatMap (stateSources year) states
    )
    [2011..2020]

nationSources year =
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
      <>
      case year of
        year | year >= 2012 -> ["uac", "zcta5"]
        _ -> []
    s_year = T.pack $ show year
    nationUrl :: T.Text -> T.Text
    nationUrl geom =
      "https://www2.census.gov/geo/tiger/TIGER"
      <> s_year <> "/"
      <> case (geom, year) of
           ("aitsn", year) | year <= 2014 -> "AITS"
           _ -> (T.toUpper geom)
      <> "/"
      <> "tl_" <> s_year <> "_us_"
      <> case geom of
           geom | geom == "zcta5" || geom == "uac" -> geom <> "10"
           _ -> geom
      <> ".zip"
   in
    map (\geom ->
      SourceFile {
        Main.name =
          "TIGER_" <> s_year <> "_US_" <> geom,
        url =
          nationUrl geom
        }
      )
      nation_geoms

sanatize = T.replace " " "_"

stateSources year state = 
  let
    state_geoms :: [T.Text]
    state_geoms =
      [ "bg"
      , "cousub"
      , "tabblock"
      , "tract"
      ]
      <>
      case (year, state) of
        (_, State{States.name=_, statefp="02"}) -> ["anrc"]
        (year ,State{States.name=_, statefp="72"}) | year >= 2020 -> ["subbarrio"]
        _ -> []
      <>
      case year of
        2020 -> ["tabblock20"]
        _ -> [];
    s_name = sanatize $ States.name state
    s_year = T.pack $ show year
    stateName :: T.Text -> T.Text
    stateName geom =
      "TIGER_" <> s_year <> "_" <> s_name <> "_" <> geom
    stateUrl :: T.Text -> T.Text
    stateUrl geom =
      "https://www2.census.gov/geo/tiger/TIGER"
      <> s_year <> "/" <> (T.toUpper geom) <> "/"
      <> "tl_" <> s_year <> "_" <> (statefp state) <> "_"
      <> case (geom, year) of
           ("tabblock", year) | year >=2014 -> "tabblock10"
           _ -> geom
      <> ".zip"     
    stateSource :: T.Text -> SourceFile
    stateSource geom =
      SourceFile {
        Main.name = stateName geom,
        url = stateUrl geom
      }
  in
    map stateSource state_geoms

main = do
  putStrLn "# Do not modify manually, auto generated with `generateSourceFiles.hs`"
  putStrLn "{"
  mapM
    (\sourceFile -> do
      nixSource <- showNixSource sourceFile
      putStr $ T.unpack $ T.unlines $ map (\x -> "  " <> x) nixSource
    )
    sources
  putStrLn "}"
