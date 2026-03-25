@ProcessAlgorithm function CaptureState(isinggraph, 
    @managed(buffer = similar(state(isinggraph))), 
    @init (;isinggraph))
    
    buffer .= state(isinggraph)
end

Capturer() = Unique(CaptureState())