extensions [gis]
;;NOTE: INITIALIZE HOUR AND DAY AS 0 in Setup
;;NOTE; Counter taken from Canvas and provided by Todd Swannack
;;NOTE: schooling behavior is adopted from existing model "Fish Schooling For Predator Avoidance" by Sebastian Dobon
__includes["nls/altmove.nls"
  "nls/prototypesetup.nls"
  "nls/Completed-Migration.nls"
  "nls/calendar.nls"
  "nls/Create-map.nls"
  "nls/CreateSpecies.nls"
  "nls/Schooling.nls"
  "nls/Align.nls"
  "nls/Separate.nls"
  "nls/Cohere.nls"
  "nls/Adjust-alewife-speed.nls"
  "nls/Find-Schoolmates.nls"
  "nls/Find-nearest-neighbor.nls"
  "nls/flee-stripedbass.nls"
  "nls/Eat.nls"
  "nls/Chase-nearest-alewife.nls"
  "nls/Scare-down.nls"
  "nls/Scare-left.nls"
  "nls/Scare-right.nls"
  "nls/Scare-prey.nls"
  "nls/Move-adults-based-on-month.nls"
  "nls/Wander.nls"
  "nls/Adjust-stripedbass-speed.nls"
  "nls/Create-salinity.nls"
  "nls/Migrate-alewives-in.nls"
  "nls/Migrate-alewives-out.nls"
  "nls/Kill-fish-seasonally.nls"
  "nls/Count-prey-eaten.nls"
  "nls/spawning-encounters.nls"
  "nls/move-in-channel.nls"
  "nls/variablenames.nls"
  "nls/reporters.nls"
  "nls/upstream-migration-duration.nls"
  "nls/Mercury-transfer.nls"]

to setup
  clear-all ; reset variables
  set minute 0  ;; Initialize the minute variable as 0
  set hour 0  ;; Initialize the hour variable as 0
  set day 110 ;; Initialize the day variable as 0
  set month "April" ;; Initialize the month variable as 0
  set monthnum 4 ;; Initialize the monthnum variable as 0
  set adult-alewife-population 0 ;; initialize population count
  set mean-spawning-encounters 0 ;; initialize mean spawning encounters
  set mean-daytime-prey-eaten 0 ;; Initialize the prey eaten variable as 0
  set alewives-through-herring-run 0 ;; Initialize the alewife herring run count as 0
  set mean-habitat-quality 0 ;; Initialize the mean habitat quality variable as 0
  set successfull-migration-to-spawning-ground 0 ;; Initialize alewife count
  ;if model-type = "Aquinnah" [setup-GIS] ;; runs setup procedure for regular model and creates simulation environment

  if model-type = "prototype" [setup-GIS] ;; runs setup procedure for prototype model in "nls/prototypesetup.nls"

  ;if model-type = "Penobscot" [penobscot-setup] ;; runs setup procedure for prototype model in "nls/prototypesetup.nls"

  set-default-shape turtles "fish" ;change default shape to fish
  let min-spawning-habitat-quality min [spawning-habitat-quality] of patches ;define min spawning HSI
  let max-spawning-habitat-quality max [spawning-habitat-quality] of patches ;define max of spawning HSI

  ;    ask patches
  ;    [
  ;      set pcolor scale-color blue spawning-habitat-quality min-spawning-habitat-quality max-spawning-habitat-quality ;assign color gradient to HSI data
  ;    ]

  ;find-herring-run-entrance
  setup-stripedbass
  setup-alewives
  create-salinity ;;add salinity if needed
  if model-type = "prototype" [prototype-parameters]   ;moves all striped bass to the lower half of grid

  ;; summary statistics
  ;open output file
;  if (file-exists? "output/AlewifeMigration_ModSummary.csv")
;  [
;    carefully
;    [file-delete "output/AlewifeMigration_ModSummary.csv"]
;    [print error-message]
;  ]
;    file-open "output/AlewifeMigration_ModSummary.csv"
;    file-type "ticks,"
;    file-type "month,"
;    file-type "day,"
;    file-type "hour,"
;    file-type "minute,"
;    file-type "mean prey eaten,"
;    file-type "mean spawning encounters,"
;    file-type "mean-daily-spawning-encounters,"
;    file-type "alewife population,"
;    file-type "alewives in Herring Run,"
;    file-type "mean habitat quality,"
;    file-print "alewives eaten"
;    file-close

  reset-ticks ; Reset the tick counter
end

to go
  ask alewives with [age = "adult"] [
    count-exposure-duration;; count exposure to methylmercury
    uptake-methylmercury;; bioaccumulation
    school ;; school function in "nls/Schooling.nls"
    move-adults-based-on-month ;; migration function in "nls/Move-adults-based-on-month.nls"
    flee-stripedbass ;; if fleeing use energy
    track-time-of-upstream-migration ;; track duration of upstream migration
    disappear-if-reached-spawning-grounds;; remove alewives from system
    ;count-spawning-encounters ;; count spawning encounters for individual alewives
    ;reset-daytime-spawning-encounters ;; reset daily spawning encounters
    ;count-time-since-spawning-encounters ;; count time since last spawning encounter
    ;ifelse model-type = "regular_model"
    ;[school] ;perform adult alewife migratory movement
    eliminate-methylmercury;; remove methylmercury
  ]
  if count alewives = 0 [
    stop
  ]
  count-alewives-in-herring-run ;; count alewives in herring run
  count-mean-duration-upstream-migration;; migration duration
  ;count-mean-spawning-encounters ;; calculate the mean number of spawning encounters
  ;highlight-patches-with-spawning-encounters ;; highlight patches with spawning encounters
  ;count-mean-habitat-quality ;; record mean habitat quality of patches with spawning encounters
  count-mean-b-methylmercury-prey ;; record mean bioaccumulated methylmercury
  count-mean-exposure-duration-prey ;; record mean duration of exposure to contamination
  count-mean-daily-bioaccumulation-alewives;; daily rate of bioaccumulation

  ask stripedbass [
    count-exposure-duration;; count exposure to methylmercury
    uptake-methylmercury;; bioaccumulation
    set prey-in-vision alewives in-radius stripedbass-vision ;; defines alewives in vision radius

    ifelse any? prey-in-vision
    [ chase-nearest-alewife ]  ;; point towards nearest prey in "nls/Chase-nearest-alewife.nls"
    [ wander ] ;; wander if no prey in sight in "nls/Wander.nls"

    adjust-stripedbass-speed  ;; predator will speed up when making an attack
    scare-prey  ;; prey fleeing starts at predator because of control flow (scare-right, scare-left)
    eat ;; eat prey if within neighbors in "nls/Eat.nls"
    reset-daytime-prey-eaten ;; limit daily prey eaten
    count-time-since-full ;; fish rests when full
    eliminate-methylmercury;; remove methylmercury
  ]

  highlight-patches-with-prey-eaten ;; highlights patches where prey has been eaten
  count-mean-daytime-prey-eaten ;; count mean daily prey eaten
  count-mean-b-methylmercury-predator ;; record mean bioaccumulated methylmercury
  count-mean-exposure-duration-predator ;; record mean duration of exposure to contamination
  count-mean-daily-bioaccumulation-stripedbass;; daily rate of bioaccumulation
  report-alewife-population ;; records prey population
  ;save-summary-stats
  ;save-world-attributes
  calendar ;; Call the calendar procedure to update hour, day, and month
  ;; Stop procedure
  tick ; Increment the tick counter
end

;to save-summary-stats
;  ; write summary statistics to output file
;  file-open "output/AlewifeMigration_ModSummary.csv"
;  file-type (word ticks ",")
;  file-type (word monthnum ",")
;  file-type (word day ",")
;  file-type (word hour ",")
;  file-type (word minute ",")
;  file-type (word mean-daytime-prey-eaten ",")
;  file-type (word mean-spawning-encounters ",")
;  file-type (word mean-daily-spawning-encounters ",")
;  file-type (word adult-alewife-population ",")
;  file-type (word alewives-through-herring-run ",")
;  file-type (word mean-habitat-quality ",")
;  file-print numAlewivesEaten
;  file-close
;end

to save-world-attributes
;export-world user-new-file
export-world (word "output/patch_attributes " random-float 1.0 ".csv")
export-view (word "output/patch_attributes " random-float 1.0 ".png")
end
@#$#@#$#@
GRAPHICS-WINDOW
213
10
322
520
-1
-1
1.0
1
10
1
1
1
0
0
0
1
0
100
0
500
0
0
1
ticks
30.0

BUTTON
5
60
68
93
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
74
60
137
93
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
939
50
1136
83
initial_stripedbass
initial_stripedbass
0
100
10.0
1
1
predators
HORIZONTAL

SLIDER
514
51
686
84
initial_alewives
initial_alewives
0
500
500.0
5
1
prey
HORIZONTAL

SLIDER
510
256
722
289
max-alewife-speed
max-alewife-speed
0
10
4.0
.1
1
patches/tick
HORIZONTAL

SLIDER
511
294
721
327
min-alewife-speed
min-alewife-speed
0
3
1.0
.1
1
patches/tick
HORIZONTAL

SLIDER
511
333
683
366
alewife-vision
alewife-vision
0
30
15.0
1
1
patches
HORIZONTAL

SLIDER
932
155
1113
188
stripedbass-vision
stripedbass-vision
0
30
15.0
1
1
patches
HORIZONTAL

SLIDER
932
420
1164
453
min-stripedbass-speed
min-stripedbass-speed
0
2
1.0
.1
1
patches/tick
HORIZONTAL

SLIDER
932
381
1166
414
max-stripedbass-speed
max-stripedbass-speed
0
3
3.0
.1
1
patches/tick
HORIZONTAL

SLIDER
932
302
1178
335
predator-burst-energy
predator-burst-energy
0
10
4.0
1
1
Units of Energy
HORIZONTAL

SLIDER
932
341
1231
374
burst-recharge-time
burst-recharge-time
0
960
960.0
1
1
ticks (1 tick = 1.5 minutes)
HORIZONTAL

SLIDER
509
473
713
506
minimum-separation
minimum-separation
0
20
0.5
.1
1
patches
HORIZONTAL

SLIDER
510
512
682
545
align-coefficient
align-coefficient
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
510
590
682
623
separate-coefficient
separate-coefficient
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
931
194
1124
227
predator-turn-coefficient
predator-turn-coefficient
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
511
372
730
405
prey-flee-energy
prey-flee-energy
0
10
4.0
1
1
Units of Energy
HORIZONTAL

SLIDER
510
551
682
584
cohere-coefficient
cohere-coefficient
0
100
50.0
1
1
%
HORIZONTAL

CHOOSER
5
10
143
55
Model-type
Model-type
"prototype" "Aquinnah" "Penobscot"
0

MONITOR
79
147
136
192
Day
Day
17
1
11

MONITOR
4
146
75
191
NIL
monthnum
17
1
11

SLIDER
501
656
766
689
limit-alewife-spawning-encounters
limit-alewife-spawning-encounters
1
5
1.0
1
1
per year
HORIZONTAL

BUTTON
141
60
204
93
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
931
234
1201
267
limit-daily-prey-allowance
limit-daily-prey-allowance
0
10
4.0
1
1
alewives per day
HORIZONTAL

SLIDER
510
152
760
185
migration-start-day
migration-start-day
60
152
112.0
1
1
th day of the year
HORIZONTAL

SLIDER
500
695
849
728
rest-between-spawning
rest-between-spawning
0
1600
960.0
1
1
(960 ticks = 1 day)
HORIZONTAL

TEXTBOX
942
12
1152
39
Predator Parameters
18
0.0
1

TEXTBOX
628
13
778
44
Prey Parameters
18
0.0
1

SLIDER
511
190
683
223
migration-end-month
migration-end-month
6
12
8.0
1
1
NIL
HORIZONTAL

TEXTBOX
516
130
666
148
Migration
12
0.0
1

TEXTBOX
515
234
665
252
Predator Avoidance
12
0.0
1

TEXTBOX
514
449
664
467
Schooling
12
0.0
1

TEXTBOX
514
633
664
651
Spawning
12
0.0
1

TEXTBOX
934
134
1084
152
Eating
12
0.0
1

TEXTBOX
934
279
1084
297
Bursting
12
0.0
1

SLIDER
931
559
1135
592
trophic-transfer-rate
trophic-transfer-rate
0
1
0.121
0.001
1
mg/kg
HORIZONTAL

SLIDER
939
89
1111
122
predator-size
predator-size
0
10
9.0
1
1
NIL
HORIZONTAL

SLIDER
514
90
686
123
prey-size
prey-size
0
5
3.0
0.5
1
NIL
HORIZONTAL

SLIDER
932
484
1141
517
uptake-Constant
uptake-Constant
0
1
0.006
0.0001
1
mg/kg/tick
HORIZONTAL

SLIDER
931
521
1160
554
elimination-constant
elimination-constant
0
1
1.0E-4
0.0001
1
mg/kg/tick
HORIZONTAL

TEXTBOX
933
462
1131
480
Contamination Exposure
12
0.0
1

SLIDER
1221
41
1393
74
Channel-Width
Channel-Width
0
25
1.0
1
1
Patches
HORIZONTAL

TEXTBOX
1223
10
1407
38
System Parameters
18
0.0
1

SLIDER
510
410
802
443
flee-recharge-time
flee-recharge-time
0
960
480.0
1
1
ticks (1 tick = 1.5 minutes)
HORIZONTAL

SLIDER
694
50
902
83
initial-b-methylmercury
initial-b-methylmercury
0
1
0.02
0.001
1
mg/kg
HORIZONTAL

MONITOR
65
194
122
239
NIL
hour
17
1
11

MONITOR
4
195
61
240
NIL
minute
17
1
11

SLIDER
1222
80
1424
113
channel-contamination
channel-contamination
0
10
1.5
.1
1
mg/m
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="test_experiment_1_Alewife_Mod" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>save-world-attributes</final>
    <exitCondition>monthnum = 9</exitCondition>
    <metric>NumAlewivesEaten</metric>
    <metric>adult-alewife-population</metric>
    <metric>minute</metric>
    <metric>hour</metric>
    <metric>day</metric>
    <metric>monthnum</metric>
    <metric>mean-daytime-prey-eaten</metric>
    <metric>mean-spawning-encounters</metric>
    <metric>mean-daily-spawning-encounters</metric>
    <metric>alewives-through-herring-run</metric>
    <metric>mean-habitat-quality</metric>
    <metric>mean-upstream-migration-time</metric>
    <enumeratedValueSet variable="limit-daily-prey-allowance">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="align-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="burst-recharge-time">
      <value value="288"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_alewives">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-alewife-speed">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cohere-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-stripedbass-speed">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-alewife-speed">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-stripedbass-speed">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_stripedbass">
      <value value="0"/>
      <value value="5"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-turn-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-burst-energy">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="separate-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alewife-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flee-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-alewife-spawning-encounters">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stripedbass-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Model-type">
      <value value="&quot;regular_model&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-start-day">
      <value value="111"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rest-between-spawning">
      <value value="832"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test_experiment_Bioaccumulation_Mod" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>alewives = 0</exitCondition>
    <metric>NumAlewivesEaten</metric>
    <metric>adult-alewife-population</metric>
    <metric>minute</metric>
    <metric>hour</metric>
    <metric>day</metric>
    <metric>monthnum</metric>
    <metric>mean-daytime-prey-eaten</metric>
    <metric>alewives-through-herring-run</metric>
    <metric>mean-upstream-migration-time</metric>
    <metric>mean-b-methylmercury-prey</metric>
    <metric>mean-b-methylmercury-predator</metric>
    <metric>mean-exposure-duration-prey</metric>
    <metric>mean-exposure-duration-predator</metric>
    <metric>successfull-migration-to-spawning-ground</metric>
    <metric>mean-daily-bioaccumulation-stripedbass</metric>
    <metric>mean-daily-bioaccumulation-alewives</metric>
    <enumeratedValueSet variable="limit-daily-prey-allowance">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="align-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="burst-recharge-time">
      <value value="288"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_alewives">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-alewife-speed">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cohere-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-stripedbass-speed">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-alewife-speed">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-stripedbass-speed">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_stripedbass">
      <value value="0"/>
      <value value="5"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-turn-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-burst-energy">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="separate-coefficient">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alewife-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-flee-energy">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flee-recharge-time">
      <value value="144"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="limit-alewife-spawning-encounters">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stripedbass-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-start-day">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rest-between-spawning">
      <value value="832"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-size">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="uptake-constant">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elimination-constant">
      <value value="1.0E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trophic-transfer-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Model-type">
      <value value="&quot;prototype&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Channel-Width">
      <value value="1"/>
      <value value="12"/>
      <value value="24"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
