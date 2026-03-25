
function ReducedBoltzmannArchitecture(layer_sizes...; precision = Float32)
    layer_gen = (Layer(
            layer_sizes[i],
            Continuous(),
            Coords(0, i, 0)) for i in 1:length(layer_sizes))

    
    IsingGraph(layer_gen...,
                Ising() + Clamping();
                index_set = g -> ToggledIndexSet(g))
end

"""
    Create a graph copy, with separate state, but shared data
"""
function GraphFromSource(g::IsingGraph; init! = identity)
    gnew = IsingGraph(
        copy(state(g)),
        adj(g),
        temp(g),
        g.default_algorithm,
        g.hamiltonian,
        g.index_set,
        g.addons,
        g.layers,
    )
    init!(gnew)
    return gnew
end

function GraphFromInit(g::IsingGraph, parameters; init! = identity)
    colptrs = getcolptrs(adj(g))
    rowvals = getrowvals(adj(g))
    nzvals = parameters.weights
    new_adj = UndirectedAdjacency(colptrs, rowvals, nzvals, size(adj(g)), diag = parameters.α_i)
    gnew = IsingGraph(
        copy(state(g)),
        new_adj,
        temp(g),
        g.default_algorithm,
        Ising(b = parameters.biases) + Clamping(),
        g.index_set,
        g.addons,
        g.layers,
    )
    init!(gnew)
    return gnew
end

