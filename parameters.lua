RestartState = "savegame.state"

ButtonNames = { "A", "B", "Up", "Down", "Left", "Right" }

ViewArea = 6
TileSize = 16
InputSize = (ViewArea * 2 + 1) * (ViewArea * 2 + 1)

Inputs = InputSize + 1
Outputs = #ButtonNames

-- NN
Population = 350
DeltaDisjoint = 2.0
DeltaWeights = 0.4
DeltaThreshold = 1.0

StaleSpecies = 15

-- GA/ES
MutateConnectionsChance = 0.25
PerturbChance = 0.90
CrossoverChance = 0.75
LinkMutationChance = 2.0
NodeMutationChance = 0.50
BiasMutationChance = 0.40
StepSize = 0.1
DisableMutationChance = 0.4
EnableMutationChance = 0.2

IterationsBeforeOneFithAdaption = 1
Mode = {}
Mode["GA"] = false
Mode["ES"] = true

-- Misc
TimeoutConstant = 20
MaxNodes = 1000000

UsedActivationFunction = "relu"

ActFunc = {}
ActFunc["sigmoid"] = function (x) return 1 / (1 + math.exp(-x)) end
ActFunc["relu"] = function (x) return math.max(0, x) end
ActFunc["sigmoid2"] = function(x) return 2 / (1 + math.exp(-4.9 * x)) - 1 end