{-# LANGUAGE OverloadedStrings #-}
module Regions where

import qualified Data.Text as T

data US_State = US_State {
  name :: T.Text
, statefp :: T.Text
, usps :: T.Text
}

us_states =
  [ US_State {name="American Samoa"                              , statefp="60", usps="AS"}
  , US_State {name="Commonwealth of the Northern Mariana Islands", statefp="69", usps="MP"}
  , US_State {name="District of Columbia"                        , statefp="11", usps="DC"}
  , US_State {name="Guam"                                        , statefp="66", usps="GU"}
  , US_State {name="Puerto Rico"                                 , statefp="72", usps="PR"}
  , US_State {name="United States Virgin Islands"                , statefp="78", usps="VI"}
  , US_State {name="Alabama"                                     , statefp="01", usps="AL"}
  , US_State {name="Alaska"                                      , statefp="02", usps="AK"}
  , US_State {name="Arizona"                                     , statefp="04", usps="AZ"}
  , US_State {name="Arkansas"                                    , statefp="05", usps="AR"}
  , US_State {name="California"                                  , statefp="06", usps="CA"}
  , US_State {name="Colorado"                                    , statefp="08", usps="CO"}
  , US_State {name="Connecticut"                                 , statefp="09", usps="CT"}
  , US_State {name="Delaware"                                    , statefp="10", usps="DE"}
  , US_State {name="Florida"                                     , statefp="12", usps="FL"}
  , US_State {name="Georgia"                                     , statefp="13", usps="GA"}
  , US_State {name="Hawaii"                                      , statefp="15", usps="HI"}
  , US_State {name="Idaho"                                       , statefp="16", usps="ID"}
  , US_State {name="Illinois"                                    , statefp="17", usps="IL"}
  , US_State {name="Indiana"                                     , statefp="18", usps="IN"}
  , US_State {name="Iowa"                                        , statefp="19", usps="IA"}
  , US_State {name="Kansas"                                      , statefp="20", usps="KS"}
  , US_State {name="Kentucky"                                    , statefp="21", usps="KY"}
  , US_State {name="Louisiana"                                   , statefp="22", usps="LA"}
  , US_State {name="Maine"                                       , statefp="23", usps="ME"}
  , US_State {name="Maryland"                                    , statefp="24", usps="MD"}
  , US_State {name="Massachusetts"                               , statefp="25", usps="MA"}
  , US_State {name="Michigan"                                    , statefp="26", usps="MI"}
  , US_State {name="Minnesota"                                   , statefp="27", usps="MN"}
  , US_State {name="Mississippi"                                 , statefp="28", usps="MS"}
  , US_State {name="Missouri"                                    , statefp="29", usps="MO"}
  , US_State {name="Montana"                                     , statefp="30", usps="MT"}
  , US_State {name="Nebraska"                                    , statefp="31", usps="NE"}
  , US_State {name="Nevada"                                      , statefp="32", usps="NV"}
  , US_State {name="New Hampshire"                               , statefp="33", usps="NH"}
  , US_State {name="New Jersey"                                  , statefp="34", usps="NJ"}
  , US_State {name="New Mexico"                                  , statefp="35", usps="NM"}
  , US_State {name="New York"                                    , statefp="36", usps="NY"}
  , US_State {name="North Carolina"                              , statefp="37", usps="NC"}
  , US_State {name="North Dakota"                                , statefp="38", usps="ND"}
  , US_State {name="Ohio"                                        , statefp="39", usps="OH"}
  , US_State {name="Oklahoma"                                    , statefp="40", usps="OK"}
  , US_State {name="Oregon"                                      , statefp="41", usps="OR"}
  , US_State {name="Pennsylvania"                                , statefp="42", usps="PA"}
  , US_State {name="Rhode Island"                                , statefp="44", usps="RI"}
  , US_State {name="South Carolina"                              , statefp="45", usps="SC"}
  , US_State {name="South Dakota"                                , statefp="46", usps="SD"}
  , US_State {name="Tennessee"                                   , statefp="47", usps="TN"}
  , US_State {name="Texas"                                       , statefp="48", usps="TX"}
  , US_State {name="Utah"                                        , statefp="49", usps="UT"}
  , US_State {name="Vermont"                                     , statefp="50", usps="VT"}
  , US_State {name="Virginia"                                    , statefp="51", usps="VA"}
  , US_State {name="Washington"                                  , statefp="53", usps="WA"}
  , US_State {name="West Virginia"                               , statefp="54", usps="WV"}
  , US_State {name="Wisconsin"                                   , statefp="55", usps="WI"}
  , US_State {name="Wyoming"                                     , statefp="56", usps="WY"} ]
