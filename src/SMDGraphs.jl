module SMDGraphs

using JSMDInterfaces.Interface

import JSMDInterfaces.Graph: 
    AbstractJSMDGraphNode, 
    AbstractJSMDGraph, 
    add_edge!, 
    add_vertex!, 
    edges, 
    edgetype, 
    get_path,
    has_vertex, 
    has_edge, 
    has_path, 
    inneighbors, 
    is_directed, 
    ne, 
    nv, 
    outneighbors, 
    vertices

import Graphs:
    AbstractGraph,
    SimpleEdge,
    SimpleGraph,
    SimpleDiGraph,
    dijkstra_shortest_paths,
    enumerate_paths

include("graphs/MappedGraphs.jl")

end
