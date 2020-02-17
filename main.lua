require("parameters")

require("emu")

require("neat")

require("crossover")
require("mutate")
require("fitness")

require("misc")
require("jsonWrapper")

Savestate = Split(RestartState, "([A-Za-z]*)")[1]
Jwrap = JsonWrapper:create()
os.execute("rm *.json")
os.execute("del *.json")

if Mode["GA"] == Mode["ES"] then
	print("Modes must have different values.")
	os.exit()
end

if Mode["GA"] then
	print("Running NEAT with GA...")
else
	print("Running NEAT with ES...")
end

if Population < IterationsBeforeOneFithAdaption then
	IterationsBeforeOneFithAdaption = Population
	print("Iterations before one-fifth rule is adapted is set to populations size.")
end

if Pool == nil then
	InitializePool()
end

Timeout = 0
Rightmost = 0

event.onexit(onExit)

Form = forms.newform(350, 160, "__--~**'' SuperLua ''**~--__")
MaxFitnessLabel = forms.label(Form, "Max Fitness: " .. math.floor(Pool.maxFitness), 5, 10)
forms.button(Form, "Restart", InitializePool, 105, 5)
forms.button(Form, "Save", SavePool, 180, 5)
forms.button(Form, "Load", LoadPool, 255, 5)
forms.button(Form, "Current best", PlayTop, 5, 35)
forms.label(Form, "Save file:", 5, 70, 40)
forms.label(Form, "Load file:", 5, 90, 40)
SaveFile = forms.textbox(Form, Savestate .. ".json", 200, 25, nil, 115, 65)
LoadFile = forms.textbox(Form, "", 200, 25, nil, 115, 90)
HideOverlay = forms.checkbox(Form, "Hide overlay", 90, 35)
forms.setproperty(HideOverlay, "Checked", true)

while true do
	local backgroundColor = 0xD0FFFFFF
	if not forms.ischecked(HideOverlay) then
		gui.drawBox(0, 5, 300, 40, backgroundColor, backgroundColor)
	end

	local species = Pool.species[Pool.currentSpecies]
	local genome = species.genomes[Pool.currentGenome]

	if Pool.currentFrame%5 == 0 then
		EvaluateCurrent()
	end

	joypad.set(Controller)

	GetCharPos()
	if Char.x > Rightmost then
		Rightmost = Char.x
		Timeout = TimeoutConstant
	end

	Timeout = Timeout - 1

	local timeoutBonus = Pool.currentFrame / 4
	if Timeout + timeoutBonus <= 0 then
		local fitness = Rightmost - Pool.currentFrame / 2
		if Rightmost > 3186 then
			fitness = fitness + 1000
		elseif fitness == 0 then
			fitness = -1
		end
		genome.fitness = fitness

		if fitness > Pool.maxFitness then
			Pool.maxFitness = fitness
			forms.settext(MaxFitnessLabel, "Max Fitness: " .. math.floor(Pool.maxFitness))
			print("Write current best pool to file...")
			print("Current best fitness -> Gen. " .. Pool.generation .. " Spec. " .. Pool.currentSpecies .. " Genome " .. Pool.currentGenome .. " Fitness: " .. fitness)
			SavePool("best_gen#" .. Pool.generation .. "_f#" .. fitness .. "_" .. forms.gettext(SaveFile))
		else
			print("Gen. " .. Pool.generation .. " Spec. " .. Pool.currentSpecies .. " Genome " .. Pool.currentGenome .. " Fitness: " .. fitness)
		end

		Pool.currentSpecies = 1
		Pool.currentGenome = 1
		while FitnessAlreadyMeasured() do
			NextGenome()
		end
		InitializeRun()
	end

	local measured = 0
	local total = 0
	for _, species in pairs(Pool.species) do
		for _, genome in pairs(species.genomes) do
			total = total + 1
			if genome.fitness ~= 0 then
				measured = measured + 1
			end
		end
	end
	if not forms.ischecked(HideOverlay) then
		gui.drawText(0, 10, "Gen. " .. Pool.generation .. "  - Spec. " .. Pool.currentSpecies .. " - Genome " .. Pool.currentGenome .. " - " .. math.floor(measured/total*100) .. "%", 0xFF000000, 11, "Arial Black")
		gui.drawText(0, 22, "Fitness: " .. math.floor(Rightmost - (Pool.currentFrame) / 2 - (Timeout + timeoutBonus)*2/3), 0xFF000000, 11, "Arial Black")
		gui.drawText(100, 22, "Max Fitness: " .. math.floor(Pool.maxFitness), 0xFF000000, 11, "Arial Black")
	end

	Pool.currentFrame = Pool.currentFrame + 1

	emu.frameadvance();
end