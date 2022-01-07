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
      (\US_State{Regions.name=name} ->
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
    [2015..2019]

nationSources year =
  let
    s_year = T.pack $ show year
  in
  [
    S.fromListText
      ("us-bg-" <> s_year)
      [ ("url", "https://www.neighborhoodatlas.medicine.wisc.edu/adi-download")
      , ("year", s_year)
      , ("extent", "US")
      , ("geom", "bg")
      , ("pname", "us-bg")
      , ("version", s_year)
      , ("state-type", "blockgroup")
      , ("scale-group", "national")
      , ("version-group", (T.drop 2 s_year))
      , ("state-name", "AL")
      ]
  ]

sanatize = T.replace " " "_"

stateSources year state =
  let
    state_geoms :: [T.Text]
    state_geoms =
      [ "bg"
      , "zip+4"
      ]
    s_name = sanatize $ Regions.name state
    s_year = T.pack $ show year
    stateName geom =
      (T.toLower s_name) <> "-" <> geom <> "-" <> s_year
    stateSource geom =
      S.fromListText
        (stateName geom)
        [ ("url", "https://www.neighborhoodatlas.medicine.wisc.edu/adi-download")
        , ("year", s_year)
        , ("extent", s_name)
        , ("geom", geom)
        , ("pname", (T.toLower s_name) <> "-" <> geom)
        , ("version", s_year)
        , ("state-type",
            case geom of
              "bg" -> "blockgroup"
              "zip+4" -> "zipcode")
        , ("scale-group", "state")
        , ("version-group", (T.drop 2 s_year))
        , ("state-name", Regions.usps state)
        ]
  in
    map stateSource state_geoms
