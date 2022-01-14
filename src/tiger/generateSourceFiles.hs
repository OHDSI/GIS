{-# LANGUAGE OverloadedStrings #-}
module Main where

import Regions as Regions
import qualified SourceFiles as S

import qualified Data.Text as T
import qualified Data.Map as M
import qualified Data.ByteString.Lazy.Char8 as B

main = B.putStrLn $ S.show sources

sources =
  concatMap
    (\year ->
      nationSources year
      <> concatMap (stateSources year) us_states
    )
    [2011..2021]

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
    s_decade = (T.take 1 (T.takeEnd 2 s_year)) <> "0"
    nationUrl :: T.Text -> T.Text
    nationUrl geom =
      "https://www2.census.gov/geo/tiger/TIGER"
      <> s_year <> "/"
      <> case (geom, year) of
           ("aitsn", year) | year <= 2014 -> "AITS"
           ("zcta5", year) | year >= 2020 -> "ZCTA5" <> s_decade
           _ -> (T.toUpper geom)
      <> "/"
      <> "tl_" <> s_year <> "_us_"
      <> case (geom, year) of
           ("zcta5", year) -> "zcta5" <> s_decade
           ("uac", year) -> "uac10"
           _ -> geom
      <> ".zip"
   in
    map (\geom ->
      S.fromListText
        ("us-" <> geom <> "-" <> s_year)
        [ ("url", nationUrl geom)
        , ("year", s_year)
        , ("extent", "US")
        , ("geom", geom)
        , ("pname", "us-" <> geom)
        , ("version", s_year)
        ]
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
        (_, US_State{Regions.name=_, statefp="02"}) -> ["anrc"]
        (year ,US_State{Regions.name=_, statefp="72"}) | year >= 2020 -> ["subbarrio"]
        _ -> []
    s_name = sanatize $ Regions.name state
    s_year = T.pack $ show year
    s_decade = (T.take 1 (T.takeEnd 2 s_year)) <> "0"
    stateName geom =
      (T.toLower s_name) <> "-" <> geom <> "-" <> s_year
    stateUrl geom =
      "https://www2.census.gov/geo/tiger/TIGER"
      <> s_year <> "/"
      <> case (geom, year) of
           ("tabblock", year) | year >= 2020 -> "TABBLOCK" <> s_decade
           _ -> (T.toUpper geom)
      <> "/"
      <> "tl_" <> s_year <> "_" <> (statefp state) <> "_"
      <> case (geom, year) of
           ("tabblock", year) | year >= 2014 -> "tabblock" <> s_decade
           _ -> geom
      <> ".zip"     
    stateSource :: T.Text -> S.SourceFile
    stateSource geom =
      S.fromListText
        (stateName geom)
        [ ("url", stateUrl geom)
        , ("year", s_year)
        , ("extent", s_name)
        , ("geom", geom)
        , ("pname", (T.toLower s_name) <> "-" <> geom)
        , ("version", s_year)
        ]
  in
    map stateSource state_geoms
