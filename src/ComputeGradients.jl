"""
Go from IsingGraph with known Hamiltonian,
    for now Ising+Clamping
To all the gradient w.r.t: weights, biases, and self-energies
"""
struct ComputeIsingGradients <: ProcessAlgorithm end

"""
Creates buffers
"""
function Processes.init(alg::ComputeIsingGradients, inputcontext::C) where C
    (;isinggraph) = context
    
    weight_gradients = zero(SparseArrays.getnzval(adj(isinggraph)))
    bias_gradients = zero(state(isinggraph))
    self_energy_gradients = zero(state(isinggraph))
    return (;dw = weight_gradients, db = bias_gradients, dα = self_energy_gradients)
end

function Processes.step!(alg::ComputeIsingGradients, context)
    (;isinggraph) = context #Input
    (;dw, db, dα) = context #Buffers

    dw = 

    return (;dw, db, dα)
end