;In this model, agents have a cultural memory of a set length.
; It begins totally as the starting culture. As the agent comes into
; contact with another culture, a memory of that culture may be added to
; the end of the array, pushing the first memory out.



extensions [array table gis nw profiler]

globals [
  ;Input Variables
  NUM_TRIBE_MEMBERS ; number of members within each tribe (21 in each of the 4 tribes = 84 total)
  NUM_CULTURES ; total number of cultures within the model (4 cultures represented by colors red, orange, yellow and brown)
  TRIBE_EXTENT ; radius within which the tribe is established and tribe members move about: 15 in setup
  ;TERRITORY_EXTENT ; intended to work as an extended area for the TRIBE_EXTENT and adds a buffer zone which could overlap with the territories of other tribes: 20 in setup
  CULTURE_LENGTH ; an array that holds the last 10 cultures of an agent: 10 in setup
  INFLUENCE_RATE ; a rate associated to culture/belief propagation by which agents can be influenced by their neighbors: 0.05 in setup
  person_VISIBILITY ; radius around a person within which it looks for animals to hunt or grain to gather: 4 in setup
  narratives ; a vector holding 5 strings which represent the stories/narratives behind the symbolism of a culture
  ;TRUST_LIMIT ; Setting the level of trust-based restriction

  animal_VISIBILITY ; radius around an animal within which agents who are present can hunt that animal: 4 in setup
  NUM_ANIMALS ; number of animals in the model: 5000 at setup
  ANIMAL_FERTILITY ; fertility rate of animals: 0.94 at setup
  ;ANIMAL_FOOD_YIELD ; the food yield of an animal: 10 at setup
  ;NUM_PATCH_GRAINS ; number of grains in each patch
  ;CULTIVATION_RATE ; rate by which the fertility of a land increases as agents continue to gather its grains: 1.10 at setup (10% increase)
  ;GRAIN_FEASIBILITY_THRESHOLD ; threshold that holds a value which determines the feasibility of a grain, Commented because the slider already creates it in globals

  ;Control Flow
  Cultivate_Land ;True if we can grow and harvest grain
  Build_Centers ;True if people stay behind to develop the center
  Hold_Festivals ;True if people visit their cultural center once a year
  ;Tribe_Territories ;True if the tribes need to stay in TERRITORY_EXTENT of their starting location
  top-festival-agents ; top agents who are chosen to attend the festival
  FestivalAttendees ; agents who attended each festival for each culture
  Festivals_Count ; holding the number of times a festival has been held at a given cultural center
  Clique_Count ; number of cliques formed in each tick
  Total_Cooperation ; addition of the number of festivals and cliques to find the total number of times agents could've been in a cooperative state

  ;Monitoring
  Festival_Time ; true if it is the time of festival for cultures
  Cooperation_Threshold ; if true along with sense of belonging threshold, social cohesion and group identity have occured
  Belonging_Threshold ; if true along with cooperation threshold, social cohesion and group identity have occured
  Monument-Established ; has the position of the monument been fixed in one spot

  ;Calendar
  Day_Festival_Start ; the day top performing agents of each culture go to their respective cultural centers: every 250 ticks/days in setup
  Day_Festival_End ; the day top performing agents of each culture come back from their respective cultural centers:  every 350 ticks/days in setup
  Day_Animal_Birth ; animal reproduction day: every 100 ticks/days in setup
  Day_Grain_Planting ; grain planting/harvesting day: every 70 ticks/days in setup
  Days_Grain_Maturity ; grain maturity day: every 160 ticks/days in setup
  Day_Grain_Spoiled ; grain spoiling day: every 340 ticks/days in setup

  Age_Animal_Edible ; the age when an animal is edible: 0.2 in setup
  Age_Animal_Mature ; the age when an animal matures: 2 in setup
  Age_Animal_Old ; the age when an animal is old: 6 in setup
  Age_Animal_Death ; the age when an animal dies: 9.5 in setup

  ;Outputs
  First_Feasible_Grain_Tick ; reporting at which tick the grain is first feasible
  First_Feasible_Grain_Distance_From_Cultural_Center ; distance of the first feasible grain to the closest cultural center
  Debug_Output ; used to report debugs
]

breed [people person]
breed [animals animal]
breed [grains grain]
breed [tribes tribe]
breed [culturalCenters culturalCenter]
breed [monuments monument]


patches-own
[
  fertility ; fertility of grains within a patch: 0 at setup

  inCulturalCenter ; Patches will remember if they are within the working radius of a cultural center, to speed up calculations.
]

people-own [

  culture ; the culture an agent belongs to (red, orange, yellow or brown)

  dominantCulture ; the main culture of each agent at any given point. updated as new memories enter CULTURE_LENGTH and the old ones leave.

  importance ; the importance of the agents effects how much they can influence another agent's culture/belief. currently all agents hold a regular importance level (1). Regular people have importance 1, Seniors have importance 2, Shamans have importance 3

  tolerance ; 0-1, how likely an agent is to accept a culture that is not its dominant culture. tolerance is set to the INFLUENCE_RATE (0.05) at the beginning of the model. Regular people have tolerance 0.5

  myTribe ; the tribe of an agent

  consumption ; the amount of food consumption by this agent

  HuntingScore ; addition of the food yield of each animal an agent hunts

  GatheringScore ; addition of the food yield of each grain an agent gathers

  HGscore ; addition of the HuntingScore and GatheringScore

  lastAte ; when did an agent last eat, used to see when to eat again

  same-family ; agents being of the same family (identified with their shapes)

  same-tribe ; agents being of the same tribe (identified with myTribe)

  same-culture ; agents being of the same culture (identified with their colors)

  SimilarityScore ; addition of same-family, same-tribe, and same-culture to see how much two agents are alike

  trustworthiness ; a measure to check the in-group favoritism (SimilarityScore) and competency (performed)

  community ; an agent's tribe unless the agent is at its cultural center which then it becomes the agent's culture/belief associated with the center and once the festival ends changes to the agent's tribe again.

  performed ; a counter for how many times an agent has been chosen to attend festival performance at the cultural center (used as a measure of cooperation)

  partnered ; a counter for how many times an agent has been a part of a clique (used as a measure of cooperation)

  cooperation ; adding the number of times an agent performed and partnered in hunts

  potentialPartners ; agents who are trustworthy and may be chosen to partner with for the hunt

  family-belonging ; a score showing an agent's sense of belonging to its family

  family-belonging-ratio ; showing what portion of the sense of belonging is comprised of family belonging

  tribe-belonging ; a score showing an agent's sense of belonging to its tribe

  tribe-belonging-ratio ; showing what portion of the sense of belonging is comprised of tribe belonging

  culture-belonging ; a score showing an agent's sense of belonging to its culture

  culture-belonging-ratio ; showing what portion of the sense of belonging is comprised of culture belonging

  SenseOfBelonging ; the overall sense of belonging of an agent measured by the addition of family, tribe and culture belongings

  narrative-attachment ; the percentage of dedication to each narrative defined as a random percentage and influenced during festivals

  celebrating ; boolean used to signify if it is festival time

  returning ; boolean used to signify if festival time has ended and the top performing agents have gone back
]

; A tribe is tied to a particular habitat (set of patches)
; and is located in the middle of that habitat.

animals-own [

  birthTick ; the timestep when an animal is born which helps with age and food yield
]

grains-own [

  birthTick ; the timestep when a grain appears which helps with age and food yield

  ;foodYield

  foodPotential ; Maximum food yield of a grain. The yield we get when a patch is 100% fertile (Every time a grain is picked, its foodPotential gets a little higher allowing for a natural process of harvesting to occur)

  currentYield ; At every tick depending on the fertility of the patch, the currentYield would be different

  planted ; checking if a grain is planted or not and works as a flag or boolean
]


tribes-own [

  startingPosition ; Where is the tribe located?

  startingHabitat ; Which patches does the tribe start on?

  startingCulture ; Which culture does the tribe start with?

  tribe-label ; tribe labels: A, B, C, or D

  members ; which agents are members of this tribe?

  ; culturalCenter ;This is the target that serves as the cultural center.

  food ; How much communal food is there?

  tribe-hunted-food ; amount of food that was comprised of hunting animals

  tribe-gathered-food ; amount of food that was comprised of gathering grains
]

; Maintenance Procedure: during festival performance people will attach to the cultural center instead of to the tribe.
; During this time they will be anchored to the cultural center and it will receive their hunting yield.

culturalCenters-own [

  culture ; the culture associated with each cultural center

  established ; has the position of the cultural center been fixed in one spot

  members ; which agents are members of the culture to which this cultural center belongs?

  food ; shows the amount of communal food

  cult-hunted-food ; amount of food that was comprised of hunting animals

  cult-gathered-food ; amount of food that was comprised of gathering grains

]

monuments-own [

  members ; which agents are members of the mmonument

  food ; shows the amount of communal food

  mon-hunted-food ; amount of food that was comprised of hunting animals

  mon-gathered-food ; amount of food that was comprised of gathering grains

]


;;;;;;;;;;;;;;;;;
;;    SETUP    ;;
;;;;;;;;;;;;;;;;;

to setupGlobals

  ;Input Variables
  set NUM_TRIBE_MEMBERS 21
  set NUM_CULTURES 4
  set TRIBE_EXTENT 15
  ;set TERRITORY_EXTENT 20
  set CULTURE_LENGTH 10
  set INFLUENCE_RATE 0.5
  set person_VISIBILITY 4
  set narratives ["A" "B" "C" "D" "E"]
  ;set TRUST_LIMIT 1

  set animal_VISIBILITY 4
  set NUM_ANIMALS 5000
  set ANIMAL_FERTILITY 0.94
  ;set ANIMAL_FOOD_YIELD 10
  ;set NUM_PATCH_GRAINS 10
  ;set CULTIVATION_RATE 1.10
  ;set GRAIN_FEASIBILITY_THRESHOLD 2

  ;Control Flow
  set Cultivate_Land true
  set Build_Centers true
  set Hold_Festivals true
  ;set Tribe_Territories false
  set top-festival-agents []
  set FestivalAttendees table:make
  set Festivals_Count 0
  set Clique_Count 0
  set Total_Cooperation 0

  ;Monitoring
  set Festival_Time false
  set Cooperation_Threshold false
  set Belonging_Threshold false
  set Monument-Established false

  ;Calendar
  set Day_Festival_Start 250
  set Day_Festival_End 350
  set Day_Animal_Birth 100
  set Day_Grain_Planting 70
  set Days_Grain_Maturity 160
  set Day_Grain_Spoiled 340

  set Age_Animal_Edible 0.2
  set Age_Animal_Mature 2
  set Age_Animal_Old 6
  set Age_Animal_Death 9.5

  ;Outputs
  set First_Feasible_Grain_Tick ""
  set First_Feasible_Grain_Distance_From_Cultural_Center ""
  set Debug_Output ""
end

to setup
  clear-all
  reset-ticks
  random-seed new-seed
  setupGlobals
  if file-exists? "GT_SNA-20.json" [file-close file-delete "GT_SNA-20.json"] ;for the SNA

  ask patches ;Initialize the patches
  [
    set fertility 0.01 + (random-float 0.1)
    set inCulturalCenter false
  ]
  ask n-of 1000 patches [ ; have 1000 random patches sprout animals and begin their life term
    sprout-animals (NUM_ANIMALS / 1000) [
      animal-init
      set birthTick (random 365 * 4) - (365 * 4)
    ]
  ]
  ask people [
      person-setColor ; Set the color based on culture
  ]

  let midpointX max-pxcor * 0.5
  let midpointY max-pycor * 0.5

  spawnTribe midpointX * -1 midpointY * -0.25 TRIBE_EXTENT 1 "A" ; location of tribe "A" at setup
  spawnTribe midpointX * 0.3 midpointY * -1 TRIBE_EXTENT 2 "B" ; location of tribe "B" at setup
  spawnTribe midpointX midpointY * -1 TRIBE_EXTENT 3 "C" ; location of tribe "C" at setup
  spawnTribe midpointX * -0.5 midpointY * -1 TRIBE_EXTENT 4 "D" ; location of tribe "D" at setup

  setupCulturePlot ; setup the culture plot on the interface

  show "SETUP"
end

;;;;;;;;;;;;;;;;;;;;;
;;    MAIN LOOP    ;;
;;;;;;;;;;;;;;;;;;;;;

to go
  ;;; <<<< clean up all the edges that are created in this tick >>>>
  ask links [die]

  if count people = 0 [ stop ]

  ;let _t0 timer
  foreach shuffle sort people [ x ->  ; Shuffle the people each time
    ask x [
      person-maybeAdoptCulture  ; Look at who else is on our space and maybe get converted
      person-setColor  ; Update our color to reflect our dominant culture
      person-eat
      person-move
    ]
  ]
  ;let _t1 timer
  ;show (word "person moves took " (_t1 - _t0) " seconds.")

;  profiler:start
  ;let _t0 timer
  hunt-gather
  ;let _t1 timer
  ;show (word "hunt took " (_t1 - _t0) " seconds.")
;  show "hunt is done!!"

;  profiler:stop          ;; stop profiling
;  print profiler:report  ;; view the results
;  profiler:reset         ;; clear the data

  ;set _t0 timer

  if Cultivate_Land [ updateGrain ] ; if it's true and we can grow and harvest grains, update grain settings
  reproduceAnimals
  moveAnimals

  tribe-reproduce

  ask tribes [
    tribe-move
    ;tribe-reproduce ; agents being added to the tribe with food surplus to maintain the total number of agents in the model
    establish-cultural-center
  ]

  ;show (word "tick: " ticks)

  ;ask tribes [
  ;  show (word "tribe: " self " consumption: " sum [consumption] of people with [myTribe = myself] " food: " food)
  ;]

  if Hold_Festivals [ performFestival ] ; if it's festival time perform festival
  ask culturalCenters with [established = false] [
    culturalCenter-move ; move cultural centers if they have not been established
  ]
  getCultureCount ; counting the number of people in each culture and storing it
  plotCultures ; ploting cultures on the interface

  collector ; collecting the data for SNA

  set Total_Cooperation Clique_Count + Festivals_Count ; addition of the number of festivals and cliques to find the total number of times agents could've been in a cooperative state
  ;show word "Total Cooperation: " Total_Cooperation

  ask people [
    set cooperation partnered + performed ; getting the number of times an agent took part in a collaborated effort
    ifelse SenseOfBelonging = 0 ; avoiding an error for division by zero
          [set family-belonging-ratio family-belonging-ratio = 0]
          [set family-belonging-ratio family-belonging / SenseOfBelonging] ; finding how much of an agent's sense of belonging is made up of its belonging to its family
    ifelse SenseOfBelonging = 0
          [set tribe-belonging-ratio tribe-belonging-ratio = 0]
          [set tribe-belonging-ratio tribe-belonging / SenseOfBelonging] ; finding how much of an agent's sense of belonging is made up of its belonging to its tribe
    ifelse SenseOfBelonging = 0
          [set culture-belonging-ratio culture-belonging-ratio = 0]
          [set culture-belonging-ratio culture-belonging / SenseOfBelonging] ; finding how much of an agent's sense of belonging is made up of its belonging to its culture
  ]

  BuildGT
  ;if Belonging_Threshold = true and Cooperation_Threshold = true [
  ;  show "Social Cohesion and Group Identity occured"
  ;]

  ;set _t1 timer
  ;show (word "everything else took " (_t1 - _t0) " seconds.")

  ;show ( word "A: " sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of people with [[tribe-label] of myTribe = "A"])
  ;show ( word "B: " sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of people with [[tribe-label] of myTribe = "B"])
  ;show ( word "C: " sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of people with [[tribe-label] of myTribe = "C"])
  ;show ( word "D: " sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of people with [[tribe-label] of myTribe = "D"])

  tick
end

;;;;;;;;;;;;;;;;;;;
;;    ANIMALS    ;;
;;;;;;;;;;;;;;;;;;;

to-report timeOfYear
  report ticks mod 365
end

to-report person-age ; Age in float and Tick is a day.
  report (ticks - birthTick) / 365.0
end

to animal-init ; initializing animals, shapes and time-steps of their birth
  set color [255 255 255 10]
  set shape one-of ["rabbit" "sheep" "cow"] ; Randomly choose an animal shape
  set birthTick ticks
end

to-report animal-foodYield ; setting specific food yields for each animal
  ;show word "shape: " shape
  if shape = "rabbit" [
    report 100 ; Rabbit has the lowest yield
  ]
  if shape = "sheep" [
    report 200 ; Sheep has an intermediate yield
  ]
  if shape = "cow" [
    report 300 ; Cow has the highest yield
  ]
end

to reproduceAnimals
  if (timeOfYear = Day_Animal_Birth and count animals < NUM_ANIMALS) [ ; if it's animal birth day and the number of animals is less than 5000
    let fertileAnimals animals with [person-age >= 1.5]  ; make a variable called fertileAnimals which holds animals with ages less than or equal to 1.5
    ; the following line ensures that the number of fertileAnimals does not exceed the number of animals missing and is as close to the number of fertileAnimals*Animal_Fertility as it can be
    ask n-of min (list (NUM_ANIMALS - count animals) (count fertileAnimals * Animal_Fertility)) fertileAnimals [ ; ask the item with the minimum value in the list to be the number of fertileAnimals. e.g. min (list(1000-800) (300*0.94)) => min (list(200) (282)) => 200
      ask patch-here [
        sprout-animals 2 [ animal-init ]
      ]
    ]
  ]
end

to moveAnimals
  ask n-of (count animals / 10) animals [ ; having a number of animals die if their age is above 9.5
    if (person-age > Age_Animal_Death) [
      die
    ]
    set heading 90 * random 4 ; having animals face random directions and move one step forward
    fd 1
  ]
end

;to updateAnimals
;end

;;;;;;;;;;;;;;;;;;
;;    GRAINS    ;;
;;;;;;;;;;;;;;;;;;

to grain-init ; initializing grain color, shape, food potential and state
  set color [100 100 100 0]
  set shape "plant"
  set foodPotential 1 + (random 10)
  set planted false
end

to grain-plant ; setup for planting a grain and setting its currentYield to the foodPotential times fertility of the patch it is on
  set planted true
  set currentYield foodPotential * [fertility] of patch-here
  set birthTick ticks
end

to grain-harvest ; setting up the state and color of grain when harvest occurs
  set planted false
  ;set foodPotential foodPotential + 1
  set color [255 255 0 0]
  ;ask patch-here [ set pcolor [100 100 0] ]
;  Put a grain nearby I guess.
;  if (random 100 > 80) [
;  ask one-of neighbors [
;    if (not any? grains-here) [
;      sprout-grains 1 [
;        grain-init
;        set planted false
;      ]
;    ]
;  ]
;  ]
end

to grain-spoil ; setting up state and color of grain when it spoils
  set planted false
  set color [255 255 0 0]
end

to person-cultivateLand  ; agent grain gathering on a patch increases its fertility by the cultivation rate
  ask patch-here [
    set fertility min (list (fertility * (1 + CULTIVATION_RATE)) 1 ) ; making sure the fertility doesn't go higher than 1
    let myColorFactor min (list 1 fertility) ; setting the patch color based on fertility (from 0 to 1)
    set pcolor scale-color green myColorFactor 0 1 ; scaling the level of patch green-ness based on the myColorFactor (from 0 not green to 1 most green)
  ]
end

; The idea is that agents start to take the grain in the winter when animals are scarce. This leads to planting in the spring.
to grain-grow
  set color (list 100 100 100 (grain-percent * 255)) ; set grain color based on growth percentage of the grain

  if (First_Feasible_Grain_Tick = "") [ ; first feasible grain appears if the grain food yield is equal or higher than grain feasibility threshold
    set First_Feasible_Grain_Tick ticks
    show (word First_Feasible_Grain_Tick ": First feasible grain (" xcor ", " ycor ")") ; else (if no estabished centers exist), First_Feasible_Grain_Tick is printed out
  ]

  if (grain-foodYield >= Grain_Feasibility_Threshold) [
    set currentYield foodPotential * [fertility] of patch-here ; letting the grains grow by increasing the foodPotential of the grain

    let establishedCenters (culturalCenters with [established = true]) ; a local variable called establishedCenters is created which holds cultural centers that are established
    ;show word "established centers: " establishedCenters
    if (any? establishedCenters) [ ; if any established centers exist, it is stored in the local variable closestCulturalCenter which holds the closest one to myself
      let closestCulturalCenter min-one-of establishedCenters [distance myself]
      if (First_Feasible_Grain_Distance_From_Cultural_Center = "") [
        set First_Feasible_Grain_Distance_From_Cultural_Center distance closestCulturalCenter ; then the first feasible grain distance from cultural center is set to the distance of the closest cultural center
        show (word First_Feasible_Grain_Tick ": First feasible grain (" xcor ", " ycor ") Distance from center " ([culture] of closestCulturalCenter) ": " First_Feasible_Grain_Distance_From_Cultural_Center)
        set shape "face happy" ;the smiley face shows the very first place that grain yield was higher than grain feasibility threshold
      ]
    ] ; the information grathered above is printed out
  ]
end

to updateGrain
  if (timeOfYear = Day_Grain_Spoiled) [ ; spoil grains when the Day_Grain_Spoiled arrives
    ask grains with [planted] [grain-spoil]
  ]

  if (timeOfYear = Day_Grain_Planting) [ ; let grain be planted when Day_Grain_Planting arrives
    ask patches with [fertility > 0] [ ; ask patches with fertility lower than 0
      if (random-float 1 < fertility) [ ; let grain sprout and initialization happen if a random generated float number up to 1 is lower than fertility and there are no grains on the patch
        if (not any? grains-here) [
          sprout-grains NUM_PATCH_GRAINS [
            grain-init
          ]
        ]
        ask grains-here with [planted = false ][ grain-plant ] ; plant grains if there are none on the patch
      ]
    ]
  ]

  ask grains with [ planted = true ] [ ; grow grain if it has already been planted
    grain-grow
  ]
end


to-report grain-percent ; reporting the precentage of planted (how far along in its growth process it is) grain using ticks, grain birthTick and Days_Grain_Maturity which occurs every 100 days
  if (not planted) [ report 0 ]
  ;report 1
  report min (list 1 ((ticks - birthTick) / Days_Grain_Maturity))
end

to-report grain-foodYield ; reporting the food yield of a grain using the grain-percent and foodPotential
  report grain-percent * foodPotential
end

; reporting the mean fertility of patches inside and outside the cultural centers for the plot on the interface
to-report meanFertilityInsideCulturalCenters
  if not any? culturalCenters with [established = true] [report 0]
  report mean [fertility] of patches with [inCulturalCenter = true]
end

to-report meanFertilityOutsideCulturalCenters
  if not any? culturalCenters with [established = true] [report 0]
  report mean [fertility] of patches with [inCulturalCenter = false]
end

;;;;;;;;;;;;;;;;;;
;;    AGENTS    ;;
;;;;;;;;;;;;;;;;;;

to person-init [newTribe myCulture] ; initializing each person (newTribe and myCulture are first mentioned here that's why they need to be in the bracket).
  set color gray
  set heading 0
  set myTribe newTribe
  set community myTribe
  set consumption 1 + (random 5)
  set potentialPartners []
  set HuntingScore 0
  Set GatheringScore 0
  Set HGscore 0
  set SimilarityScore 0
  set SenseOfBelonging 0
  set narrative-attachment n-values (length narratives) [precision random-float 1 2]
  set partnered 0
  set performed 0
  set cooperation 0
  set celebrating false
  set returning false
  set importance 1
  set tolerance INFLUENCE_RATE
  person-setCulture myCulture
  ;show (word "consumption: " consumption " agent: " self)
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;    AGENT MOVING    ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to-report person-distanceFromTribe ; distance of an agent from its tribe
  report distance community
end

to-report person-isScared ; when an agent is outside the tibe extent
  report person-distanceFromTribe > TRIBE_EXTENT * 1.5
end

to-report animal-isFood [myCommunity] ; to make sure an animal is a food for community both conditions in each of the lines below have to be true
  report (person-age > Age_Animal_Old and [food] of myCommunity < NUM_TRIBE_MEMBERS * 7) or
        (person-age > Age_Animal_Mature and [food] of myCommunity < NUM_TRIBE_MEMBERS * 3) or
        (person-age > Age_Animal_Edible and [food] of myCommunity < NUM_TRIBE_MEMBERS)
end

;to-report plant-isCommunityFood [myCommunity]
;  report [food] of myCommunity < count [members] of myCommunity
;end

to person-move
  let myperson self
  let thisTribe myTribe

  if (any? (animals-on patch-here) with [animal-isFood thisTribe]) [ ; if there are animals that are food on the patch the agent is on and ????? then stop
    stop
  ]

  ifelse person-isScared ; the agent is outside the tribe extent it will face the community
  [
    face community
  ]
  [ ; else inside the tribe extent
    let huntingTargets animals in-radius person_VISIBILITY with [animal-isFood thisTribe] ; find all animals that are considered hunting targets ones that are within the person_VISIBILITY (4) radius
    let grainTargets grains in-radius person_VISIBILITY with [grain-foodYield >= GRAIN_FEASIBILITY_THRESHOLD] ; find all plants that are considered grain targets within person_VISIBILITY (4) radius and with grain-foodYield larger or equal to GRAIN_FEASIBILITY_THRESHOLD

    let doHunt true ; set local variables doHunt and doGather to true if hunting and grain targets are found otherwise set them to false
    let doGather true

    if (not any? huntingTargets) [ set doHunt false ]
    if (not any? grainTargets) [ set doGather false ]

    let bestGrainTarget max-one-of grainTargets [grain-foodYield] ; bestGrainTarget holds one of the grain targets with the maximum grain food yield
    let bestHuntingTarget max-one-of huntingTargets [animal-foodYield] ; bestHuntingTarget holds one of the animal targets with the maximum animal food yield

    if (doHunt and doGather) [ ; if the grain yield of the best grain target is higher than the animal yield of the best hunting target, gather otherwise hunt
      ifelse ([grain-foodYield] of bestGrainTarget > [animal-foodYield] of bestHuntingTarget) [
        set doHunt false
        set doGather true
      ]
      [
        set doHunt true
        set doGather false
      ]
    ]

    if (doHunt) [ face bestHuntingTarget ] ; if hunting then have agent bestHuntingTarget
    if (doGather) [ ; if hunting and Cultivate_Land is true then have agent cultivate land and face bestGrainTarget
      if (Cultivate_Land) [ person-cultivateLand ]
      face bestGrainTarget
    ]

    if (not doHunt and not doGather) [ ; if not hunting or gathering, if Cultivate_Land is true then have agent cultivate land and move randomly
      if (Cultivate_Land) [ person-cultivateLand ]
      set heading 90 * random 4
    ]
  ]
  fd 1
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    AGENTS HUNTING, GATHERING AND EATING    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report sort-agentsets-by-HGscore [agentset-list] ; sorts the agentsets in the list by the sum of HGScore within each agentsets
  let sorted-list sort-by [[a1 a2] -> (precision (sum [HGscore] of a2) 4) >= (precision (sum [HGscore] of a1) 4) ] agentset-list
  report sorted-list
end


to hunt-gather
  ;;; <<<< create potential partners network for all people on the map >>>>>
  ask people [
    set potentialPartners []
  ]

;      show word "agentPresent" map [ [t] -> [who] of t ] sort agentsPresent
  ask people [
    let a self
;    let otherAgents other people-on patch-here
    let otherAgents other people in-radius animal_VISIBILITY
    ask otherAgents [
      let b self
      ifelse [shape] of a = [shape] of b ; checking the similarity based on family which grants 40% if true
        [set same-family 0.4]
        [set same-family 0]
      ifelse [myTribe] of a = [myTribe] of b ; checking the similarity based on tribe which grants 30% if true
        [set same-tribe 0.3]
        [set same-tribe 0]
      ifelse [color] of a = [color] of b ; checking the similarity based on culture which grants 30% if true
        [set same-culture 0.3]
        [set same-culture 0]
      set SimilarityScore same-family + same-tribe + same-culture ; getting the similarity score by adding the above percentages
      ifelse Festivals_Count = 0 ; preventing an error of performed divided by zero
        [set trustworthiness SimilarityScore]
        [set trustworthiness SimilarityScore + (performed / Festivals_Count)] ; a measure to check the in-group favoritism (SimilarityScore) and competncy (performed)
      if trustworthiness >= TRUST-LIMIT ; checking the agent trusworthiness score against the trusting score on the slider. the higher the TRUST-LIMIT, the less trusting the society is.
      [
        ask a [
          set potentialPartners fput b potentialPartners ; adding the potential partners of each agent to an agentset
          ;show word "potential partners: " potentialPartners
        ]
      ]
    ]
  ]

  ask people [ ; for each of the agents present, check if that agent exists in the other agents' potential partners list and form a link between them if they do
    let c self
;    let otherAgents other people-on patch-here
    let otherAgents other people in-radius animal_VISIBILITY
    ask otherAgents [
      let d self
      if member? c [potentialPartners] of d [
        create-link-with c
      if [shape] of c = [shape] of d ; increasing an agent's sense of belonging to its family when it has formed a link with a member of its family
        [set family-belonging family-belonging + 0.1]
      if [myTribe] of c = [myTribe] of d ; increasing an agent's sense of belonging to its tribe when it has formed a link with a member of its tribe
        [set tribe-belonging tribe-belonging + 0.1]
      if [color] of c = [color] of d ; increasing an agent's sense of belonging to its culture when it has formed a link with a member of its culture
        [set culture-belonging culture-belonging + 0.1]
      set SenseOfBelonging family-belonging + tribe-belonging + culture-belonging ; getting the overall sense of belonging for each agent
      ]
    ]
  ]

  nw:set-context people links ; create the cliques only using people
  let cliques nw:maximal-cliques ; A maximal clique is a clique that is not, itself, contained in a bigger clique. The result is reported as a list of agentsets, in random order.
  ;let cliques filter [clique -> all? clique [member? self people]] all_cliques ; checking to make sure all the members of the cliques are people.

  set Clique_Count length cliques ; calculating the number of clicks formed at each time-step

  ;show word "number of all cliques: " Clique_Count


  let partnered-cliques filter [clique -> (count clique) > 1] cliques ; find all clicks who have more than 1 member
  foreach partnered-cliques [ clique -> ; going through the members of each clique to see how many times they have been part of a clique
    ask clique [
      set partnered partnered + 1
    ]
  ]

  ;;; <<<< run hunting for every patch on the map >>>>>
  ask patches with [any? people-on self] [ ; only do hunt and gather in patches that people exist
    let thisPatch self

    if (any? animals-on thisPatch) [ ; to  hunt based on animal food yield, if there are any animals on this patch, make them a hunting target
      let huntingTargets animals-on thisPatch
      let agentsPresent people in-radius animal_VISIBILITY ; choose from a list of agents within the animal visibility (4) to hunt
      ;show (word "thisPatch: " thisPatch)
      ;show (word "huntingTargets: " count huntingTargets)
      ;show (word "agentsPresent: " count agentsPresent)

      let mostAnimalYield -1  ; Initialize with a value that is less than the minimum possible foodYield
      let bestAnimal nobody  ; Initialize as nobody

      foreach sort huntingTargets [ x ->   ; foreach needs a list not an agentset and sort huntingTargets returns a list of animals not an agentset
        if [animal-foodYield] of x > mostAnimalYield [ ; finding the animal with the most food yield from the available options to choose as the best animal
          set mostAnimalYield [animal-foodYield] of x
          set bestAnimal x
        ]
      ]
      ;show word "huntingTargets1: " huntingTargets
      let agentsRequired (mostAnimalYield / 100) ; number of agents required to hunt an animal based on its yield
                                                 ;show word "agentsRequired: " agentsRequired
      ;show (word "bestAnimal: " bestAnimal)
      ;show (word "mostAnimalYield: " mostAnimalYield)

      let presentCliques [] ; creating an empty list of cliques
      foreach cliques [ clique ->
        ask agentsPresent [
          let thisAgent self
          if member? thisAgent clique [ ; check to see if this agent is a member of the clique
            set presentCliques fput clique presentCliques ; if they are in the clique (condition is true), add this clique to the beginning of the presentCliques list
          ]
        ]
      ]

      ;show (word "this Patch" thisPatch)
      ;foreach presentCliques [pc ->
      ;  show (word "sum HGscore: " (sum [HGscore] of pc) )
      ;]

      let uniqueCliques remove-duplicates presentCliques ; dropping duplicate cliques that is present in the presentClique variable
      let sortedCliques sort-agentsets-by-HGscore uniqueCliques

      let foundBestClique false ; checking if the clique is large enough to meet the number of agents required to hunt the animal

      ;show (word "sortedCliques: " sortedCliques)

      foreach sortedCliques [ clique ->
        let foodAmount (mostAnimalYield / count clique)

        ;show (word "foodAmount: " foodAmount)

        if not foundBestClique and count clique >= agentsRequired [
          ask clique [ ; once the agentsPresent hunt, they gain a hunting score which is taken by dividing the food yield of the hunted animal by the number of agents who participated in the hunt
            set HuntingScore HuntingScore + foodAmount
            ;show (word "HuntingScore: " HuntingScore)

            let thisAgent self
            ;show word "HuntingScore:" HuntingScore
            ;show word "community in hunt: " community
            ask community [ ; to add the food of the hunted animal to the community stash, its yield is divided by the number of agents present to act as a fair sharing of the food
              ifelse (Festival_Time = true)[ ; making sure the food hunted by a top agent at the festival is added to the festival stash
                ifelse member? thisAgent top-festival-agents [
                  ifelse Monument-Established = true and member? self monuments ; making sure that the community of the agent is monument and not cultural center
                  [
                    set mon-hunted-food mon-hunted-food + foodAmount
                  ]
                  [
                    set cult-hunted-food cult-hunted-food + foodAmount
                    ;show (word "cult-hunted-food: " cult-hunted-food)
                  ]
                ]
                [
                  set tribe-hunted-food tribe-hunted-food + foodAmount
                  ;show (word "tribe-hunted-food: " tribe-hunted-food)
                ]
              ]
              [
                set tribe-hunted-food tribe-hunted-food + foodAmount
                ;show (word "tribe-hunted-food: " tribe-hunted-food)
              ]
              ;show (word "community: " self " food before: " food)
              set food food + foodAmount
              ;show (word "community: " self " food after: " food)
              ;show (word "food: " food)
              ;show (word "food after:" food)
            ]
          ]
          set foundBestClique true
        ]
      ]

      ask bestAnimal [ ; the hunted animal is now dead
        die
      ]
    ]

    if (any? ((grains-on thisPatch) with [grain-foodYield > 0])) [ ; to gather, if ther are any grains on this patch consider them as grain targets
                                       ;show count people-on patch-here
                                       ;show count grains-on patch-here
      ;let this-grains grains-on thisPatch
      ;let grown-grains filter [g -> [grain-foodYield] of g > 0] (sort this-grains)
      ask one-of (grains-on thisPatch) with [grain-foodYield > 0] [
        ;show word "self" self
        let grainYield [grain-foodYield] of self ; setting the local variable grainYield as grain-foodYield of this grain (self is grains here)

        ;show (word "grainYield: " grainYield)

        ask one-of people-on thisPatch [ ; one of the agents on the patch randomly gathers the grain (self is people here)
          ;show word "self" self
          ;show word "GatheringScore: " GatheringScore
          set GatheringScore GatheringScore + grainYield ; the yield of the gathered grain is added to the agent's gathering score
          ;show word "HGscore: " HGscore
          set HGscore HGscore + GatheringScore + HuntingScore ; Hunting and gathering scores added
          let thisAgent self
          ;show community
          ask community [
            ifelse (Festival_Time = true)[ ; making sure the food gathered by a top agent at the festival is added to the festival stash
                ifelse member? thisAgent top-festival-agents [
                  ifelse Monument-Established = true and member? self monuments ; making sure that the community of the agent is monument and not cultural center
                  [
                    set mon-gathered-food mon-gathered-food + grainYield
                  ]
                  [
                    set cult-gathered-food cult-gathered-food + grainYield
                  ]
                ]
                [
                  set tribe-gathered-food tribe-gathered-food + grainYield
                ]
            ]
            [
              set tribe-gathered-food tribe-gathered-food + grainYield
            ]

            set food food + grainYield ; gathered grain yield is added to the food in the tribe's stash
          ]
          ;show word "GatheringScore: " GatheringScore
          ;show word "HGscore: " HGscore
        ]
        grain-harvest
      ]
    ]
  ]

end

to person-eat
  let thisPerson self
  if (ticks - lastAte > 1) [ ; if the time-step an agent last ate minus the time-step it is at a given moment is more than 1 it will have to eat from the community food provided there is food available
    if [food] of community > 0 [
      ask community [
        set food food - [consumption] of thisPerson ; once the agent eats, the community food stash amount decreases and the agent's lastAte changes
      ]
      ask self [ set lastAte ticks ]
    ]
    if (ticks - lastAte > 14) [ die ] ; If an agent has not eaten in the last 14 time-steps it will die
  ]

end


;;;;;;;;;;;;;;;;;
;;    TRIBE    ;;
;;;;;;;;;;;;;;;;;

to spawnTribe [ tribeCenterX tribeCenterY tribeExtent tribeCulture tribeLabel] ; setting the parameters that the spawnTribe function will take
  ask spawnTribeAndReport tribeCenterX tribeCenterY tribeExtent tribeCulture tribeLabel []
end

to-report spawnTribeAndReport [ tribeCenterX tribeCenterY tribeExtent tribeCulture tribeLabel] ; creating tribes one by one using spawnTribe calle in Setup
  let thisTribe 0
  ask patch tribeCenterX tribeCenterY [
    sprout-tribes 1 [

      set startingPosition (list tribeCenterX tribeCenterY) ; initializing tribe variables
      set startingCulture tribeCulture ; startingCulture is the culture/belief the tribe starts out with
      set color colorForCulture startingCulture ; color of the agents in the tribe is the same as the color for their starting culture/belief
      set shape "house" ; centeral point of the tribe members (different from cultural centers)
      set thisTribe self
      set tribe-label tribeLabel ; which tribe an agent is in: A, B, C, D
      set food 10 ; some food in the tribe stash to begin
      set tribe-hunted-food 0 ; animals (yield) that has been hunted
      set tribe-gathered-food 0 ; grains (yield) that has been gathered
      tribe-spawnAgentsWithFamilies ; calling families in each tribe to be created
;      tribe-spawnAgents NUM_TRIBE_MEMBERS
    ]

    sprout-culturalCenters 1 ; creating and initializing a cultural center associated with each tribe
    [
      set shape "target"
      set color colorForCulture tribeCulture ; cultural center color is the same as the color for the tribe culture/belief it starts with and does not change even if all agents die
      set culture tribeCulture
      set established false
      ;ask thisTribe [ set culturalCenter self ]
    ]
  ]
  report thisTribe
end

to-report centroid [ tribePeople ] ; calculating the average position of the tribe people and reporting it as a list of two values: the mean x-coordinate and the mean y-coordinate.
  ifelse any? tribePeople [
    report (list mean [xcor] of tribePeople mean [ycor] of tribePeople )
  ]
  [ report [ 0 0 ] ]
end

to tribe-move

  if (any? members) [ ; to move the tribe allow the central point of the members (that are not returning) to be the new position not far from the starting position
    let myCentroid centroid members with [ community = myTribe and returning != true ]
    setxy item 0 myCentroid item 1 myCentroid ; the coordinates of the new position is the zero and one items within the myCentroid list
  ]

end

to tribe-spawnAgentsWithFamilies   ; creating agents in tribes. tribe who ID numbers are A=0, B=23, C=46, D=69
  let thisTribe self
  if (members = 0) [ set members no-turtles ] ; if there are no members
  let myMembers sort members ; myMembers is a local variable holding a sorted agentset of members
  let newCulture startingCulture ; make the culture of the agent the same as the starting culture of the tribe

  if (count members > 0) [ ; if there are members in the tribe
    set newCulture one-of modes [dominantCulture] of members ; make the culture of the agent one of the most common dominant cultures of the members
  ]

  let tribeArea patches in-radius TRIBE_EXTENT ; make the tribe area the patches within the tribe extent

  ; defines members of the first families within each tribe
  ask n-of 7 tribeArea [ ; create people one by one on 7 randomly chosen spots of the tribeArea
    sprout-people 1 [
      person-init thisTribe newCulture ; setting the tribe and culture of each agent
      set myMembers lput self myMembers ; setting the new created agent at the end of the myMembers list of agents
      (
        ifelse ; making 7 family members for each of the first families of every tribe
          ([tribe-label] of thisTribe = "A") [ set shape "default"]
          ([tribe-label] of thisTribe = "B") [ set shape "square"]
          ([tribe-label] of thisTribe = "C") [ set shape "circle"]
          ([tribe-label] of thisTribe = "D") [ set shape "hex"]
      )
    ]
  ]
  ; defines members of the second families within each tribe
  ask n-of 7 tribeArea [ ; create people one by one on 7 randomly chosen spots of the tribeArea
    sprout-people 1 [
      person-init thisTribe newCulture ; setting the tribe and culture of each agent
      set myMembers lput self myMembers ; setting the new created agent at the end of the myMembers list of agents
      (
        ifelse ; making 7 family members for each of the second families of every tribe
          ([tribe-label] of thisTribe = "A") [ set shape "triangle"]
          ([tribe-label] of thisTribe = "B") [ set shape "square 2"]
          ([tribe-label] of thisTribe = "C") [ set shape "circle 2"]
          ([tribe-label] of thisTribe = "D") [ set shape "pentagon"]
      )
    ]
  ]
  ; defines members of the third families within each tribe
  ask n-of 7 tribeArea [ ; create people one by one on 7 randomly chosen spots of the tribeArea
    sprout-people 1 [
      person-init thisTribe newCulture ; setting the tribe and culture of each agent
      set myMembers lput self myMembers ; setting the new created agent at the end of the myMembers list of agents
      (
        ifelse ; making 7 family members for each of the third families of every tribe
          ([tribe-label] of thisTribe = "A") [ set shape "triangle 2"]
          ([tribe-label] of thisTribe = "B") [ set shape "die 1"]
          ([tribe-label] of thisTribe = "C") [ set shape "wheel"]
          ([tribe-label] of thisTribe = "D") [ set shape "suit diamond"]
      )
    ]
  ]

  set members people with [member? self myMembers] ; this defines members as an agentset rather than a list of agents. update the agentset members with myMembers
end

to tribe-reproduce
  let surplus-tribes tribes with [food > sum [consumption] of members]
  let dying-tribes tribes with [count members < NUM_TRIBE_MEMBERS]

  if any? dying-tribes [
    let current-population count people
    let total-allowed-people NUM_TRIBE_MEMBERS * count tribes
    let num-people-to-add total-allowed-people - current-population

    let winner-tribe one-of surplus-tribes
    ask winner-tribe [
      let newCulture one-of modes [dominantCulture] of members

      let tribeArea patches in-radius TRIBE_EXTENT ; make the tribe area the patches within the tribe extent
      let myMembers sort members ; myMembers is a local variable holding a sorted agentset of members

      ask n-of num-people-to-add tribeArea [ ; create people one by one on 7 randomly chosen spots of the tribeArea
        ;show (word "new person is being added to tribe: " [tribe-label] of winner-tribe)
        sprout-people 1 [
          person-init winner-tribe newCulture ; setting the tribe and culture of each agent
          set myMembers lput self myMembers ; setting the new created agent at the end of the myMembers list of agents
          (
            ifelse ; making 7 family members for each of the first families of every tribe
            ([tribe-label] of winner-tribe = "A") [ set shape "default"]
            ([tribe-label] of winner-tribe = "B") [ set shape "square"]
            ([tribe-label] of winner-tribe = "C") [ set shape "circle"]
            ([tribe-label] of winner-tribe = "D") [ set shape "hex"]
          )
        ]
      ]

      set members people with [member? self myMembers] ; this defines members as an agentset rather than a list of agents. update the agentset members with myMembers
    ]
  ]

end

;to tribe-reproduce ; new agents being added to the tribe with food surplus to maintain the total number of agents in the model
;  if (food > sum [consumption] of members and count members < NUM_TRIBE_MEMBERS) [ ; if the current number of tribe members is lower than the food amount and the total number of members a tribe can have (21)
;    tribe-spawn-new-people (NUM_TRIBE_MEMBERS - count members) ; the number of agents that can be created would be the lowest number between the NUM_TRIBE_MEMBERS and the food value minus the current number of tribe members
;  ]
;end

to tribe-spawn-new-people [numpeople] ; process of adding the new people to a tribe
  let thisTribe self

  if (count members = 0) [ set members no-turtles ] ; if there are no members
  let myMembers sort members ; myMembers is a local variable holding a sorted agentset of members
  let newCulture startingCulture ; make the culture of the new agent the same as the starting culture of the tribe it appeared in

  if (count members > 0) [ ; if there are members in the tribe
    set newCulture one-of modes [dominantCulture] of members ; make the culture of the new agent one of the most common dominant cultures of the members
  ]

  let tribeArea patches in-radius TRIBE_EXTENT ; make the tribe area the patches within the tribe extent
  let overflow max (list 0 (numpeople - count tribeArea)) ; make the overflow the maximum value between zero and number of new people minus the number of patches in the tribe extent
  ask n-of (numpeople - overflow) tribeArea [ ; ask (numpeople - overflow) amount of tribe area to sprout a person in this tribe with its culture
    sprout-people 1 [
      person-init thisTribe newCulture
      set myMembers lput self myMembers ; setting the new created agent at the end of the myMembers list of agents
    ]
  ]
  set members people with [ member? self myMembers ] ; update the agentset members with myMembers
  if (overflow > 0) [ tribe-spawn-new-people overflow ] ; if overflow is more than 0 create as many new people as the number of overflow

end

;;;;;;;;;;;;;;;;;;;;;;;;;
;;    AGENT CULTURE    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

to-report person-getCulture
  report item 0 modes array:to-list culture ; reports what the item zero of the list holding most common culture is (red, yellow, orange, brown)
end

to person-setColor
  set color colorForCulture person-getCulture ; colorForCulture will be set to the color of the value provided by person-getCulture
end

to-report colorForCulture [ value ] ; value is the input provided to the procedure which is used as an index to select a color from the list
  report item value base-colors ; retrieving the item at position value from the base-colors list
end

to person-setCulture [ value ] ; setting agent culture by creating an array of length CULTURE_LENGTH where each element is initialized with the provided value
  set culture array:from-list n-values CULTURE_LENGTH [ value ] ; meaning the agent's culture as an array of the same value repeated CULTURE_LENGTH times
  set dominantCulture value ; Update dominantCulture
end

to-report person-getCultureTrait [ traitNum ] ; person-getCultureTrait takes an input traitNum and reports a specific trait value from the culture array based on the provided trait number
  report array:item culture (traitNum - 1) ; array:item function retrieving the item at position (traitNum - 1) from the culture array
end

to person-setCultureTrait [ value ] ; updating an agent's culture variable by adding a new value to the end of the array and push out the first/oldest culture memory.
  let index 0
  while [index < array:length culture - 1] [ ; loop will iterate as long as the index variable is less than the length of culture array minus
    array:set culture index array:item culture (index + 1) ; Inside the loop, it shifts the value at index + 1 to index moving each element of the culture array one position toward the beginning
    set index index + 1 ; incrementing index to move to the next element in the culture array
  ]
  array:set culture (array:length culture - 1) value ; After the loop, it sets the last element of the culture array (the most recent culture memory) to the value provided to the procedure
  set dominantCulture person-getCulture ; Updates the agent's dominantCulture variable to reflect the latest culture in their memory
end

to getCultureCount ; counting the number of agents within each culture
  let counter 0
  let cultureCount array:from-list n-values NUM_CULTURES [0] ; counting the culture by making an array the length of NUM_CULTURES (4) with zero as each element
  while [ counter < NUM_CULTURES ] [ ; looping while counter is less than the number of cultures (4)
    array:set cultureCount counter count people with [dominantCulture = (counter + 1)] ; setting the counter index of the cultureCount array to the number of people with dominantCulture that is (counter + 1)
    set counter counter + 1 ; incrementing the counter
  ]
  file-open "cultureCount.txt"
  file-write cultureCount
  file-close
end


to person-maybeAdoptCulture ; adopting culture from agents on one's patch or on the surrounding 8 patches
  let peopleOnSpace other people-on neighbors ; peopleOnSpace provides an agentset that contains other agents on a given agent's patch and its surrounding 8 neighbors
  if any? peopleOnSpace [ person-maybeAdoptCultureFrom peopleOnSpace ] ; if there are any agents here or surrounding, the agent can adopt its culture from them
end

to person-maybeAdoptCultureFrom [ otherpeople ] ; process of an agent adopting another's culture
  let possibleBelief [] ; Making a list of the beliefs that passed the 50/50 chance
  foreach sort-on [importance] otherpeople [ x ->  ; looping on a sorted list of the importance of otherpeople. importance is 1 for regulars.
    let counter 0
    while [ counter < [importance] of x ] [
      if random-float 1 < tolerance [ ; Each other agent on this space gets to try to convert this agent once, by a 50/50 chance.
        let traitNum item 0 modes array:to-list [culture] of x ; item 0 of mode = first most common item
        set possibleBelief lput traitNum possibleBelief ; adding traitNum (the belief of every agent) to the end of the possibleBelief list
      ]
      set counter counter + 1
    ]
  ] ; breaking tie by adding the agent's (that's being studied) belief
  if not empty? possibleBelief [  ; if the possibleBelief list is not empty
    ifelse length modes possibleBelief > 1 [ ; if the mode has 2 or more items
      set possibleBelief lput dominantCulture possibleBelief ; setting possibleBelief to the end of the dominantCulture array (agent memory)
      let adoptedBelief item 0 modes possibleBelief ; setting the adoptedBelief to be the most common item of the possibleBelief list
      person-setCultureTrait adoptedBelief ; updating person-setCultureTrait to adoptedBelief
    ] [
      let adoptedBelief item 0 modes possibleBelief ; else part of the ifelse
      person-setCultureTrait adoptedBelief
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    CULTURAL CENTER    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report unique-values [ mySet ]
  report remove-duplicates mySet ; removing all duplicate values from the mySet list to report unique-values
end


to-report find-argmax [vec]
  let max-val max vec ; Get the maximum value in the vector
  let max-index position max-val vec ; Find the index of the maximum value
  report max-index ; Report the index of the maximum value
end

; as the culture spreads outside the tribe the cultural center leaves the tribe’s boundary. When this happens, it is “established” and no longer moves
to culturalCenter-move
  let cultureMembers people with [dominantCulture = [culture] of myself]
  set members cultureMembers
  if (not established) [
    ifelse (any? cultureMembers) [ ; if there are cultureMembers, adjust the location of the cultural center using the coordinates of the agents
      let centroidX mean [xcor] of cultureMembers
      let centroidY mean [ycor] of cultureMembers
      set color colorForCulture culture
      setxy centroidX centroidY

      ;if (min [distance myself] of tribes > (TRIBE_EXTENT)) [ ; if the adjusted location of the tribe falls outside the tribe extent, the center is established and printed with the time-step
      ;  show (word ticks ": ESTABLISHED center " culture)
      ;  set established true
        ;ask n-of (count cultureMembers / 3) cultureMembers [ ; Leave some members here to act as guards maintaining the center
        ;  person-goToCulturalCenter myself
        ;]
      ;]
    ]
    [
      set color black
    ]
  ]
end

to establish-cultural-center ; cultural centers are established when the tribes that they originated from have 100 times the amount of food they need to sustain their members
  ;show (word self " consumption: " sum [consumption] of people with [myTribe = myself])
  let food-threshold 100 * sum [consumption] of people with [myTribe = myself]

  if food >= food-threshold
  [
    let tribe-startingCulture startingCulture
    let my-cultural-center one-of culturalCenters with [culture = tribe-startingCulture]
    if [established] of my-cultural-center = false [
      ask my-cultural-center
      [
        show (word ticks ": ESTABLISHED center " culture)
        set established true
        ask patches with [distance myself <= TRIBE_EXTENT * 1.5] ; making sure patches within the tribe extent and buffer are set to inCulturalCenter
        [
          set inCulturalCenter true
        ]
      ]
    ]
  ]
end

to person-goToCulturalCenter [cultCent count-agents] ; agents preparing to go to the cultural center and taking food
  let foodToBring [food] of [myTribe] of self / count-agents ; the amount of food to take will be determined by dividing the food of tribe stash by the number of tribe members
  ask cultCent [ ; adding food amount to the cultural center stash
    set food food + foodToBring
  ]
  ask myTribe [ ; subtracting food amount from the tribe stash
    set food food - foodToBring
  ]
  set community cultCent ; set the agent community from its tribe to the cultural center for the period it is at the center
end


to person-goToMonument [numToSelect] ; agents preparing to go to the monument and taking food
  let foodToBring [food] of [myTribe] of self / numToSelect ; the amount of food to take will be determined by dividing the food of tribe stash by the number of tribe members
  ask monuments [ ; adding food amount to the monument stash
    set food food + foodToBring
  ]
  ask myTribe [ ; subtracting food amount from the tribe stash
    set food food - foodToBring
  ]
  set community monuments ; set the agent community from its tribe to the monument for the period it is at the monument
end


to performFestival ; process of topAgents going to the cultural center to perform festival and coming back
  ;show word "day of the year: " timeOfYear
  if (timeOfYear >= Day_Festival_Start and timeOfYear < Day_Festival_End) [
    set Festival_Time true
    let all-cultures [dominantCulture] of people ; Extract cultures from all people [orange orange red ... orange yellow]
    let distinct-cultures remove-duplicates sort all-cultures ; Find distinct cultures [orange red yellow]

    if (timeOfYear = Day_Festival_Start) [
      set Festivals_Count Festivals_Count + 1 ; counting how many times festivals have been held at each cultural center
      foreach distinct-cultures [ x -> ; selecting the top agents of each culture that is established based on their HGscores to attend the festival
        let this-cultural-center one-of culturalCenters with [culture = x] ; select the culturalCenter object that has the culture "x"
        if [established] of this-cultural-center = true [ ; if this cultural center is established, then start selecting people for the festival
          let sortedAgents sort-on [HGscore] people with [dominantCulture = x] ; Sort the agents within each culture by HGscores in descending order
                                                                               ;show word "sortedAgents: " sortedAgents
          let numToSelect ceiling (0.2 * length sortedAgents)  ; Calculate the number of agents to select (top 20%)

          table:put FestivalAttendees x numToSelect ; create a key-value pair in the FestivalAttendees dictionary, key is a culture and value is the numToSelect for that culture

          let topAgents sublist sortedAgents 0 numToSelect   ; Select the top 20% of agents based on HGscores

          set top-festival-agents sentence top-festival-agents topAgents ; reassigning the top-festival-agents to topAgents

          ask people with [member? self topAgents] [
            let thisTribe [myTribe] of self
            let number-of-people-in-tribe count people with [myTribe = thisTribe]

            ;show word "topAgents: " topAgents
            ifelse (Monument-Established = true) ; if the monument is established, have the top agents go there for the festival, otherwise go to their cultural centers
            [
              let current-monument one-of monuments ; have the top agents go to the monument
              person-goToMonument number-of-people-in-tribe
              set community current-monument
              set celebrating true
            ]
            [
              let cultCent one-of culturalCenters with [culture = [dominantCulture] of myself] ; have the top agents go to the cultural center of their dominantCulture
              if ([established] of cultCent) [
                person-goToCulturalCenter cultCent number-of-people-in-tribe
                set community cultCent
                set celebrating true
              ]
            ]
          ]

          let festival-narratives [] ; vector holding each agent's narrative with the highest narrative attachment
          ask people with [member? self topAgents] [
            set performed performed + 1 ; a counter to report how many times an agent has attended the performance at the cultural center
            set culture-belonging culture-belonging + 0.1 ; increasing the sense of belonging to culture when an agent has performed
            let index find-argmax narrative-attachment ; getting the index of the highest value in the narrative-attachment vector
            let bestNarrative item index narratives ; finding the item with the same index in the narrative array
            set festival-narratives fput bestNarrative festival-narratives ; adding every agent's best narrative to the festival narratives vector
          ]
          ask people with [member? self topAgents] [
            foreach festival-narratives [ y -> ; going through each item in the festival narrative vector
              let index position y narratives ; getting the first position of the item in the narratives list. basically what is the narratives vector index of the item we are looping on each time.
              let current-value item index narrative-attachment ; checking what the current value in the given index is
              set narrative-attachment replace-item index narrative-attachment (current-value + 0.05) ; increasing the value of the given narrative attachment by 0.05
            ]
          ]
        ]
      ]
    ]
  ]

  if (timeOfYear = Day_Festival_End) [ ; festival ends after 100 days
    set Festival_Time false
    ;Clear the cultural center's members.
    ask culturalCenters [ ; checking if the length of the unique values of the myTribe property among the members agentset is equal to one
      let culturalCenter_culture [culture] of self ; saving the cultural center of each agent in the variable culturalCenter_culture
      let numPeopleWithinCulture count people with [culture = culturalCenter_culture] ; getting the number of people within each culture
      if numPeopleWithinCulture > 0 [ ; running the rest of the festival code would require the number of agents in each culture to be more than zero
        if length unique-values [myTribe] of members = 1 [ set established false ]  ; If the length of unique tribe values is equal to 1 (meaning all members belong to the same tribe), it sets the agent's established property to false
        let culturalCenterFood food ; account for the food accumulated at the cultural center

        let numToSelect table:get FestivalAttendees [culture] of self ; get the numToSelect value for the current culture from the FestivalAttendees dictionary
        ask members with [celebrating = true][
          set celebrating false
          if (not Build_Centers or random 100 < 60) [ ; if not staying to build the centers (setting off for now)
            set returning true
            set community myTribe ;Set the member's community back to be their tribe
            ask community [ set food food + culturalCenterFood / numToSelect ] ; divide the cultural center food stash by the number of members and add it to the community/tribe food
          ]
        ]
      ]
      set food 0 ; setting the cultural center's food stash to zero
    ]

    ask people [
       set community myTribe
    ]

    set top-festival-agents [] ; empty the top-festival-agents list
    set FestivalAttendees table:make ; makes a dictionary for each festival attendee
  ]

  ask people with [ returning = true ] [
    if (distance myTribe < TRIBE_EXTENT) [ set returning false ] ; set returning to false if the distance between the agent (myself) and its myTribe (the tribe to which it belongs) is less than the value of TRIBE_EXTENT
  ] ; meaning if the agent is within the tribe extent it is considered returned
end


;;;;;;;;;;;;;;;;;;;;;
;;    BUILDING     ;;
;;;;;;;;;;;;;;;;;;;;;


to-report sort-table [myTable]
  let keyValueList (table:to-list myTable) ; Convert the table to a list of key-value pairs
  let sortedList sort-by [[pair1 pair2] -> last pair1 > last pair2] keyValueList ; Sort the list based on values (descending order)
  let sortedTable table:from-list sortedList ; Convert the sorted list back to a table
  report sortedTable ; Report the sorted table
end


to BuildGT
   let Average_Cooperation mean [cooperation] of people ; getting the average cooperation of the people
   let high-cooperating count people with [cooperation >= Average_Cooperation] ; to get the majority, we check how many people have higher cooperation than average
   ifelse high-cooperating >=  (count people / 2) ; if the cooperation of the majority of the agents is more than or equal to the average cooperation set the cooperation threshold to true
          [set Cooperation_Threshold true]
          [set Cooperation_Threshold false]

   let Average_Belonging mean [SenseOfBelonging] of people ; getting the average sense of belonging of the people
   let high-belonging count people with [SenseOfBelonging >= Average_Belonging] ; to get the majority, we check how many people have higher sense of belonging than average
   ifelse high-belonging >=  (count people / 2) ; if the sense of belonging of the majority of the agents is more than or equal to the average sense of belonging set the belonging threshold to true
          [set Belonging_Threshold true]
          [set Belonging_Threshold false]
   ;show (word "tick: " ticks " Belonging_Threshold: " Belonging_Threshold " Cooperation_Threshold: " Cooperation_Threshold)
   ;show (word "tick: " ticks " high-belonging: " high-belonging " high-cooperating: " high-cooperating)

   ; only run the following code (establishing the monument) if the monument has not been established and the sense of belonging and cooperation thresholds are true and the tick is higher than the start of the festival
   if (Cooperation_Threshold = true and Belonging_Threshold = true and Monument-Established = false and ticks > Day_Festival_Start)[

    show (word "tick: (" ticks "): Social Cohesion and Group Identity occured")

    let possibleBuilders sort-by [[a1 a2] -> (([cooperation] of a2) >= ([cooperation] of a1)) and (([SenseOfBelonging] of a2) >= ([SenseOfBelonging] of a1))] people ; Sort the agents by highest cooperation and or sense of belonging scores in descending order

    let numToSelect ceiling (0.2 * length possibleBuilders)  ; Calculate the number of agents to select (top 20%)

    let topBuilders sublist possibleBuilders 0 numToSelect   ; Select the top 20% of agents based on cooperation and sense of belonging scores

    let topFamilies remove-duplicates [shape] of people with [member? self topBuilders]  ; finding the families of the top builders and avoiding duplicates

    let familyScores table:make
    foreach topFamilies [ x -> ; getting the sum score of the cooperation and sense of belonging for each family
      let familyMembers people with [shape = x] ; agentset of agents with the shape of x
      let overallScore sum [cooperation] of familyMembers + sum [SenseOfBelonging] of familyMembers
      table:put familyScores x overallScore ; create a key-value pair in the familyScores dictionary, key is a family and value is the overallScore for that family
    ]

    let sortedFamilies sort-table familyScores ; Sort the families by scoreValue in descending order

    let selectedFamilies ceiling (0.2 * length (table:to-list sortedFamilies))  ; Calculate the number of families to select (top 20%)

    let familiesList (table:to-list sortedFamilies) ; Convert the table to a list of key-value pairs

    let familiesSublist sublist familiesList 0 selectedFamilies   ; get a sublist of the familiesList

    let buildingFamilies map first familiesSublist ; Select the top 20% of families based on cooperation and sense of belonging scores as the bulding families

    let builders filter [i -> member? ([shape] of i) buildingFamilies] (sort people) ; using filter to find the agents with the buildingFamilies shape (sort is used to convert people from agentset to list per filter requirment)
    set builders people with [member? self builders]; convert list to agentset

    let centerX mean [xcor] of builders ; getting the x and y coordinates of each agent in the builders list
    let centerY mean [ycor] of builders
    ask patch centerX centerY [ ; creating the GT monument from the cental point of the agents in the builders list
      sprout-monuments 1 [ ; initializing Gobekli Tepe as a monument
        set shape "building institution"
        set size 3
        set color blue
        setxy centerX centerY
        set food 0
        set mon-hunted-food 0
        set mon-gathered-food 0
      ]
    ]
    set Monument-Established true
   ]

end


;;;;;;;;;;;;;;;;;;;;;;;
;;    EXPERIMENTS    ;;
;;;;;;;;;;;;;;;;;;;;;;;

to-report tribe-hunting-proportion [input-tribe] ; reporter for BehaviorSpace to experiment on the hunting proportion of each tribe
  ifelse count tribes with [tribe-label = input-tribe] > 0 [
    let hunt-food item 0 [tribe-hunted-food] of tribes with [tribe-label = input-tribe]
    let gathered-food item 0 [tribe-gathered-food] of tribes with [tribe-label = input-tribe]
    let total-food hunt-food + gathered-food
    ifelse total-food = 0
      [report 0]
      [report hunt-food / total-food]
  ]
  [report 0]
end

to-report tribe-gathering-proportion [input-tribe] ; reporter for BehaviorSpace to experiment on the gathering proportion of each tribe
  ifelse count tribes with [tribe-label = input-tribe] > 0 [
    let hunt-food item 0 [tribe-hunted-food] of tribes with [tribe-label = input-tribe]
    let gathered-food item 0 [tribe-gathered-food] of tribes with [tribe-label = input-tribe]
    let total-food hunt-food + gathered-food
    ifelse total-food = 0
      [report 0]
      [report gathered-food / total-food]
  ]
  [report 0]
end

to-report cult-hunting-proportion [input-culture] ; reporter for BehaviorSpace to experiment on the hunting proportion of each culture
  ifelse count culturalCenters with [color = input-culture] > 0 [
    let hunt-food item 0 [cult-hunted-food] of culturalCenters with [color = input-culture]
    let gathered-food item 0 [cult-gathered-food] of culturalCenters with [color = input-culture]
    let total-food hunt-food + gathered-food
    ifelse total-food = 0
      [report 0]
      [report hunt-food / total-food]
  ]
  [report 0]
end

to-report cult-gathering-proportion [input-culture] ; reporter for BehaviorSpace to experiment on the gathering proportion of each culture
  ifelse count culturalCenters with [color = input-culture] > 0 [
    let hunt-food item 0 [cult-hunted-food] of culturalCenters with [color = input-culture]
    let gathered-food item 0 [cult-gathered-food] of culturalCenters with [color = input-culture]
    let total-food hunt-food + gathered-food
    ifelse total-food = 0
      [report 0]
      [report gathered-food / total-food]
  ]
  [report 0]
end

to-report average-distance-in-tribe [input-tribe-label]
  let tribe-agents people with [[tribe-label] of myTribe = input-tribe-label]

  ifelse any? tribe-agents [
    let total-distance 0
    let total-pairs 0

    foreach sort tribe-agents [ agent1 -> ; Nested loops to calculate distances between all pairs of agents
      foreach sort tribe-agents [ agent2 ->
        if agent1 != agent2 [
          let this-distance [distance agent1] of agent2
          set total-distance total-distance + this-distance
          set total-pairs total-pairs + 1
        ]
      ]
    ]
    ifelse total-pairs > 0 [ ; Calculate the average distance
      report total-distance / total-pairs
    ]
    [
      report 0 ; Avoid division by zero if there are no pairs
    ]
  ]
  [
    report 0 ; No agents in the tribe
  ]
end

to-report average-distance-in-culture [input-culture]
  let culture-agents people with [color = input-culture]

  ifelse any? culture-agents [
    let total-distance 0
    let total-pairs 0

    foreach sort culture-agents [ agent1 -> ; Nested loops to calculate distances between all pairs of agents
      foreach sort culture-agents [ agent2 ->
        if agent1 != agent2 [
          let this-distance [distance agent1] of agent2
          set total-distance total-distance + this-distance
          set total-pairs total-pairs + 1
        ]
      ]
    ]
    ifelse total-pairs > 0 [ ; Calculate the average distance
      report total-distance / total-pairs
    ]
    [
      report 0 ; Avoid division by zero if there are no pairs
    ]
  ]
  [
    report 0 ; No agents in the tribe
  ]
end

to-report SNA-ID
  report [who] of people
end

to-report SNA-location
  report [patch-here] of people
end

to-report SNA-neighbors
  report [neighbors] of people
end

to-report SNA-culture
  report [culture] of people
end


to collector ; organizing and saving the data to a file
  file-open "/Users/niloofarjebelli/Desktop/plot/BP__P21__NPG5__CR0_1__GFT5__T1/GT_SNA-21.json"
  let data "{"
  set data (word data "\"time\":\"" ticks "\"")
  set data (word data ",\"data\":[")
  ask people [
    set data (word data "{\"id\":\"" who "\",")
    set data (word data "\"xcor\":\"" xcor "\"," "\"ycor\":\"" ycor "\",")
    set data (word data "\"neighbors\":\"" [[who] of people-here] of neighbors "\"")
    set data (word data ",")
    set data (word data "\"culture\":\"" array:to-list culture "\"")
    set data (word data ",")
    set data (word data "\"dominant\":\"" dominantCulture "\"")
    set data (word data "},")
  ]
  set data remove-item (length data - 1) data
  set data (word data "]}\r")
  file-print data
  file-close
end


; setting the interface plot for each of the cultures
to setupCulturePlot
  set-current-plot "Population of Cultures"

  let counter 1
  while [ counter <= NUM_CULTURES ] [
    set-current-plot "Population of Cultures"
    create-temporary-plot-pen (word counter)
    set-current-plot-pen (word counter)
    set-plot-pen-color colorForCulture counter
;    add-plot-pen-legend counter (item (counter - 1) colorNames)
    set counter counter + 1
  ]

end

to plotCultures
  let counter 1
  while [ counter <= NUM_CULTURES ] [
    set-current-plot-pen (word counter)
    plot count people with [dominantCulture = counter] ; plotting the number of agents whose dominant culture is the same as the counter variable
    set counter counter + 1
  ]
end

; measures how much nodes tend to cluster together in the network in general. It is defined based on the types of triplets in the network.
; A triplet consists of a central node and two of its neighbors. If its neighbors are also connected, it’s a closed triplet. If its neighbors are not connected, it’s an open triplet.
; The global clustering coefficient is simply the number of closed triplets in a network divided by the total number of triplets.


;to-report tribe-global-clustering-coefficient [input-tribe-label]
;  let closed-triplets sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of people with [[tribe-label] of myTribe = input-tribe-label]
;  let triplets sum [ count my-links * (count my-links - 1) ] of people with [[tribe-label] of myTribe = input-tribe-label]
;  ifelse triplets = 0
;  [report 0]
;  [report closed-triplets / triplets]
;end


to-report tribe-average-local-clustering-coefficient [input-tribe-label] ; The average local clustering coefficient is another popular method for measuring the amount of clustering in the network as a whole.
  nw:set-context people links
  let tribe-members people with [[tribe-label] of myTribe = input-tribe-label]
  ifelse count tribe-members = 0
  [report 0]
  [
    let local-clustering mean [ nw:clustering-coefficient ] of tribe-members
    report local-clustering
  ]
end

;to-report tribe-transitivity [input-tribe-label] ; The average local clustering coefficient is another popular method for measuring the amount of clustering in the network as a whole.
;  nw:set-context people links
;  let tribe-members people with [[tribe-label] of myTribe = input-tribe-label]
;  ifelse count tribe-members = 0
;  [report 0]
;  [
;    let tribe-people people with [[tribe-label] of myTribe = input-tribe-label]
;    let closed-triplets sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of tribe-people
;    let n count tribe-people
;    let total-possible-triplets n * (n - 1 ) * (n - 2) / 6
;    report 3 * closed-triplets / total-possible-triplets
;  ]
;end

to-report tribe-modularity
  nw:set-context people links
  let modularity 0
  let pair-counts 0

  foreach [tribe-label] of tribes [ l1 ->
    foreach [tribe-label] of tribes [ l2 ->
      if l1 != l2 [
        if count people with [ [tribe-label] of myTribe = l1 ] > 0 and count people with [ [tribe-label] of myTribe = l2 ] > 0 [
          let score nw:modularity (list (people with [ [tribe-label] of myTribe = l1 ]) (people with [ [tribe-label] of myTribe = l2 ]))
          if (score <= 0) or (score >= 0) [
            set modularity modularity + score
            set pair-counts pair-counts + 1
          ]
        ]
      ]
    ]
  ]
  ifelse pair-counts = 0
    [report 0]
    [report modularity / pair-counts]
end

to-report single-tribe-modularity [input-tribe]
  nw:set-context people links
  let modularity 0
  let pair-counts 0

  foreach [tribe-label] of tribes [ l2 ->
    if input-tribe != l2 [
      if count people with [ [tribe-label] of myTribe = input-tribe ] > 0 and count people with [ [tribe-label] of myTribe = l2 ] > 0 [
        let score nw:modularity (list (people with [ [tribe-label] of myTribe = input-tribe ]) (people with [ [tribe-label] of myTribe = l2 ]))
        if (score <= 0) or (score >= 0) [
          set modularity modularity + score
          set pair-counts pair-counts + 1
        ]
      ]
    ]
  ]
  ifelse pair-counts = 0
    [report 0]
    [report modularity / pair-counts]
end


to-report cult-average-local-clustering-coefficient [input-cult-label] ; The average local clustering coefficient is another popular method for measuring the amount of clustering in the network as a whole.
  nw:set-context people links
  let cult-members people with [color = input-cult-label]
  ifelse count cult-members = 0
  [report 0]
  [
    let local-clustering mean [ nw:clustering-coefficient ] of cult-members
    report local-clustering
  ]
end


to-report culture-modularity
  nw:set-context people links
  let modularity 0
  let pair-counts 0

  foreach [color] of culturalCenters [ l1 ->
    foreach [color] of culturalCenters [ l2 ->
      if l1 != l2 [
        if count people with [ color = l1 ] > 0 and count people with [ color = l2 ] > 0 [
          let score nw:modularity (list (people with [ color = l1 ]) (people with [ color = l2 ]))
          if (score <= 0) or (score >= 0) [
            set modularity modularity + score
            set pair-counts pair-counts + 1
          ]
        ]
      ]
    ]
  ]
  ifelse pair-counts = 0
    [report 0]
    [report modularity / pair-counts]
end

to-report single-culture-modularity [input-culture]
  nw:set-context people links
  let modularity 0
  let pair-counts 0

  foreach [color] of culturalCenters [ l2 ->
    if input-culture != l2 [
      if count people with [ color = input-culture ] > 0 and count people with [ color = l2 ] > 0 [
        let score nw:modularity (list (people with [ color = input-culture ]) (people with [ color = l2 ]))
        if (score <= 0) or (score >= 0) [
          set modularity modularity + score
          set pair-counts pair-counts + 1
        ]
      ]
    ]
  ]
  ifelse pair-counts = 0
    [report 0]
    [report modularity / pair-counts]
end


;to-report cult-global-clustering-coefficient [input-cult-label]
;  let closed-triplets sum [ nw:clustering-coefficient * count my-links * (count my-links - 1) ] of people with [color = input-cult-label]
;  let triplets sum [ count my-links * (count my-links - 1) ] of people with [color = input-cult-label]
;  ifelse triplets = 0
;  [report 0]
;  [report closed-triplets / triplets]
;end




to-report narrative-attachment-cultures [input-culture input-narrative]
  let cult-members people with [color = input-culture]
  ifelse count cult-members = 0
  [report 0]
  [
    let index position input-narrative narratives ; getting the index of each item in the narratives list
    let cult-narrative-attachment sum [item index narrative-attachment] of cult-members ; getting the value of the item with the same index in the narrative-attachment list
    report cult-narrative-attachment
  ]
end

to-report narrative-attachment-tribes [input-tribe input-narrative]
  let tribe-members people with [[tribe-label] of myTribe = input-tribe]
  ifelse count tribe-members = 0
  [report 0]
  [
    let index position input-narrative narratives ; getting the index of each item in the narratives list
    let tribe-narrative-attachment sum [item index narrative-attachment] of tribe-members ; getting the value of the item with the same index in the narrative-attachment list
    report tribe-narrative-attachment
  ]
end

to-report narrative-attachment-monument [input-narrative]
  let mon-members people with [community = one-of monuments]
  ifelse count mon-members = 0
  [report 0]
  [
    let index position input-narrative narratives ; getting the index of each item in the narratives list
    let mon-narrative-attachment sum [item index narrative-attachment] of mon-members ; getting the value of the item with the same index in the narrative-attachment list
    report mon-narrative-attachment
  ]
end


;;;;;;;;;;;;;;;;;;;;;
;;    UTILITIES    ;;
;;;;;;;;;;;;;;;;;;;;;

; utilities used in multiple sections of the code or in the interface
to-report interpolateColor [ col factor ]
  let myRGB extract-rgb col
  report (rgb (item 0 myRGB * factor) (item 1 myRGB * factor) (item 2 myRGB * factor))
end

to-report histogram-table [ mySet ]
  let result table:make
  foreach mySet [ x ->
    ; Add the key to the table
    if not table:has-key? result x [
      table:put result x 0
    ]
    ; Add to the count
    table:put result x (table:get result x) + 1
  ]
  report result
end

to writeOut [string]
  set Debug_Output (word Debug_Output "\n" string)
  show string
end
@#$#@#$#@
GRAPHICS-WINDOW
234
63
1423
551
-1
-1
11.7
1
10
1
1
1
0
0
0
1
-50
50
-20
20
0
0
1
ticks
30.0

BUTTON
19
11
82
44
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
89
11
152
44
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
18
63
214
183
Population of Cultures
Days
People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

PLOT
13
463
213
593
Animals
Days
Animals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Rabbit" 1.0 0 -7858858 true "" "plot count turtles with [shape = \"rabbit\"]"
"Sheep" 1.0 0 -15302303 true "" "plot count turtles with [shape = \"sheep\"]"
"Cow" 1.0 0 -14454117 true "" "plot count turtles with [shape = \"cow\"]"

MONITOR
166
10
251
55
Festival Time
Festival_Time
17
1
11

PLOT
14
329
214
456
Food of Tribes
Days
Food
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "if (count tribes > 0) [plot [food] of item 0 sort tribes]"
"B" 1.0 0 -10141563 true "" "if (count tribes > 0) [plot [food] of item 1 sort tribes]"
"C" 1.0 0 -14835848 true "" "if (count tribes > 0) [plot [food] of item 2 sort tribes]"
"D" 1.0 0 -8053223 true "" "if (count tribes > 0) [plot [food] of item 3 sort tribes]"

PLOT
476
557
811
707
Average Fertility Around Cultural Centers
Days
Fertility
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"In" 1.0 0 -13345367 true "" "plot meanFertilityInsideCulturalCenters"
"Out" 1.0 0 -4699768 true "" "plot meanFertilityOutsideCulturalCenters"

SLIDER
1103
10
1341
43
GRAIN_FEASIBILITY_THRESHOLD
GRAIN_FEASIBILITY_THRESHOLD
0
10
5.0
.01
1
NIL
HORIZONTAL

PLOT
14
191
215
322
Population of Tribes
Days
People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot count turtles with [member? shape [\"default\" \"triangle\" \"triangle 2\"]]"
"B" 1.0 0 -8630108 true "" "plot count turtles with [member? shape [\"square\" \"square 2\" \"die 1\"]]"
"C" 1.0 0 -14835848 true "" "plot count turtles with [member? shape [\"circle\" \"circle 2\" \"wheel\"]]"
"D" 1.0 0 -5298144 true "" "plot count turtles with [member? shape [\"hex\" \"pentagon\" \"suit diamond\"]]"

SLIDER
639
10
762
43
TRUST-LIMIT
TRUST-LIMIT
0
2
1.0
0.1
1
NIL
HORIZONTAL

MONITOR
256
10
393
55
Cooperation Threshold
Cooperation_Threshold
17
1
11

MONITOR
396
10
518
55
Belonging Threshold
Belonging_Threshold
17
1
11

PLOT
13
598
212
730
Grains
Days
Grains
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14439633 true "" "plot count grains"

PLOT
477
847
811
995
Planted vs. Harvested Grains
Days
Grains
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"P" 1.0 0 -14439633 true "" "plot count grains with [planted = true]"
"H" 1.0 0 -8431303 true "" "plot count grains with [planted = false]"

PLOT
815
557
1035
717
Hunting vs. Gathering Tribe A
Days
Ratio
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"H" 1.0 0 -5298144 true "plot tribe-hunting-proportion \"A\"" "plot tribe-hunting-proportion \"A\""
"G" 1.0 0 -14439633 true "plot tribe-gathering-proportion \"A\"" "plot tribe-gathering-proportion \"A\""

PLOT
477
712
637
843
Average Fertility
Days
Fertility
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14439633 true "" "plot mean [fertility] of patches"

PLOT
640
712
810
843
Average Grain Food Yield
Days
Fertility
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14070903 true "ifelse count grains > 0 [ plot mean [grain-foodYield] of grains ] [plot 0]" "ifelse count grains > 0 [ plot mean [grain-foodYield] of grains ] [plot 0]"

SLIDER
930
10
1097
43
CULTIVATION_RATE
CULTIVATION_RATE
0.01
0.2
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
767
10
923
43
NUM_PATCH_GRAINS
NUM_PATCH_GRAINS
1
10
5.0
1
1
NIL
HORIZONTAL

PLOT
1042
558
1265
719
Hunting vs. Gathering Tribe B
Days
Ratio
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"H" 1.0 0 -5298144 true "" "plot tribe-hunting-proportion \"B\""
"G" 1.0 0 -14439633 true "" "plot tribe-gathering-proportion \"A\""

PLOT
816
721
1036
881
Hunting vs. Gathering Tribe C
Days
Ratio
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"H" 1.0 0 -5298144 true "" "plot tribe-hunting-proportion \"C\""
"G" 1.0 0 -14439633 true "" "plot tribe-gathering-proportion \"C\""

PLOT
1042
723
1267
881
Hunting vs. Gathering Tribe D
Days
Ratio
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"H" 1.0 0 -5298144 true "" "plot tribe-hunting-proportion \"D\""
"G" 1.0 0 -14439633 true "" "plot tribe-gathering-proportion \"D\""

PLOT
215
557
473
709
Average Agent Distance in Tribes
Days
Distance
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot average-distance-in-tribe \"A\""
"B" 1.0 0 -10141563 true "" "plot average-distance-in-tribe \"B\""
"C" 1.0 0 -15302303 true "" "plot average-distance-in-tribe \"C\""
"D" 1.0 0 -8053223 true "" "plot average-distance-in-tribe \"D\""

PLOT
1271
557
1535
718
Hunting vs. Gathering Culture Orange
Days
Ratio
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"H" 1.0 0 -5298144 true "" "plot cult-hunting-proportion orange"
"G" 1.0 0 -14439633 true "" "plot cult-gathering-proportion orange"

PLOT
1273
724
1536
880
Hunting vs. Gathering Culture Red
Days
Ratio
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"H" 1.0 0 -5298144 true "" "plot cult-hunting-proportion red"
"G" 1.0 0 -14439633 true "" "plot cult-gathering-proportion red"

PLOT
1540
556
1798
716
Hunting vs. Gathering Culture Brown
Days
Ratio
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"H" 1.0 0 -5298144 true "" "plot cult-hunting-proportion brown"
"G" 1.0 0 -14439633 true "" "plot cult-gathering-proportion brown"

PLOT
1541
722
1802
879
Hunting vs. Gathering Culture Yellow
Days
Ratio
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"H" 1.0 0 -5298144 true "" "plot cult-hunting-proportion yellow"
"G" 1.0 0 -14439633 true "" "plot cult-gathering-proportion brown"

PLOT
12
734
211
884
Number of Cliques
Days
Cliques
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot Clique_Count"

MONITOR
521
10
634
55
Total Cooperation
Total_Cooperation
17
1
11

PLOT
214
713
474
874
Average Agent Distance in Cultures
Days
Distance
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"1" 1.0 0 -2674135 true "" "plot average-distance-in-culture red"
"2" 1.0 0 -955883 true "" "plot average-distance-in-culture orange"
"3" 1.0 0 -8431303 true "" "plot average-distance-in-culture brown"
"4" 1.0 0 -1184463 true "" "plot average-distance-in-culture yellow"

PLOT
11
888
211
1044
Average Sense of Belonging
Days
Belonging
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "ifelse count people > 0 [plot mean [SenseOfBelonging] of people] [plot 0]" "ifelse count people > 0 [plot mean [SenseOfBelonging] of people] [plot 0]"

PLOT
216
877
473
1043
Average Cooperation
Days
Cooperation
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "ifelse count people > 0 [plot mean [cooperation] of people] [plot 0]"

PLOT
10
1050
236
1205
Sense of Belonging
Days
Value
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Ave" 1.0 0 -16777216 true "" "plot count people with [SenseOfBelonging > mean [SenseOfBelonging] of people]"
"1/2" 1.0 0 -5298144 true "" "plot count people / 2"

PLOT
242
1050
472
1205
Cooperation
Days
Value
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Ave" 1.0 0 -16777216 true "" "plot count people with [cooperation > mean [cooperation] of people]"
"1/2" 1.0 0 -8053223 true "" "plot count people / 2"

PLOT
10
1212
407
1362
Trust and Cooperation Tribe A
Days
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Ave Local" 1.0 0 -5298144 true "plot tribe-average-local-clustering-coefficient \"A\"" "plot tribe-average-local-clustering-coefficient \"A\""
"Modularity" 1.0 0 -7500403 true "plot single-tribe-modularity \"A\"" "plot single-tribe-modularity \"A\""

PLOT
817
885
1121
1055
Narrative Attachments Orange Culture
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-cultures orange \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-cultures orange \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-cultures orange \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-cultures orange \"D\""
"E" 1.0 0 -14835848 true "" "plot narrative-attachment-cultures orange \"E\""

PLOT
818
1060
1122
1220
Narrative Attachments Red Culture
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-cultures red \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-cultures red \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-cultures red \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-cultures red \"D\""
"E" 1.0 0 -15302303 true "" "plot narrative-attachment-cultures red \"E\""

PLOT
1125
885
1432
1054
Narrative Attachments Brown Culture
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-cultures brown \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-cultures brown \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-cultures brown \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-cultures brown \"D\""
"E" 1.0 0 -15302303 true "" "plot narrative-attachment-cultures brown \"E\""

PLOT
1126
1060
1433
1220
Narrative Attachments Yellow Culture
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-cultures yellow \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-cultures yellow \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-cultures yellow \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-cultures yellow \"D\""
"E" 1.0 0 -15302303 true "" "plot narrative-attachment-cultures yellow \"E\""

PLOT
478
1037
812
1206
Narrative Attachments Monument
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-monument \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-monument \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-monument \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-monument \"D\""
"E" 1.0 0 -15302303 true "" "plot narrative-attachment-monument \"E\""

PLOT
818
1226
1122
1379
Narrative Attachments Tribe A
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-tribes \"A\" \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-tribes \"A\" \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-tribes \"A\" \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-tribes \"A\" \"D\""
"E" 1.0 0 -15302303 true "" "plot narrative-attachment-tribes \"A\" \"E\""

PLOT
1128
1226
1434
1379
Narrative Attachments Tribe B
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-tribes \"B\" \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-tribes \"B\" \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-tribes \"B\" \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-tribes \"B\" \"D\""
"E" 1.0 0 -15302303 true "" "plot narrative-attachment-tribes \"B\" \"E\""

PLOT
818
1385
1122
1546
Narrative Attachments Tribe C
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-tribes \"C\" \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-tribes \"C\" \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-tribes \"C\" \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-tribes \"C\" \"D\""
"E" 1.0 0 -15302303 true "" "plot narrative-attachment-tribes \"C\" \"E\""

PLOT
1128
1385
1435
1545
Narrative Attachments Tribe D
Days
Attachment
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" "plot narrative-attachment-tribes \"D\" \"A\""
"B" 1.0 0 -5298144 true "" "plot narrative-attachment-tribes \"D\" \"B\""
"C" 1.0 0 -6459832 true "" "plot narrative-attachment-tribes \"D\" \"C\""
"D" 1.0 0 -13345367 true "" "plot narrative-attachment-tribes \"D\" \"D\""
"E" 1.0 0 -15302303 true "" "plot narrative-attachment-tribes \"D\" \"E\""

PLOT
413
1212
812
1363
Trust and Cooperation Tribe B
Days
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Ave Local" 1.0 0 -5298144 true "" "plot tribe-average-local-clustering-coefficient \"B\""
"Modularity" 1.0 0 -7500403 true "plot single-tribe-modularity \"B\"" "plot single-tribe-modularity \"B\""

PLOT
10
1369
407
1528
Trust and Cooperation Tribe C
Days
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Ave Local" 1.0 0 -5298144 true "" "plot tribe-average-local-clustering-coefficient \"C\""
"Modularity" 1.0 0 -7500403 true "plot single-tribe-modularity \"C\"" "plot single-tribe-modularity \"C\""

PLOT
414
1369
813
1528
Trust and Cooperation Tribe D
Days
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Ave Local" 1.0 0 -5298144 true "" "plot tribe-average-local-clustering-coefficient \"D\""
"Modularity" 1.0 0 -7500403 true "plot single-tribe-modularity \"D\"" "plot single-tribe-modularity \"D\""

PLOT
10
1535
408
1692
Trust and Cooperation Orange Culture
Days
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Ave Local" 1.0 0 -5298144 true "" "plot cult-average-local-clustering-coefficient orange"
"Modularity" 1.0 0 -7500403 true "plot single-culture-modularity orange" "plot single-culture-modularity orange"

PLOT
415
1535
812
1692
Trust and Cooperation Red Culture
Days
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Ave Local" 1.0 0 -5298144 true "" "plot cult-average-local-clustering-coefficient red"
"Modularity" 1.0 0 -7500403 true "plot single-culture-modularity red" "plot single-culture-modularity red"

PLOT
10
1699
407
1856
Trust and Cooperation Brown Culture
Days
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Ave Local" 1.0 0 -5298144 true "" "plot cult-average-local-clustering-coefficient brown"
"Modularity" 1.0 0 -7500403 true "plot single-culture-modularity brown" "plot single-culture-modularity brown"

PLOT
415
1699
811
1856
Trust and Cooperation Yellow Culture
Days
Value
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Ave Local" 1.0 0 -5298144 true "" "plot cult-average-local-clustering-coefficient yellow"
"Modularity" 1.0 0 -7500403 true "plot single-culture-modularity yellow" "plot single-culture-modularity yellow"

PLOT
819
1554
1434
1710
Modularity
Days
Modularity
0.0
10.0
0.0
0.5
true
true
"" ""
PENS
"Tribe" 1.0 0 -13791810 true "plot tribe-modularity" "plot tribe-modularity"
"Culture" 1.0 0 -5825686 true "" "plot culture-modularity"

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

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

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

die 1
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 129 129 42

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

hex
false
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270

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

rabbit
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

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

sheep 2
false
0
Polygon -7500403 true true 209 183 194 198 179 198 164 183 164 174 149 183 89 183 74 168 59 198 44 198 29 185 43 151 28 121 44 91 59 80 89 80 164 95 194 80 254 65 269 80 284 125 269 140 239 125 224 153 209 168
Rectangle -7500403 true true 180 195 195 225
Rectangle -7500403 true true 45 195 60 225
Rectangle -16777216 true false 180 225 195 240
Rectangle -16777216 true false 45 225 60 240
Polygon -7500403 true true 245 60 250 72 240 78 225 63 230 51
Polygon -7500403 true true 25 72 40 80 42 98 22 91
Line -16777216 false 270 137 251 122
Line -16777216 false 266 90 254 90

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

suit diamond
false
0
Polygon -7500403 true true 150 15 45 150 150 285 255 150

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
  <experiment name="Hunting vs. Gathering" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5500"/>
    <metric>count people with [[tribe-label] of myTribe = "A"]</metric>
    <metric>count people with [[tribe-label] of myTribe = "B"]</metric>
    <metric>count people with [[tribe-label] of myTribe = "C"]</metric>
    <metric>count people with [[tribe-label] of myTribe = "D"]</metric>
    <metric>count people with [color = orange]</metric>
    <metric>count people with [color = red]</metric>
    <metric>count people with [color = brown]</metric>
    <metric>count people with [color = yellow]</metric>
    <metric>tribe-hunting-proportion "A"</metric>
    <metric>tribe-hunting-proportion "B"</metric>
    <metric>tribe-hunting-proportion "C"</metric>
    <metric>tribe-hunting-proportion "D"</metric>
    <metric>tribe-gathering-proportion "A"</metric>
    <metric>tribe-gathering-proportion "B"</metric>
    <metric>tribe-gathering-proportion "C"</metric>
    <metric>tribe-gathering-proportion "D"</metric>
    <metric>cult-hunting-proportion orange</metric>
    <metric>cult-hunting-proportion red</metric>
    <metric>cult-hunting-proportion brown</metric>
    <metric>cult-hunting-proportion yellow</metric>
    <metric>cult-gathering-proportion orange</metric>
    <metric>cult-gathering-proportion red</metric>
    <metric>cult-gathering-proportion brown</metric>
    <metric>cult-gathering-proportion yellow</metric>
    <metric>average-distance-in-tribe "A"</metric>
    <metric>average-distance-in-tribe "B"</metric>
    <metric>average-distance-in-tribe "C"</metric>
    <metric>average-distance-in-tribe "D"</metric>
    <metric>average-distance-in-culture orange</metric>
    <metric>average-distance-in-culture red</metric>
    <metric>average-distance-in-culture brown</metric>
    <metric>average-distance-in-culture yellow</metric>
    <enumeratedValueSet variable="GRAIN_FEASIBILITY_THRESHOLD">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NUM_PATCH_GRAINS">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TRUST-LIMIT">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CULTIVATION_RATE">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Trust and Cooperation Building" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5500"/>
    <metric>tribe-modularity</metric>
    <metric>culture-modularity</metric>
    <metric>single-tribe-modularity "A"</metric>
    <metric>single-tribe-modularity "B"</metric>
    <metric>single-tribe-modularity "C"</metric>
    <metric>single-tribe-modularity "D"</metric>
    <metric>tribe-average-local-clustering-coefficient "A"</metric>
    <metric>tribe-average-local-clustering-coefficient "B"</metric>
    <metric>tribe-average-local-clustering-coefficient "C"</metric>
    <metric>tribe-average-local-clustering-coefficient "D"</metric>
    <metric>single-culture-modularity orange</metric>
    <metric>single-culture-modularity red</metric>
    <metric>single-culture-modularity brown</metric>
    <metric>single-culture-modularity yellow</metric>
    <metric>cult-average-local-clustering-coefficient orange</metric>
    <metric>cult-average-local-clustering-coefficient red</metric>
    <metric>cult-average-local-clustering-coefficient brown</metric>
    <metric>cult-average-local-clustering-coefficient yellow</metric>
    <enumeratedValueSet variable="GRAIN_FEASIBILITY_THRESHOLD">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NUM_PATCH_GRAINS">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TRUST-LIMIT">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CULTIVATION_RATE">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Universal Narrative Development" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5500"/>
    <metric>narrative-attachment-cultures orange "A"</metric>
    <metric>narrative-attachment-cultures orange "B"</metric>
    <metric>narrative-attachment-cultures orange "C"</metric>
    <metric>narrative-attachment-cultures orange "D"</metric>
    <metric>narrative-attachment-cultures orange "E"</metric>
    <metric>narrative-attachment-cultures red "A"</metric>
    <metric>narrative-attachment-cultures red "B"</metric>
    <metric>narrative-attachment-cultures red "C"</metric>
    <metric>narrative-attachment-cultures red "D"</metric>
    <metric>narrative-attachment-cultures red "E"</metric>
    <metric>narrative-attachment-cultures brown "A"</metric>
    <metric>narrative-attachment-cultures brown "B"</metric>
    <metric>narrative-attachment-cultures brown "C"</metric>
    <metric>narrative-attachment-cultures brown "D"</metric>
    <metric>narrative-attachment-cultures brown "E"</metric>
    <metric>narrative-attachment-cultures yellow "A"</metric>
    <metric>narrative-attachment-cultures yellow "B"</metric>
    <metric>narrative-attachment-cultures yellow "C"</metric>
    <metric>narrative-attachment-cultures yellow "D"</metric>
    <metric>narrative-attachment-cultures yellow "E"</metric>
    <metric>narrative-attachment-tribes "A" "A"</metric>
    <metric>narrative-attachment-tribes "A" "B"</metric>
    <metric>narrative-attachment-tribes "A" "C"</metric>
    <metric>narrative-attachment-tribes "A" "D"</metric>
    <metric>narrative-attachment-tribes "A" "E"</metric>
    <metric>narrative-attachment-tribes "B" "A"</metric>
    <metric>narrative-attachment-tribes "B" "B"</metric>
    <metric>narrative-attachment-tribes "B" "C"</metric>
    <metric>narrative-attachment-tribes "B" "D"</metric>
    <metric>narrative-attachment-tribes "B" "E"</metric>
    <metric>narrative-attachment-tribes "C" "A"</metric>
    <metric>narrative-attachment-tribes "C" "B"</metric>
    <metric>narrative-attachment-tribes "C" "C"</metric>
    <metric>narrative-attachment-tribes "C" "D"</metric>
    <metric>narrative-attachment-tribes "C" "E"</metric>
    <metric>narrative-attachment-tribes "D" "A"</metric>
    <metric>narrative-attachment-tribes "D" "B"</metric>
    <metric>narrative-attachment-tribes "D" "C"</metric>
    <metric>narrative-attachment-tribes "D" "D"</metric>
    <metric>narrative-attachment-tribes "D" "E"</metric>
    <metric>narrative-attachment-monument "A"</metric>
    <metric>narrative-attachment-monument "B"</metric>
    <metric>narrative-attachment-monument "C"</metric>
    <metric>narrative-attachment-monument "D"</metric>
    <metric>narrative-attachment-monument "E"</metric>
    <enumeratedValueSet variable="GRAIN_FEASIBILITY_THRESHOLD">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NUM_PATCH_GRAINS">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TRUST-LIMIT">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CULTIVATION_RATE">
      <value value="0.1"/>
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
