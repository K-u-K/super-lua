function Crossover(g1, g2)
	-- Make sure g1 is the higher fitness genome
	if g2.fitness > g1.fitness then
		local tempg = g1
		g1 = g2
		g2 = tempg
	end

	local child = CreateGenome()
	
	local innovations2 = {}
	for i = 1, #g2.genes do
		local gene = g2.genes[i]
		innovations2[gene.innovation] = gene
	end
	
	for i=1,#g1.genes do
		local gene1 = g1.genes[i]
		local gene2 = innovations2[gene1.innovation]
		if gene2 ~= nil and math.random(2) == 1 and gene2.enabled then
			table.insert(child.genes, CopyGene(gene2))
		else
			table.insert(child.genes, CopyGene(gene1))
		end
	end
	
	child.maxneuron = math.max(g1.maxneuron,g2.maxneuron)
	
	-- for mutation,rate in pairs(g1.mutationRates) do
	-- 	child.mutationRates[mutation] = rate
	-- end

	child.mutationRates = DeepCopy(g1.mutationRates)
	child.mutationCount = DeepCopy(g1.mutationCount)
	child.mutationIter  = g1.mutationIter

	return child
end
