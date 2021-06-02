module States where

data State = State {
  name :: String
, statefp :: String
}

states =
  [ State {name="American Samoa"                              , statefp="60"}
  , State {name="Commonwealth of the Northern Mariana Islands", statefp="69"}
  , State {name="District of Columbia"                        , statefp="11"}
  , State {name="Guam"                                        , statefp="66"}
  , State {name="Puerto Rico"                                 , statefp="72"}
  , State {name="United States Virgin Islands"                , statefp="78"}
  , State {name="Alabama"                                     , statefp="01"}
  , State {name="Alaska"                                      , statefp="02"}
  , State {name="Arizona"                                     , statefp="04"}
  , State {name="Arkansas"                                    , statefp="05"}
  , State {name="California"                                  , statefp="06"}
  , State {name="Colorado"                                    , statefp="08"}
  , State {name="Connecticut"                                 , statefp="09"}
  , State {name="Delaware"                                    , statefp="10"}
  , State {name="Florida"                                     , statefp="12"}
  , State {name="Georgia"                                     , statefp="13"}
  , State {name="Hawaii"                                      , statefp="15"}
  , State {name="Idaho"                                       , statefp="16"}
  , State {name="Illinois"                                    , statefp="17"}
  , State {name="Indiana"                                     , statefp="18"}
  , State {name="Iowa"                                        , statefp="19"}
  , State {name="Kansas"                                      , statefp="20"}
  , State {name="Kentucky"                                    , statefp="21"}
  , State {name="Louisiana"                                   , statefp="22"}
  , State {name="Maine"                                       , statefp="23"}
  , State {name="Maryland"                                    , statefp="24"}
  , State {name="Massachusetts"                               , statefp="25"}
  , State {name="Michigan"                                    , statefp="26"}
  , State {name="Minnesota"                                   , statefp="27"}
  , State {name="Mississippi"                                 , statefp="28"}
  , State {name="Missouri"                                    , statefp="29"}
  , State {name="Montana"                                     , statefp="30"}
  , State {name="Nebraska"                                    , statefp="31"}
  , State {name="Nevada"                                      , statefp="32"}
  , State {name="New Hampshire"                               , statefp="33"}
  , State {name="New Jersey"                                  , statefp="34"}
  , State {name="New Mexico"                                  , statefp="35"}
  , State {name="New York"                                    , statefp="36"}
  , State {name="North Carolina"                              , statefp="37"}
  , State {name="North Dakota"                                , statefp="38"}
  , State {name="Ohio"                                        , statefp="39"}
  , State {name="Oklahoma"                                    , statefp="40"}
  , State {name="Oregon"                                      , statefp="41"}
  , State {name="Pennsylvania"                                , statefp="42"}
  , State {name="Rhode Island"                                , statefp="44"}
  , State {name="South Carolina"                              , statefp="45"}
  , State {name="South Dakota"                                , statefp="46"}
  , State {name="Tennessee"                                   , statefp="47"}
  , State {name="Texas"                                       , statefp="48"}
  , State {name="Utah"                                        , statefp="49"}
  , State {name="Vermont"                                     , statefp="50"}
  , State {name="Virginia"                                    , statefp="51"}
  , State {name="Washington"                                  , statefp="53"}
  , State {name="West Virginia"                               , statefp="54"}
  , State {name="Wisconsin"                                   , statefp="55"}
  , State {name="Wyoming"                                     , statefp="56"} ]
