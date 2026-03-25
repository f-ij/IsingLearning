ForwardDynamics(windowsize, tol,) = CompositeAlgorithm(
    InteractiveIsing.Metropolis(),
    ConvergeanceTest()
)

@ProcessAlgorithm function resetgraph!(isinggraph::G) where G
    resetstate!(isinggraph)
    return 
end

@ProcessAlgorithm function empty()
    return
end

function NudgedProcess(layer)
    beta = layer.β
    fullsweeps = layer.fullsweeps
    n_units = layer.n_units
    # c1 = ConvergeanceTest(windowsize, tol)
    # c2 = ConvergeanceTest(windowsize, tol)
    plus_capture = Capturer()
    minus_capture = Capturer()
    forward = Routine(Composite(Metropolis()), 
                        plus_capture, 
                        resetgraph!, 
                        (Repeat(fullsweeps*n_units), 1),
        Route(Metropolis => plus, :state => :isinggraph),
        Route(Metropolis => resetgraph, :state => :isinsggraph)
        )
        

    backward = Routine(Composite(Metropolis()), minus_capture, resetgraph!, (Repeat(fullsweeps*n_units), 1),
        Route(Metropolis => minus, :state => :isinggraph),
        Route(Metropolis => resetgraph, :state => :isinsggraph)
    )

    r = CompositeAlgorithm(forward, backward, computegradients,
        Route(plus_capture => computegradients, :buffer => :plus_state),
        Route(minus_capture => computegradients, :buffer => :minus_state)
    )
    g = layer.graph_init()
    proc = InlineProcess(r, Input(Metropolis(), state = g))
    return (;proc, plus_capture, minus_capture)
end

