
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
