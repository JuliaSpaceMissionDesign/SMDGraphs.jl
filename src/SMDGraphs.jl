module SMDGraphs

import Graphs: 
    SimpleGraph, 
    SimpleDiGraph,

    add_edge!,
    add_vertex!, 
    nv, 
    dijkstra_shortest_paths, 
    enumerate_paths, 
    has_vertex, 
    has_path   
    
include("abstract.jl")
include("graphs/MappedGraphs.jl")

end
