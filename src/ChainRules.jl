"""
Run one free phase and one nudged phase for the cotangent ȳ, and return
the EP estimate of the VJP with respect to ps.

Interpretation:
    pullback(ȳ) ≈ ∂⟨ȳ, y⟩/∂(x, ps, st)
"""
function ep_param_vjp(layer::LayeredIsingGraphLayer, x, ps, st, ȳ; β = layer.β)
    βf = Float32(β)
    iszero(βf) && throw(ArgumentError("β must be non-zero"))

    # It is safest to work on copies / reconstructed graphs, not the live one.
    g0 = GraphFromInit(st.graph, ps)
    gp = GraphFromInit(st.graph, ps)

    # ---------- free phase ----------
    off!(g0.index_set, layer.input_layer)
    state(g0[1]) .= x

    algo0 = st.relax_routine
    run(
        algo0,
        Input(algo0[1], state = g0),
        lifetime = Repeat(length(state(g0)) * layer.fullsweeps),
        mode = :inline_synced,
    )

    s0 = copy(state(g0))
    y0 = copy(@view state(g0[nlayers(g0)]))

    # ---------- nudged phase ----------
    # same input clamp
    off!(gp.index_set, layer.input_layer)
    state(gp[1]) .= x

    # TODO:
    # convert output cotangent ȳ into your clamping/nudging parameters.
    #
    # For a linear output-nudging term -β * dot(ȳ, y),
    # the force is directly ȳ.
    #
    # For your existing Clamping Hamiltonian, you need to decide how
    # `target`/`:y` should encode this cotangent. If your clamping term is
    # quadratic in (y - target), then the direct EP pullback is cleaner if you
    # make a nudging routine that accepts ȳ itself rather than a target vector.
    set_output_cotangent_nudge!(gp, layer.output_layer, ȳ, βf)

    algop = st.relax_routine
    run(
        algop,
        Input(algop[1], state = gp),
        lifetime = Repeat(length(state(gp)) * layer.fullsweeps),
        mode = :inline_synced,
    )

    sp = copy(state(gp))

    # ---------- EP estimates ----------
    # These are sketches. Adapt indexing/storage to your actual graph layout.

    # edge weights
    dweights = similar(ps.weights)
    edge_iter = each_trainable_edge(gp)  # define this for your adjacency storage
    for (k, (i, j)) in enumerate(edge_iter)
        dweights[k] = (Float32(sp[i]) * Float32(sp[j]) -
                       Float32(s0[i]) * Float32(s0[j])) / βf
    end

    # biases
    dbiases = similar(ps.biases)
    @inbounds for i in eachindex(ps.biases)
        dbiases[i] = (Float32(sp[i]) - Float32(s0[i])) / βf
    end

    # self-energies / diagonal terms
    dα = similar(ps.α_i)
    @inbounds for i in eachindex(ps.α_i)
        # TODO: fix this to match your exact Hamiltonian parameterization.
        # This is only a placeholder for a quadratic local term.
        dα[i] = (Float32(sp[i])^2 - Float32(s0[i])^2) / βf
    end

    return (weights = dweights, biases = dbiases, α_i = dα)
end

using ChainRulesCore

function ChainRulesCore.rrule(layer::LayeredIsingGraphLayer, x, ps, st)
    # ---------- primal free phase ----------
    g = GraphFromInit(st.graph, ps)



    off!(g.index_set, layer.input_layer)
    state(g[1]) .= x



    proc = st.relax_routine
    minus_capture = st.minus_capture
    plus_capture = st.plus_capture

    # reset!(proc, Input(Metropolis(), state = g))
    g.hamiltonian[4].β = layer.β #TODO: Find a way to refer to \beta cleanly
    c = run(proc, Input(Metropolis(), state = g))
    plus_state = c[plus_capture].captured
    minus_state = c[minus_capture].captured
    
    output_idxs = layer.output_layer
    yplus = @view plus_state[output_idxs]
    yminus = @view minus_state[output_idxs]

    project_ps = ProjectTo(ps)

    function pullback(ΔΩ)
        ΔΩ = unthunk(ΔΩ)
        ȳ, _ = ΔΩ

        βf = layer.β

        s_plus  = nudged_from_free_state(layer, s_free, x, ps, st, ȳ, +βf)
        s_minus = nudged_from_free_state(layer, s_free, x, ps, st, ȳ, -βf)

        ∂ps = @thunk begin
            dweights = similar(ps.weights)
            for (k, (i, j)) in enumerate(each_trainable_edge(st.graph))
                dweights[k] =
                    (Float32(s_plus[i]) * Float32(s_plus[j]) -
                     Float32(s_minus[i]) * Float32(s_minus[j])) / (2f0 * βf)
            end

            dbiases = similar(ps.biases)
            @inbounds for i in eachindex(ps.biases)
                dbiases[i] = (Float32(s_plus[i]) - Float32(s_minus[i])) / (2f0 * βf)
            end

            dα = similar(ps.α_i)
            @inbounds for i in eachindex(ps.α_i)
                dα[i] = (Float32(s_plus[i])^2 - Float32(s_minus[i])^2) / (2f0 * βf)
            end

            project_ps((weights = dweights, biases = dbiases, α_i = dα))
        end

        ∂layer = NoTangent()
        ∂x     = ZeroTangent()
        ∂st    = NoTangent()

        return ∂layer, ∂x, ∂ps, ∂st
    end

    return (y, st_out), pullback
end