function EvaluateNetwork(network, inputs)
	table.insert(inputs, 1)
	if #inputs ~= Inputs then
		print("Incorrect number of neural network inputs.")
		return {}
	end

	for i = 1, Inputs do
		network.neurons[i].value = inputs[i]
	end

	for _, neuron in pairs(network.neurons) do
		local sum = 0
		for j = 1, #neuron.incoming do
			local incoming = neuron.incoming[j]
			local other = network.neurons[incoming.input]
			sum = sum + incoming.weight * other.value
		end

		if #neuron.incoming > 0 then
			neuron.value = ActFunc[UsedActivationFunction](sum)
		end
	end

	local outputs = {}
	for o = 1, Outputs do
		local button = "P1 " .. ButtonNames[o]
		if network.neurons[MaxNodes + o].value > 0 then
			outputs[button] = true
		else
			outputs[button] = false
		end
	end

	return outputs
end

function EvaluateCurrent()
	local species = Pool.species[Pool.currentSpecies]
	local genome = species.genomes[Pool.currentGenome]

	inputs = GetInputs()
	Controller = EvaluateNetwork(genome.network, inputs)

	if Controller["P1 Left"] and Controller["P1 Right"] then
		Controller["P1 Left"] = false
		Controller["P1 Right"] = false
	end
	if Controller["P1 Up"] and Controller["P1 Down"] then
		Controller["P1 Up"] = false
		Controller["P1 Down"] = false
	end

	joypad.set(Controller)
end

function FitnessAlreadyMeasured()
	local species = Pool.species[Pool.currentSpecies]
	local genome = species.genomes[Pool.currentGenome]
	return genome.fitness ~= 0
end

function RankGlobally()
	local global = {}
	for s = 1, #Pool.species do
		local species = Pool.species[s]
		for g = 1, #species.genomes do
			table.insert(global, species.genomes[g])
		end
	end
	table.sort(global, function (a, b) return (a.fitness < b.fitness) end)

	for g = 1, #global do
		global[g].globalRank = g
	end
end

function CalculateAverageFitness(species)
	local total = 0

	for g = 1, #species.genomes do
		local genome = species.genomes[g]
		total = total + genome.globalRank
	end

	species.averageFitness = total / #species.genomes
end

function TotalAverageFitness()
	local total = 0
	for s = 1, #Pool.species do
		local species = Pool.species[s]
		total = total + species.averageFitness
	end

	return total
end

function CullSpecies(cutToOne)
	for s = 1, #Pool.species do
		local species = Pool.species[s]

		table.sort(species.genomes, function (a, b) return (a.fitness > b.fitness) end)

		local remaining = math.ceil(#species.genomes / 2)
		if cutToOne then
			remaining = 1
		end
		while #species.genomes > remaining do
			table.remove(species.genomes)
		end
	end
end

function RemoveStaleSpecies()
	local survived = {}

	for s = 1, #Pool.species do
		local species = Pool.species[s]

		table.sort(species.genomes, function (a, b) return (a.fitness > b.fitness) end)

		if species.genomes[1].fitness > species.topFitness then
			species.topFitness = species.genomes[1].fitness
			species.staleness = 0
		else
			species.staleness = species.staleness + 1
		end
		if species.staleness < StaleSpecies or species.topFitness >= Pool.maxFitness then
			table.insert(survived, species)
		end
	end
	Pool.species = survived
end

function RemoveWeakSpecies()
	local survived = {}

	local sum = TotalAverageFitness()
	for s = 1, #Pool.species do
		local species = Pool.species[s]
		local breed = math.floor(species.averageFitness / sum * Population)
		if breed >= 1 then
			table.insert(survived, species)
		end
	end
	Pool.species = survived
end