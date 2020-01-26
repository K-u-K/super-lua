function PointMutate(genome)
	local step = genome.mutationRates["step"]

	for i = 1, #genome.genes do
		local gene = genome.genes[i]
		if math.random() < PerturbChance then
			gene.weight = gene.weight + math.random() * step * 2 - step
		else
			gene.weight = math.random() * 4 - 2
		end
	end
end

function LinkMutate(genome, forceBias)
	local neuron1 = RandomNeuron(genome.genes, false)
    local neuron2 = RandomNeuron(genome.genes, true)

	local newLink = CreateGene()
	if neuron1 <= Inputs and neuron2 <= Inputs then
		-- Both input nodes
		return
	end
	if neuron2 <= Inputs then
		-- Swap output and input
		local temp = neuron1
		neuron1 = neuron2
		neuron2 = temp
	end

	newLink.input = neuron1
	newLink.output = neuron2
	if forceBias then
		newLink.input = Inputs
	end

	if ContainsLink(genome.genes, newLink) then
		return
	end
	-- New Mutation happens
	Pool.innovation = Pool.innovation + 1
	newLink.innovation = Pool.innovation
	newLink.weight = math.random() * 4 - 2

	table.insert(genome.genes, newLink)
	if forceBias then
		genome.mutationCount["bias"] = genome.mutationCount["bias"] + 1
	else
		genome.mutationCount["link"] = genome.mutationCount["link"] + 1
	end
end

function NodeMutate(genome)
	if #genome.genes == 0 then
		return
	end

	genome.maxneuron = genome.maxneuron + 1

	local gene = genome.genes[math.random(1,#genome.genes)]
	if not gene.enabled then
		return
	end
	gene.enabled = false

	local gene1 = CopyGene(gene)
	gene1.output = genome.maxneuron
	gene1.weight = 1.0
	-- New Mutation happens
	Pool.innovation = Pool.innovation + 1
	gene1.innovation = Pool.innovation
	gene1.enabled = true
	table.insert(genome.genes, gene1)

	local gene2 = CopyGene(gene)
	gene2.input = genome.maxneuron
	-- New Mutation happens
	Pool.innovation = Pool.innovation + 1
	gene2.innovation = Pool.innovation
	gene2.enabled = true
	table.insert(genome.genes, gene2)
	genome.mutationCount["node"] = genome.mutationCount["node"] + 1
end

function EnableDisableMutate(genome, enable)
	local candidates = {}
	for _, gene in pairs(genome.genes) do
		if gene.enabled == not enable then
			table.insert(candidates, gene)
		end
	end

	if #candidates == 0 then
		return
	end

	local gene = candidates[math.random(1, #candidates)]
	gene.enabled = not gene.enabled
	if enable then
		genome.mutationCount["enable"] = genome.mutationCount["enable"] + 1
	else
		genome.mutationCount["disable"] = genome.mutationCount["disable"] + 1
	end
end

function Mutate(genome)
	local mutate = false

	for mutation, rate in pairs(genome.mutationRates) do
		-- if math.random(1, 2) == 1 then
		-- 	genome.mutationRates[mutation] = 0.95 * rate
		-- else
		-- 	genome.mutationRates[mutation] = 1.05263 * rate
		-- end
		--print("Checking for mutation: " .. genome.mutationIter .. IterationsBeforeOneFithAdaption)
		if mutation ~= "step" then
			--print("Adapting mutation rates..." .. genome.mutationCount[mutation] .. " - "..  mutation .. " - " .. genome.mutationIter)
			if genome.mutationIter >= IterationsBeforeOneFithAdaption then
				if genome.mutationCount[mutation] > (genome.mutationIter / 5) then
					if mutation == "connections" then genome.mutationRates["step"] = (1/0.82) * rate end
					genome.mutationRates[mutation] = (1/0.82) * rate
				else
					if mutation == "connections" then genome.mutationRates["step"] = 0.82 * rate end
					genome.mutationRates[mutation] = 0.82 * rate
				end
				mutate = true
			end
		end
	end

	if mutate then
		genome.mutationIter = 0
	end

	if math.random() < genome.mutationRates["connections"] then
		genome.mutationIter = genome.mutationIter + 1
		genome.mutationCount["connections"] = genome.mutationCount["connections"] + 1
		PointMutate(genome)
	end

	local p = genome.mutationRates["link"]
	while p > 0 do
		if math.random() < p then
			genome.mutationIter = genome.mutationIter + 1
			LinkMutate(genome, false)
		end
		p = p - 1
	end

	p = genome.mutationRates["bias"]
	while p > 0 do
		if math.random() < p then
			genome.mutationIter = genome.mutationIter + 1
			LinkMutate(genome, true)
		end
		p = p - 1
	end

	p = genome.mutationRates["node"]
	while p > 0 do
		if math.random() < p then
			genome.mutationIter = genome.mutationIter + 1
			NodeMutate(genome)
		end
		p = p - 1
	end

	p = genome.mutationRates["enable"]
	while p > 0 do
		if math.random() < p then
			genome.mutationIter = genome.mutationIter + 1
			EnableDisableMutate(genome, true)
		end
		p = p - 1
	end

	p = genome.mutationRates["disable"]
	while p > 0 do
		if math.random() < p then
			genome.mutationIter = genome.mutationIter + 1
			EnableDisableMutate(genome, false)
		end
		p = p - 1
	end
end