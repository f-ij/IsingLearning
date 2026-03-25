ForwardDynamics(windowsize, tol,) = CompositeAlgorithm(
    InteractiveIsing.Metropolis(),
    ConvergeanceTest()
)

function ForwardAndBackwardDynamics(windowsize, tol)
    c1 = ConvergeanceTest(windowsize, tol)
    c2 = ConvergeanceTest(windowsize, tol)
    plus_capture = Capturer()
    minus_capture = Capturer()
    forward = Routine(Composite(Metropolis, c1), plus_capture, (Repeat(1000), 1),
        Route(Metropolis => plus, :state => :isinggraph))

    backwards = Routine(Composite(Metropolis, c2), minus_capture, (Repeat(1000), 1),
        Route(Metropolis => minus, :state => :isinggraph))

    r = CompositeAlgorithm(forward, backwards, computegradients,
        Route(plus_capture => computegradients, :buffer => :plus_state),
        Route(minus_capture => computegradients, :buffer => :minus_state)
    )
    materialize(r)
end