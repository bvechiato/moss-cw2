extensions [ py ]
__includes [ "network.nls" "users.nls" "tweets.nls" "algorithms.nls" "visualisation.nls"]

globals [
  global-echo-chamber-evaluation
  belief-purity-average
  std-belief-purity
]


;;;;;;;;;;;;;
;;; SETUP ;;;
;;;;;;;;;;;;;
to setup
  clear-all

  set-default-shape users "circle"
  set-default-shape tweets "triangle"
  random-seed seed

  setup-python
  create-initial-network

  no-display

  reset-ticks

  layout-network
  plot-followers-following

  set belief-purity-average mean [belief-purity] of users
  set std-belief-purity standard-deviation [belief-purity] of users

  update-opinion-sd
  get-global-echo-chamber-evaluation
end


;;;;;;;;;;
;;; GO ;;;
;;;;;;;;;;
to go
  let online-users n-of (count users * 0.42 ) users  ;; Select 40% of users
  ask online-users [
    let belief-purity-sum 0

    ;; VIEW TWEETS
    let n_to_view determine-posts-viewed
    let tweets-to-view []

    ;; Retrieve tweets based on weighted random selection
    repeat n_to_view [
      let x random-float 1

      ;; Step 2: Determine which category the post falls into based on x
      if x < belief-local [
        ;; Tweets from local belief range
        let local-tweet find-tweet-in-belief-range-local
        if local-tweet != nobody [
          set tweets-to-view lput local-tweet tweets-to-view
        ]
      ]

      if belief-local <= x and x < belief-local + belief-global [
        ;; Tweets from global belief range
        let global-tweet find-tweet-in-belief-range-global
        if global-tweet != nobody [
          set tweets-to-view lput global-tweet tweets-to-view
        ]
      ]

      if belief-local + belief-global <= x and x < belief-local + belief-global + chronological [
        ;; Tweets based on chronological order
        let local-tweet find-most-recent-tweet
        if local-tweet != nobody [
          set tweets-to-view lput local-tweet tweets-to-view
        ]
      ]

      if belief-local + belief-global + chronological <= x and x <= 1 - popularity - randomised [
        ;; Tweets based on popularity
        let local-tweet find-most-popular-tweet
        if local-tweet != nobody [
          set tweets-to-view lput local-tweet tweets-to-view
        ]
      ]

      if 1 - popularity - randomised < x [
        ;; Random tweets
        let local-tweet find-random-tweet
        if local-tweet != nobody [
          set tweets-to-view lput local-tweet tweets-to-view
        ]
      ]
    ]

    if length tweets-to-view > 0 [
      foreach tweets-to-view [
        curr_tweet ->
        let tweet-belief [belief] of curr_tweet

        ;; UPDATE BELIEF
        update-belief tweet-belief

        ;; RETWEET
        if random-float 1 < 0.08 [
          let curr-user self
          ask curr_tweet [ retweet curr-user ]
        ]

        ;; ADD TO SEEN LIST
        ;; set seen lput curr_tweet seen

        set belief-purity-sum belief-purity-sum + abs(belief - tweet-belief)
      ]
    ]

    set belief-purity 1 - (belief-purity-sum / (2 * n_to_view))
  ]

  ;; update echochamber tracking
  update-opinion-sd
  get-global-echo-chamber-evaluation

  ;; TWEET
  repeat count online-users [                       ;; Repeat for every user
    if random-float 1 < 0.5 [
      let selected-user one-of online-users         ;; Randomly select one user
      create-tweet-for-user selected-user           ;; Make that turtle post a tweet
    ]
  ]


  ;; REMOVE OLD TWEETS
  while [count tweets > 7500] [
    ;; Find and delete the oldest tweet based on the `time-posted` variable
    let oldest-tweet min-one-of tweets [time-posted]
    ask oldest-tweet [ die ]
  ]

  set belief-purity-average mean [belief-purity] of users
  set std-belief-purity standard-deviation [belief-purity] of users

  tick
end


to setup-python
  py:setup py:python
  py:run "from scipy.stats import beta"
  py:run "import numpy as np"
  py:run "from scipy.stats import beta"

  py:set "seed" 12345
  py:run "rng = np.random.default_rng(seed)"
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DETERMINE POST NUMBER ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report determine-posts-viewed
  py:run "import numpy as np"
  py:run "num_posts = rng.negative_binomial(40, 0.5)" ; Use the seeded RNG]

  report py:runresult "num_posts"
end

to run-simulations-5-seeds
  let seeds [47822 13523 31238 98424 64001]  ;; List of 5 seeds
  foreach seeds [
    curr-seed ->  ;; Set the seed for random number generation
    run-simulations-one-algo curr-seed  ;; Call the run-simulations procedure with the current seed
  ]

  foreach seeds [
    curr-seed ->  ;; Set the seed for random number generation
    run-simulations-weighted-algo curr-seed  ;; Call the run-simulations procedure with the current seed
  ]
end

to run-simulations-one-algo [set-seed]
  run-simulation 1 0 0 0 0 "belief-local-1" set-seed
  run-simulation 0 1 0 0 0 "belief-global-1" set-seed
  run-simulation 0 0 1 0 0 "chronological-1" set-seed
  run-simulation 0 0 0 1 0 "randomised-1" set-seed
  run-simulation 0 0 0 0 1 "popularity-1" set-seed
end

to run-simulations-weighted-algo [set-seed]
  run-simulation 0.5 0 0 0 0.5 "belief-local-0.5-popularity-0.5" set-seed
  run-simulation 0.5 0 0 0.5 0 "belief-local-0.5-randomised-0.5" set-seed
  run-simulation 0.5 0 0.5 0 0 "belief-local-0.5-chronological-0.5" set-seed
  run-simulation 0.5 0.5 0 0 0 "belief-local-0.5-belief-global-0.5" set-seed

  run-simulation 0 0.5 0 0 0.5 "belief-global-0.5-popularity-0.5" set-seed
  run-simulation 0 0.5 0 0.5 0 "belief-global-0.5-randomised-0.5" set-seed
  run-simulation 0 0 0.5 0 0.5 "chronological-0.5-popularity-0.5" set-seed
  run-simulation 0 0 0.5 0.5 0 "chronological-0.5-randomised-0.5" set-seed

  run-simulation 0 0 0 0.5 0.5 "randomised-0.5-popularity-0.5" set-seed
  run-simulation 0.25 0 0.25 0.25 0.25 "all" set-seed
end


to run-simulation [belief-local-value belief-global-value chronological-value randomised-value popularity-value algo-name set-seed]
  set belief-local belief-local-value
  set belief-global belief-global-value
  set chronological chronological-value
  set randomised randomised-value
  set popularity popularity-value
  set number-of-agents 500
  set seed set-seed

  setup

  ;; Turn off graphics (hide turtles and disable plots)
  ask turtles [
    hide-turtle
  ]

  ask links [
    hide-link
  ]

  ;; Loop through different ticks (20, 40, 60, 80, 100)
  foreach [10 20 30 40 50] [
    tick-value ->
    repeat 10 [
      go
    ]

    if ticks = tick-value [
      export-user-opinion-sd tick-value algo-name set-seed
      export-user-belief tick-value algo-name set-seed
    ]
  ]

  ;; Export final plots and interface
  export-plot "Belief Purity" (word "/Users/bea/Downloads/moss-cw2/results/seed-" set-seed "/" algo-name "/belief-purity.csv")
  export-plot "Global Echo Chamber Eval" (word "/Users/bea/Downloads/moss-cw2/results/seed-" set-seed "/" algo-name "/gec.csv")
  export-interface (word "/Users/bea/Downloads/moss-cw2/results/seed-" set-seed "/" algo-name "/interface.png")
end


to export-user-opinion-sd [at-tick algo-name set-seed]
  let file-name (word "/Users/bea/Downloads/moss-cw2/results/seed-" set-seed "/" algo-name "/opinion-sd-" at-tick ".csv")

  if file-exists? file-name [
    file-delete file-name
  ]

  file-open file-name

  ;; Write headers
  file-print "turtle-id,opinion-sd"

  ;; Loop over each turtle and write their ID and energy to the file
  ask users [
    file-print (word who "," opinion-sd)
  ]

  file-close
end

to export-user-belief [at-tick algo-name set-seed]
  let file-name (word "/Users/bea/Downloads/moss-cw2/results/seed-" set-seed "/" algo-name "/belief-" at-tick ".csv")

  if file-exists? file-name [
    file-delete file-name
  ]

  file-open file-name

  ;; Write headers
  file-print "turtle-id,belief"

  ;; Loop over each turtle and write their ID and energy to the file
  ask users [
    file-print (word who "," belief)
  ]

  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
496
12
1168
685
-1
-1
5.49
1
10
1
1
1
0
0
0
1
-60
60
-60
60
1
1
1
ticks
15.0

BUTTON
9
14
125
47
NIL
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
135
13
233
46
NIL
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
5
60
191
93
number-of-agents
number-of-agents
0
1000
500.0
100
1
NIL
HORIZONTAL

PLOT
5
148
313
268
Follower/Following Distribution
# of followers
freq
0.0
200.0
0.0
200.0
false
true
"" ""
PENS
"followers" 10.0 0 -16777216 true "" ""
"following" 10.0 0 -7500403 true "" ""

MONITOR
6
100
120
145
NIL
number-of-tweets
0
1
11

PLOT
251
534
484
676
Belief Distribution
belief
# of users
-1.0
1.0
0.0
200.0
false
false
"set-plot-y-range 0 number-of-agents / 2" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [belief] of users"

PLOT
7
277
233
397
SD of opinion difference
NIL
NIL
0.0
2.0
0.0
10.0
true
false
"set-plot-y-range 0 number-of-agents / 2" ""
PENS
"pen-0" 0.1 1 -16777216 true "" "histogram [opinion-sd] of users"

PLOT
240
277
486
397
Average Opinion Difference
ticks
NIL
0.0
2.0
0.0
2.0
false
true
"set-plot-x-range 0 2" "ifelse ticks > 0 [set-plot-x-range 0 ticks] [set-plot-x-range 0 2]"
PENS
"max" 1.0 0 -14070903 true "" "plotxy ticks precision (max [average-echo] of users) 1"
"mean" 1.0 0 -7858858 true "" "plotxy ticks precision (mean [average-echo] of users) 1"

PLOT
9
408
482
528
Global Echo Chamber Eval
ticks
NIL
0.0
10.0
0.0
10.0
true
false
"" "ifelse ticks > 0 [set-plot-x-range 0 ticks] [set-plot-x-range 0 2]"
PENS
"default" 1.0 0 -2674135 true "" "plotxy ticks global-echo-chamber-evaluation"
"pen-1" 1.0 0 -5987164 true "" ""

PLOT
9
535
244
677
Global Echo Chamber Distribution
NIL
NIL
-1.0
1.0
-1.0
1.0
false
false
"set-plot-y-range 0 number-of-agents / 2" ""
PENS
"default" 0.2 1 -16777216 true "" "histogram [local-echo-eval] of users"

SLIDER
320
234
484
267
belief-local
belief-local
0
1
0.25
0.25
1
NIL
HORIZONTAL

SLIDER
320
196
485
229
belief-global
belief-global
0
1
0.0
0.25
1
NIL
HORIZONTAL

SLIDER
320
158
484
191
randomised
randomised
0
1
0.25
0.25
1
NIL
HORIZONTAL

SLIDER
321
74
484
107
popularity
popularity
0
1
0.25
0.25
1
NIL
HORIZONTAL

SLIDER
319
117
482
150
chronological
chronological
0
1
0.25
0.25
1
NIL
HORIZONTAL

TEXTBOX
321
55
536
83
Algorithms, should add up to 1
11
0.0
1

PLOT
13
691
213
841
Belief Purity
NIL
NIL
0.0
10.0
0.0
1.5
false
false
"ifelse ticks > 0 [set-plot-x-range 0 ticks] [set-plot-x-range 0 2]" "ifelse ticks > 0 [set-plot-x-range 0 ticks] [set-plot-x-range 0 2]"
PENS
"default" 1.0 0 -16777216 true "" "plotxy ticks belief-purity-average"
"pen-1" 1.0 0 -5298144 true "" "plotxy ticks belief-purity-average + std-belief-purity"
"pen-2" 1.0 0 -13345367 true "" "plotxy ticks belief-purity-average - std-belief-purity"

INPUTBOX
209
68
305
128
seed
64001.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

In some networks, a few "hubs" have lots of connections, while everybody else only has a few.  This model shows one way such networks can arise.

Such networks can be found in a surprisingly large range of real world situations, ranging from the connections between websites to the collaborations between actors.

This model generates these networks by a process of "preferential attachment", in which new network members prefer to make a connection to the more popular existing members.

## HOW IT WORKS

The model starts with two nodes connected by an edge.

At each step, a new node is added.  A new node picks an existing node to connect to randomly, but with some bias.  More specifically, a node's chance of being selected is directly proportional to the number of connections it already has, or its "degree." This is the mechanism which is called "preferential attachment."

## HOW TO USE IT

Pressing the GO ONCE button adds one new node.  To continuously add nodes, press GO.

The LAYOUT? switch controls whether or not the layout procedure is run.  This procedure attempts to move the nodes around to make the structure of the network easier to see.

The PLOT? switch turns off the plots which speeds up the model.

The RESIZE-NODES button will make all of the nodes take on a size representative of their degree distribution.  If you press it again the nodes will return to equal size.

If you want the model to run faster, you can turn off the LAYOUT? and PLOT? switches and/or freeze the view (using the on/off button in the control strip over the view). The LAYOUT? switch has the greatest effect on the speed of the model.

If you have LAYOUT? switched off, and then want the network to have a more appealing layout, press the REDO-LAYOUT button which will run the layout-step procedure until you press the button again. You can press REDO-LAYOUT at any time even if you had LAYOUT? switched on and it will try to make the network easier to see.

## THINGS TO NOTICE

The networks that result from running this model are often called "scale-free" or "power law" networks. These are networks in which the distribution of the number of connections of each node is not a normal distribution --- instead it follows what is a called a power law distribution.  Power law distributions are different from normal distributions in that they do not have a peak at the average, and they are more likely to contain extreme values (see Albert & Barabási 2002 for a further description of the frequency and significance of scale-free networks).  Barabási and Albert originally described this mechanism for creating networks, but there are other mechanisms of creating scale-free networks and so the networks created by the mechanism implemented in this model are referred to as Barabási scale-free networks.

You can see the degree distribution of the network in this model by looking at the plots. The top plot is a histogram of the degree of each node.  The bottom plot shows the same data, but both axes are on a logarithmic scale.  When degree distribution follows a power law, it appears as a straight line on the log-log plot.  One simple way to think about power laws is that if there is one node with a degree distribution of 1000, then there will be ten nodes with a degree distribution of 100, and 100 nodes with a degree distribution of 10.

## THINGS TO TRY

Let the model run a little while.  How many nodes are "hubs", that is, have many connections?  How many have only a few?  Does some low degree node ever become a hub?  How often?

Turn off the LAYOUT? switch and freeze the view to speed up the model, then allow a large network to form.  What is the shape of the histogram in the top plot?  What do you see in log-log plot? Notice that the log-log plot is only a straight line for a limited range of values.  Why is this?  Does the degree to which the log-log plot resembles a straight line grow as you add more nodes to the network?

## EXTENDING THE MODEL

Assign an additional attribute to each node.  Make the probability of attachment depend on this new attribute as well as on degree.  (A bias slider could control how much the attribute influences the decision.)

Can the layout algorithm be improved?  Perhaps nodes from different hubs could repel each other more strongly than nodes from the same hub, in order to encourage the hubs to be physically separate in the layout.

## NETWORK CONCEPTS

There are many ways to graphically display networks.  This model uses a common "spring" method where the movement of a node at each time step is the net result of "spring" forces that pulls connected nodes together and repulsion forces that push all the nodes away from each other.  This code is in the `layout-step` procedure. You can force this code to execute any time by pressing the REDO LAYOUT button, and pressing it again when you are happy with the layout.

## NETLOGO FEATURES

Nodes are turtle agents and edges are link agents. The model uses the ONE-OF primitive to chose a random link and the BOTH-ENDS primitive to select the two nodes attached to that link.

The `layout-spring` primitive places the nodes, as if the edges are springs and the nodes are repelling each other.

Though it is not used in this model, there exists a network extension for NetLogo that comes bundled with NetLogo, that has many more network primitives.

## RELATED MODELS

See other models in the Networks section of the Models Library, such as Giant Component.

See also Network Example, in the Code Examples section.

## CREDITS AND REFERENCES

This model is based on:
Albert-László Barabási. Linked: The New Science of Networks, Perseus Publishing, Cambridge, Massachusetts, pages 79-92.

For a more technical treatment, see:
Albert-László Barabási & Reka Albert. Emergence of Scaling in Random Networks, Science, Vol 286, Issue 5439, 15 October 1999, pages 509-512.

The layout algorithm is based on the Fruchterman-Reingold layout algorithm.  More information about this algorithm can be obtained at: http://cs.brown.edu/people/rtamassi/gdhandbook/chapters/force-directed.pdf.

For a model similar to the one described in the first suggested extension, please consult:
W. Brian Arthur, "Urban Systems and Historical Path-Dependence", Chapt. 4 in Urban systems and Infrastructure, J. Ausubel and R. Herman (eds.), National Academy of Sciences, Washington, D.C., 1988.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2005).  NetLogo Preferential Attachment model.  http://ccl.northwestern.edu/netlogo/models/PreferentialAttachment.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2005 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2005 -->
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
set layout? false
set plot? false
setup repeat 300 [ go ]
repeat 100 [ layout ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="run-simulations" repetitions="1" runMetricsEveryStep="true">
    <setup>setup run-simulations</setup>
    <go>go</go>
    <metric>count turtles</metric>
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
