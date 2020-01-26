function CreatePool()
	local pool 			= {}
	pool.species 		= {}
	pool.generation 	= 0
	pool.innovation 	= Outputs
	pool.currentSpecies = 1
	pool.currentGenome 	= 1
	pool.currentFrame 	= 0
	pool.maxFitness 	= 0
	return pool
end

function CreateSpecies()
	local species 			= {}
	species.topFitness 		= 0
	species.staleness 		= 0
	species.genomes 		= {}
	species.averageFitness 	= 0
	return species
end

function CreateGenome()
	local genome 	= {}
	genome.genes 	= {}
	genome.fitness 	= 0
	genome.adjustedFitness 	= 0
	genome.network 		  	= {}
	genome.maxneuron 		= 0
	genome.globalRank 		= 0
	genome.mutationRates 	= {}
	genome.mutationCount 	= {}
	genome.mutationIter 	= 0
	genome.mutationRates["connections"] = MutateConnectionsChance
	genome.mutationCount["connections"] = 0
	genome.mutationRates["link"] 		= LinkMutationChance
	genome.mutationCount["link"] 		= 0
	genome.mutationRates["bias"] 		= BiasMutationChance
	genome.mutationCount["bias"] 		= 0
	genome.mutationRates["node"] 		= NodeMutationChance
	genome.mutationCount["node"] 		= 0
	genome.mutationRates["enable"] 		= EnableMutationChance
	genome.mutationCount["enable"] 		= 0
	genome.mutationRates["disable"] 	= DisableMutationChance
	genome.mutationCount["disable"] 	= 0
	genome.mutationRates["step"] 		= StepSize
	return genome
end

function CreateGene()
	local gene 		= {}
	gene.input 		= 0
	gene.output 	= 0
	gene.weight 	= 0.0
	gene.enabled 	= true
	gene.innovation = 0
	return gene
end

function CopyGene(gene)
	local gene2 = CreateGene()
	gene2 		= DeepCopy(gene)
	return gene2
end

function CreateNeuron()
	local neuron 	= {}
	neuron.incoming = {}
	neuron.value 	= 0.0
	return neuron
end

function BasicGenome()
	local genome = CreateGenome()
	genome.maxneuron = Inputs
	Mutate(genome)
	return genome
end

function CopyGenome(genome)
	local genome2 = CreateGenome()
	for g = 1, #genome.genes do
		table.insert(genome2.genes, CopyGene(genome.genes[g]))
	end
	genome2.maxneuron	  = genome.maxneuron
	genome2.mutationIter  = genome.mutationIter
	genome2.mutationRates = DeepCopy(genome.mutationRates)
	genome2.mutationCount = DeepCopy(genome.mutationCount)
	return genome2
end

function GenerateNetwork(genome)
	local network = {}
	network.neurons = {}

	for i = 1, Inputs do
		network.neurons[i] = CreateNeuron()
	end

	for o = 1, Outputs do
		network.neurons[MaxNodes + o] = CreateNeuron()
	end

	table.sort(genome.genes, function (a, b) return (a.output < b.output) end)
	for i = 1, #genome.genes do
		local gene = genome.genes[i]
		if gene.enabled then
			if network.neurons[gene.output] == nil then
				network.neurons[gene.output] = CreateNeuron()
			end
			local neuron = network.neurons[gene.output]
			table.insert(neuron.incoming, gene)
			if network.neurons[gene.input] == nil then
				network.neurons[gene.input] = CreateNeuron()
			end
		end
	end
	genome.network = network
end

function NewGeneration()
	CullSpecies(false) -- Cull the bottom half of each species (reduce to the half best genomes in each species)
	RankGlobally()
	RemoveStaleSpecies()
	RankGlobally()
	for s = 1, #Pool.species do
		local species = Pool.species[s]
		CalculateAverageFitness(species)
	end
	RemoveWeakSpecies()
	local sum = TotalAverageFitness()
	local children = {}
	for s = 1, #Pool.species do
		local species = Pool.species[s]
		local breed = math.floor(species.averageFitness / sum * Population) - 1
		for i = 1, breed do
			table.insert(children, BreedChild(species))
		end
	end
	CullSpecies(true) -- Cull all but the top member of each species (reduce to one genome in each species)
	while #children + #Pool.species < Population do
		local species = Pool.species[math.random(1, #Pool.species)]
		table.insert(children, BreedChild(species))
	end
	for c = 1, #children do
		AddToSpecies(children[c])
	end

	Pool.generation = Pool.generation + 1
	print("Saving newly generated population to file...")
	SavePool("new_gen#" .. Pool.generation .. "_" .. forms.gettext(SaveLoadFile))
end

function RandomNeuron(genes, nonInput)
	local neurons = {}
	if not nonInput then
		for i = 1, Inputs do
			neurons[i] = true
		end
	end
	for o = 1, Outputs do
		neurons[MaxNodes + o] = true
	end
	for i = 1, #genes do
		if (not nonInput) or genes[i].input > Inputs then
			neurons[genes[i].input] = true
		end
		if (not nonInput) or genes[i].output > Inputs then
			neurons[genes[i].output] = true
		end
	end

	local n = math.random(1, #neurons + Outputs)
	if neurons[n] == nil then
		return MaxNodes + n
	else
		return n
	end

	return 0
end

function ContainsLink(genes, link)
	for i = 1, #genes do
		local gene = genes[i]
		if gene.input == link.input and gene.output == link.output then
			return true
		end
	end
	return false
end

function Disjoint(genes1, genes2)
	local i1 = {}
	for i = 1, #genes1 do
		local gene = genes1[i]
		i1[gene.innovation] = true
	end

	local i2 = {}
	for i = 1, #genes2 do
		local gene = genes2[i]
		i2[gene.innovation] = true
	end

	local disjointGenes = 0
	for i = 1, #genes1 do
		local gene = genes1[i]
		if not i2[gene.innovation] then
			disjointGenes = disjointGenes+1
		end
	end

	for i = 1, #genes2 do
		local gene = genes2[i]
		if not i1[gene.innovation] then
			disjointGenes = disjointGenes+1
		end
	end

	local n = math.max(#genes1, #genes2)
	return disjointGenes / n
end

function Weights(genes1, genes2)
	local i2 = {}
	for i = 1, #genes2 do
		local gene = genes2[i]
		i2[gene.innovation] = gene
	end

	local sum = 0
	local coincident = 0
	for i = 1, #genes1 do
		local gene = genes1[i]
		if i2[gene.innovation] ~= nil then
			local gene2 = i2[gene.innovation]
			sum = sum + math.abs(gene.weight - gene2.weight)
			coincident = coincident + 1
		end
	end
	return sum / coincident
end

function BreedChild(species)
	local child = {}
	if Mode["GA"] then
		if math.random() < CrossoverChance then
			local g1 = species.genomes[math.random(1, #species.genomes)]
			local g2 = species.genomes[math.random(1, #species.genomes)]
			child = Crossover(g1, g2)
		else
			local g = species.genomes[math.random(1, #species.genomes)]
			child = CopyGenome(g)
		end
	else
		local g = species.genomes[math.random(1, #species.genomes)]
		child = CopyGenome(g)
	end

	Mutate(child)
	return child
end

function AddToSpecies(child)
	local foundSpecies = false
	for s = 1, #Pool.species do
		local species = Pool.species[s]
		local dd = DeltaDisjoint * Disjoint(child.genes, species.genomes[1].genes)
		local dw = DeltaWeights  * Weights(child.genes, species.genomes[1].genes)
		if not foundSpecies and (dd + dw < DeltaThreshold) then
			table.insert(species.genomes, child)
			foundSpecies = true
		end
	end

	if not foundSpecies then
		local childSpecies = CreateSpecies()
		table.insert(childSpecies.genomes, child)
		table.insert(Pool.species, childSpecies)
	end
end

function NextGenome()
	Pool.currentGenome = Pool.currentGenome + 1
	if Pool.currentGenome > #Pool.species[Pool.currentSpecies].genomes then
		Pool.currentGenome = 1
		Pool.currentSpecies = Pool.currentSpecies + 1
		if Pool.currentSpecies > #Pool.species then
			NewGeneration()
			Pool.currentSpecies = 1
		end
	end
end