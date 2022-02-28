{-# LANGUAGE OverloadedStrings #-}
module Main where

import Regions as Regions

import qualified SourceFiles as S
import qualified Data.Text as T
import qualified Data.Map as M
import qualified Data.ByteString.Lazy.Char8 as B

main = B.putStrLn $ S.show sources

sources =
  let
    states = filter
      (\US_State{Regions.name=name, statefp=_} ->
        name /= "American Samoa"
        && name /= "Commonwealth of the Northern Mariana Islands"
        && name /= "Guam"
        && name /= "United States Virgin Islands"
      )
      us_states
  in
  concatMap
    (\year ->
      nationSources year
      <> concatMap (stateSources year) states
    )
    [2014,2016..2018]

nationSources year =
  let
    nation_geoms =
      [ "county"
      , "tract"
      , "ttract"
      ]
    s_year = T.pack $ show year
    nationUrl :: T.Text -> T.Text
    nationUrl geom =
      "https://svi.cdc.gov/Documents/Data/"
      <> s_year <> "_SVI_Data/"
      <> case (geom, year) of
           ("ttract", _) -> "States/Tribal_Tracts"
           ("tract", _) -> "SVI" <> s_year <> "_US"
           ("county", year) | year == 2014 -> "SVI" <> s_year <> "_US_cnty"
           _ -> "SVI" <> s_year <> "_US_" <> geom
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
      [ "county"
      , "tract"
      ]
    s_name = sanatize $ Regions.name state
    u_name = T.replace " " "" $ Regions.name state
    s_year = T.pack $ show year
    stateName :: T.Text -> T.Text
    stateName geom =
      (T.toLower s_name) <> "-" <> geom <> "-" <> s_year
    stateUrl :: T.Text -> T.Text
    stateUrl geom =
      "https://svi.cdc.gov/Documents/Data/"
      <> s_year <> "_SVI_Data/"
      <> case (geom, year) of
           ("tract", _) -> "States/" <> u_name
           ("county", year) | year == 2014 -> "States_Counties/" <> u_name <> "_cnty"
           ("county", _) -> "States_Counties/" <> u_name <> "_county"
      <> ".zip"
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
