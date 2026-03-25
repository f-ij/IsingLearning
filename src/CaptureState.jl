@ProcessAlgorithm function CaptureState(isinggraph, 
    @managed(captured = similar(state(isinggraph))), 
    @init (;isinggraph))
    
    captured .= state(isinggraph)
    return 
end

Capturer() = Unique(CaptureState())