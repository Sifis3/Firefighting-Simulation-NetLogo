breed [fires fire]  ; Fire breed for burning grass
breed [firefighters firefighter]  ; Firefighter breed to extinguish fires

patches-own [countdown burning cooldown]  ; Countdown for regrowth, burning state, and cooldown timer
firefighters-own [fires-quenched time-since-fire]  ; Track number of fires quenched and time since last fire extinguished

to setup
  clear-all

  ; Initialize patches
  ask patches [
    set pcolor green  ; Initialize patches with grass
    set countdown random grass-regrowth-time  ; Randomize regrowth countdowns
    set burning false  ; No fires initially
    set cooldown 0  ; No cooldown initially
  ]

  ; Create fires based on the slider value
  create-fires initial-number-fires [
    set shape "circle"
    set size 1
    set color red
    setxy random-xcor random-ycor
  ]

  ; Create firefighters based on the slider value
  create-firefighters initial-number-firefighters [
    set shape "person"
    set size 1.5
    set color blue
    setxy random-xcor random-ycor
    set fires-quenched 0  ; Initialize fires quenched count
    set time-since-fire 0  ; Initialize time since last fire extinguished
  ]

  reset-ticks
end
to go
  ; Fires spread and burn grass
  ask fires [ spread-fire ]

  ; Firefighters move and extinguish fires
  ask firefighters [
    move
    extinguish-fire
    track-time
  ]

  ; Grass regrowth on burned patches (if cooldown is done)
  ask patches [ grow-grass ]

  ; Update the plot with the current number of fires and firefighters
  plot-pen-reset  ; Reset the plot at each tick to start fresh

  ; Plot the number of fires on the "fires" pen (red line)
  set-current-plot-pen "fires"
  plot count fires  ; Plot the current number of fires

  ; Plot the number of firefighters on the "firefighters" pen (blue line)
  set-current-plot-pen "firefighters"
  plot count firefighters  ; Plot the current number of firefighters

  ; Stop the simulation if ticks reach 450
  if ticks >= 450 [
    stop
  ]

  tick
end




to move  ; firefighter procedure
  rt random 50
  lt random 50

  ; If on dirt (brown), move faster (increase step size)
  if pcolor = brown [
    fd 6  ; Move 6 steps when on dirt
  ]
  ; If on grass (green), move faster (increase step size)
  if pcolor = green [
    fd 3  ; Move 3 steps when on grass
  ]
  ; If neither (could be fire or other), move normally (1 step)
  if pcolor != brown and pcolor != green [
    fd 1  ; Move 1 step on other patches (fire, etc.)
  ]
end

to extinguish-fire  ; firefighter procedure
  let fire-here one-of fires-here
  if fire-here != nobody [
    ask fire-here [ die ]  ; Remove the fire
    set pcolor brown  ; Turn the patch into dirt
    set fires-quenched fires-quenched + 1  ; Increment the firefighter's fire count
    set time-since-fire 0  ; Reset the timer for inactivity

    ; If the firefighter has extinguished 30 fires, they die
    if fires-quenched >= 30 [
      die  ; Remove the firefighter
    ]

    ; Start cooldown period (e.g., 5 seconds) before regrowth can happen
    set cooldown 5  ; Set cooldown to 5 ticks before grass can regrow

    ; Spawn new firefighters if this one quenches 3 fires
    if fires-quenched >= 3 [
      set fires-quenched 0  ; Reset the counter

      ; Check if the number of firefighters is greater than the number of fires
      if ticks > 350 and count firefighters > count fires [
        hatch-firefighters 6 [  ; Spawn 6 new firefighters
          set shape "person"
          set size 4
          set color blue
          setxy random-xcor random-ycor
          set fires-quenched 0
          set time-since-fire 0
        ]
      ]
      ; If not, spawn 1 new firefighter
      if count firefighters <= count fires [
        hatch-firefighters 1 [  ; Spawn 1 new firefighter if the condition is not met
          set shape "person"
          set size 1.5
          set color blue
          setxy random-xcor random-ycor
          set fires-quenched 0
          set time-since-fire 0
        ]
      ]
    ]
  ]
end

to track-time  ; firefighter procedure
  set time-since-fire time-since-fire + 1  ; Increment the inactivity timer
  if time-since-fire >= 40 [
    die  ; Remove the firefighter if inactive for 40 ticks
  ]
end

to spread-fire  ; fire procedure
  ; Check if the fire self-extinguishes (10% chance)
  if random-float 1 < 0.20 [  ; 20% chance for the fire to extinguish by itself
    die  ; Remove the fire
  ]

  ; Otherwise, the fire spreads to neighboring grass patches
  let target one-of neighbors with [pcolor = green and not burning]  ; Check for green grass patches
  if target != nobody [
    ask target [
      set burning true
      sprout-fires 1 [
        set shape "circle"
        set size 1
        set color red
      ]
    ]
  ]

  ; Check if fire spreads to a firefighter
  let fire-on-firefighter one-of firefighters-here
  if fire-on-firefighter != nobody [
    let fire-spread-chance 0.06  ; Default 6% chance to burn the firefighter

    ; Increase the chance if ticks > 300 and there are more fires than firefighters
    if ticks > 350 and count fires / 25 > count firefighters [
      set fire-spread-chance 0.22  ; Increase the chance to 22%
    ]

    ; Apply the fire spread chance
    if random-float 1 < fire-spread-chance [  ; Use the dynamically adjusted spread chance
      ask fire-on-firefighter [
        die  ; Firefighter is burned and dies
      ]
    ]
  ]
end

to grow-grass  ; patch procedure
  if pcolor = brown and cooldown > 0 [
    set cooldown cooldown - 1  ; Decrease cooldown after each tick
  ]

  if pcolor = brown and cooldown = 0 [  ; If the patch is dirt and cooldown is over
    if random-float 1 < 0.05 [  ; 5% chance for grass regrowth (increased chance)
      set pcolor green  ; Grass regrows
      set countdown grass-regrowth-time  ; Start regrowth countdown
    ]
  ]

  ; After regrowth, the patch should allow fire to spread again
  if pcolor = green and burning [
    set countdown countdown - 1  ; Decrease the countdown after regrowth
    if countdown <= 0 [
      set burning false  ; Stop burning after countdown finishes
    ]
  ]
end





@#$#@#$#@
GRAPHICS-WINDOW
355
10
873
529
-1
-1
10.0
1
14
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
40
100
252
133
grass-regrowth-time
grass-regrowth-time
0
100
30.0
1
1
NIL
HORIZONTAL

BUTTON
50
155
150
200
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
185
155
280
200
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
0
60
172
93
initial-number-fires
initial-number-fires
1
100
5.0
1
1
NIL
HORIZONTAL

SLIDER
175
60
357
93
initial-number-firefighters
initial-number-firefighters
1
50
30.0
1
1
NIL
HORIZONTAL

SWITCH
80
15
267
48
grass-regrowth-enabled
grass-regrowth-enabled
0
1
-1000

MONITOR
145
225
222
270
Active Fires
count fires
17
1
11

MONITOR
10
225
142
270
Firefighters Remaining
count firefighters
17
1
11

MONITOR
225
225
352
270
Grass Coverage (%)
(count patches with [pcolor = green] / count patches) * 100
17
1
11

PLOT
15
290
345
440
Fires and Firefighters Plot
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"fires" 1.0 0 -2674135 true "" ""
"firefighters" 1.0 0 -13345367 true "" ""

@#$#@#$#@
## WHAT IS IT?
In order to shed light on the complexities of resource management and response strategies in an environment susceptible to disturbances like fires this model depicts an ecosystem that includes the interactions between fires firefighters and grass. The primary goal is to examine how fires spread through grassy areas the tactics used by firefighters to put out these fires and the overall effects on the balance of the ecosystem. Additionally this model demonstrates the ability to make decisions in a distributed environment where firefighters act independently to combat fire outbreaks.

## HOW IT WORKS
The following are the main elements of the model. Grass: The main source of fire fuel is grass which is symbolized by green patches. Grass patches are the only way for fire to spread. fires. Red patches indicate fires that spread through nearby grass patches. The amount of grass present determines the fires intensity and spread. Firemen:. To put out fires firefighters (represented by turtles) travel across the grid. Each firefighter can put out fires on the patches they are assigned to or nearby patches but their range of motion is restricted. The dynamics of simulation. At the beginning fires start at random or according to user configuration. Grass replicates natural regrowth by growing back after a predetermined amount of time. Firefighters are always on the move spotting fires in their vicinity and putting them out. The way these parts work together enables the user to examine how the system responds to different circumstances and how well firefighters are able to control fire outbreaks. 

## HOW TO USE IT
Adjust the sliders to set simulation parameters:
INITIAL-GRASS-DENSITY: The percentage of the landscape covered by grass at the start.
NUMBER-OF-FIREFIGHTERS: The number of firefighters deployed in the simulation.
FIRE-SPREAD-RATE: The probability of fire spreading to adjacent patches.
GRASS-REGROWTH-TIME: The time it takes for burned grass to regrow.
Press the SETUP button to initialize the environment.
Press the GO button to start the simulation.

## PARAMETERS
INITIAL-GRASS-DENSITY: Initial coverage of grass on the grid.
NUMBER-OF-FIREFIGHTERS: Number of firefighter agents deployed.
FIRE-SPREAD-RATE: Likelihood of a fire spreading to neighboring patches.
GRASS-REGROWTH-TIME: Time for burned grass patches to regenerate.
FIREFIGHTER-SPEED: Speed at which firefighters move across the grid.

## OUTPUTS
Plots:
A single plot showing the amount of grass, active fires, and firefighters’ actions over time.
Monitors:
Current grass coverage.
Number of active fires.
Firefighters actively extinguishing fires.

## THINGS TO NOTICE
Examine the differences in fire spread between high and low grass densities. Take note of the speed and efficiency with which firefighters attend to fires. Consider the relationship between fire spread and grass regrowth. Does a fast rate of regrowth contribute to environmental stability?

## THINGS TO TRY
Grass Density:
Experiment with low and high initial grass densities. What happens when there’s too little or too much grass?
Firefighters’ Deployment:
Increase or decrease the number of firefighters. Does more manpower always result in better control of fires?
Fire Spread Rate:
Set a high fire spread rate to simulate extreme fire conditions. Can firefighters still manage the situation effectively?
Grass Regrowth Time:
Modify the regrowth time to simulate faster or slower ecological recovery. How does this affect fire intensity over time?

## EXTENDING THE MODEL
Add water bodies (non-flammable patches) to the grid to simulate natural firebreaks.
Introduce wind direction and strength to make fire spread asymmetrically.
Simulate a priority system where firefighters prioritize larger fires or fires near critical zones.

## NETLOGO FEATURES
Patches: Represent grass, fire, and burned areas dynamically.
Turtles: Firefighters are modeled as autonomous agents navigating the grid.
BehaviorSpace: Enables systematic exploration of parameter variations, allowing you to assess the resilience of the ecosystem under different scenarios.
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
NetLogo 6.4.0
@#$#@#$#@
set model-version "sheep-wolves-grass"
set show-energy? false
setup
repeat 75 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="BehaviorSpace run 3 experiments" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="450"/>
    <metric>count turtles with [label = "fire"]</metric>
    <metric>count turtles with [label = "firefighter"]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <enumeratedValueSet variable="initial-number-firefighters">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grass-regrowth-enabled">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-fires">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grass-regrowth-time">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
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
1
@#$#@#$#@
