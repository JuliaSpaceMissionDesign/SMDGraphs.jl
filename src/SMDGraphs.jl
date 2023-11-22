module SMDGraphs

using JSMDInterfaces.Interface: @interface

import JSMDInterfaces: 
    AbstractJSMDGraphNode, 
    AbstractJSMDGraph

import Graphs:
    AbstractGraph
    SimpleGraph,
    SimpleDiGraph,
    add_edge!,
    add_vertex!,
    dijkstra_shortest_paths,
    edges,
    edgetype,
    enumerate_paths,
    has_edge,
    has_path,
    has_vertex, 
    is_directed,
    ne,
    nv,
    vertices
    

include("graphs/MappedGraphs.jl")

end
