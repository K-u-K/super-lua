function InitializePool()
	print("Initialize pool...")
	Pool = CreatePool()

	for i = 1, Population do
		AddToSpecies(BasicGenome())
	end

	InitializeRun()
end

function InitializeRun()
	savestate.load(RestartState);
	Rightmost = 0
	Pool.currentFrame = 0
	Timeout = TimeoutConstant
	ClearJoypad()

	local species = Pool.species[Pool.currentSpecies]
	local genome = species.genomes[Pool.currentGenome]
	GenerateNetwork(genome)
	EvaluateCurrent()
end

function ClearJoypad()
	Controller = {}
	for b = 1, #ButtonNames do
		Controller["P1 " .. ButtonNames[b]] = false
	end
	joypad.set(Controller)
end

function DeepCopy(obj)
	if type(obj) ~= 'table' then return obj end
	local res = setmetatable({}, getmetatable(obj))
	for k, v in pairs(obj) do res[DeepCopy(k)] = DeepCopy(v) end
	return res
end

function Split(val, delimiter)
	local res = {}
	local i = 1
	for tmp in val:gmatch(delimiter) do
		res[i] = tmp
		i = i + 1
	end
	return res
end

function SavePool(filename)
	filename = filename or forms.gettext(SaveLoadFile)
	local pool = DeepCopy(Pool)
	for i = 1, #pool.species do
		for k = 1, #pool.species[i].genomes do
			pool.species[i].genomes[k].network = {}
		end
	end

	JsonWrapper.writeToFile(pool, filename)
end

function LoadPool(filename)
	print("Load file pool...")
	filename = filename or forms.gettext(SaveLoadFile)
	Pool = JsonWrapper.readFromFile(filename)

	if Pool ~= nil then
		while FitnessAlreadyMeasured() do
			NextGenome()
		end
		InitializeRun()
		Pool.currentFrame = Pool.currentFrame + 1
	end
end

function PlayTop()
	local maxfitness = 0
	local maxs, maxg
	for s, species in pairs(Pool.species) do
		for g, genome in pairs(species.genomes) do
			if genome.fitness > maxfitness then
				maxfitness = genome.fitness
				maxs = s
				maxg = g
			end
		end
	end

	Pool.currentSpecies = maxs
	Pool.currentGenome = maxg
	Pool.maxFitness = maxfitness
	forms.settext(MaxFitnessLabel, "Max Fitness: " .. math.floor(Pool.maxFitness))
	print("<>------- Running top genome -------<>")
	InitializeRun()
	Pool.currentFrame = Pool.currentFrame + 1
	return
end

function OnExit()
	forms.destroy(form)
end