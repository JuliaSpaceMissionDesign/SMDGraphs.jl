using SMDGraphs
using Graphs
using Test

import SMDGraphs: MappedGraph, 
                  MappedDiGraph

# Simple Node graph for testing purposes
struct IntNode <: SMDGraphs.AbstractGraphNode 
    id::Int
end

SMDGraphs.get_node_id(n::IntNode) = n.id

@testset "SMDGraphs.jl" begin

    # Test MappedGraph Constructor
    graph = MappedGraph(IntNode)
    @test isa(graph, SMDGraphs.MappedNodeGraph{IntNode, SimpleGraph{Int64}})

    dgraph = MappedDiGraph(IntNode)
    @test isa(dgraph, SMDGraphs.MappedNodeGraph{IntNode, SimpleDiGraph{Int64}})

    @test isempty(graph)
    @test isempty(dgraph)

    node_a = IntNode(10) 
    node_b = IntNode(7)
    node_c = IntNode(1)

    # Test vertex addition 
    SMDGraphs.add_vertex!(graph, node_a)
    SMDGraphs.add_vertex!(graph, node_b)

    @test !isempty(graph)

    @test SMDGraphs.has_vertex(graph, 10)
    @test SMDGraphs.has_vertex(graph, 7)
    @test !SMDGraphs.has_vertex(graph, 1)

    SMDGraphs.add_vertex!(graph, node_c)
    @test SMDGraphs.has_vertex(graph, 1)

    # Test Mapped IDs 
    @test SMDGraphs.get_mappedid(graph, 10) == 1
    @test SMDGraphs.get_mappedid(graph, 7) == 2

    # Test Mapped Nodes
    @test SMDGraphs.get_node(graph, 1) == node_c

    # Add path 
    @test !SMDGraphs.has_path(graph, 7, 10)
    SMDGraphs.add_edge!(graph, 7, 10)
    @test SMDGraphs.has_path(graph, 7, 10)

    SMDGraphs.add_edge!(graph, 10, 1)
    @test SMDGraphs.has_path(graph, 1, 7)

    # Check path computation 
    SMDGraphs.compute_paths!(graph)

    @test SMDGraphs.get_path(graph, 1, 7)  == [3, 1, 2]
    @test SMDGraphs.get_path(graph, 1, 10) == [3, 1]

    @test SMDGraphs.get_edgecosts(graph, 8, 2) == Int64[]
    
end;
