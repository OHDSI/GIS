{-# LANGUAGE OverloadedStrings #-}
module Main where

import Regions as Regions
import Utils as Utils

import qualified Data.Text as T
import qualified Data.Map as M

main = Utils.showNixSourceFiles sources

sources =
  concatMap
    (\year ->
      nationSources year
      <> concatMap (stateSources year) us_states
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
        Utils.name =
          "TIGER_" <> s_year <> "_US_" <> geom,
        url =
          nationUrl geom,
        extraAttrs = M.fromList
          [ ("year", s_year)
          , ("region", "US")
          , ("geom", geom)
          ]
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
        (_, US_State{Regions.name=_, statefp="02"}) -> ["anrc"]
        (year ,US_State{Regions.name=_, statefp="72"}) | year >= 2020 -> ["subbarrio"]
        _ -> []
      <>
      case year of
        2020 -> ["tabblock20"]
        _ -> [];
    s_name = sanatize $ Regions.name state
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
        Utils.name = stateName geom,
        url = stateUrl geom,
        extraAttrs = M.fromList
          [ ("year", s_year)
          , ("region", s_name)
          , ("geom", geom)
          ]
      }
  in
    map stateSource state_geoms
