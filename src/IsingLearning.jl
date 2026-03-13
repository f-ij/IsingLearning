module IsingLearning

using LuxCore
using Random: AbstractRNG
using SparseArrays: nonzeros, nzrange, rowvals, SparseMatrixCSC
using InteractiveIsing
using InteractiveIsing: state, adj, setparam!, getparam, setSpins!, nStates
using InteractiveIsing.Processes
using DataStructures

import LuxCore: initialparameters, initialstates
import Processes: init, step!

include("Utils.jl")
include("SparseAdjacency.jl")
include("LuxModel.jl")

end # module IsingLearning
