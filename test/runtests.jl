using SMDGraphs
using Test

using Graphs: Graphs, SimpleEdge

import JSMDInterfaces.Errors: NotImplementedError
import JSMDInterfaces.Graph as jGraph
import SMDGraphs: MappedGraph, MappedDiGraph, MappedNodeGraph

# Simple Node graph for testing purposes
struct IntNode <: jGraph.AbstractJSMDGraphNode
    id::Int
end

struct FakeNode <: jGraph.AbstractJSMDGraphNode
    id::Int
end

SMDGraphs.get_node_id(n::IntNode) = n.id

@testset "SMDGraphs.jl" begin

    @testset "MappedGraphs" begin 

        # Check Error Enforcement 
        @test_throws NotImplementedError SMDGraphs.get_node_id(FakeNode(7))

        # Test MappedGraph Constructor
        graph = MappedGraph(IntNode)
        @test isa(graph, SMDGraphs.MappedNodeGraph{IntNode,SimpleGraph{Int64}})

        graph2 = MappedNodeGraph{IntNode}()
        @test isa(graph, SMDGraphs.MappedNodeGraph{IntNode,SimpleGraph{Int64}})

        dgraph = MappedDiGraph(IntNode)
        @test isa(dgraph, SMDGraphs.MappedNodeGraph{IntNode,SimpleDiGraph{Int64}})

        @test isempty(graph)
        @test isempty(dgraph)

        @test SMDGraphs.nv(graph) == 0
        @test SMDGraphs.ne(graph) == 0

        @test SMDGraphs.vertices(graph) == []

        node_a = IntNode(10)
        node_b = IntNode(7)
        node_c = IntNode(1)

        # Test vertex addition 
        SMDGraphs.add_vertex!(graph, node_a)
        SMDGraphs.add_vertex!(graph, node_b)

        SMDGraphs.add_vertex!(dgraph, node_a)
        SMDGraphs.add_vertex!(dgraph, node_b)
        SMDGraphs.add_vertex!(dgraph, node_c)

        @test !isempty(graph)

        # Test JSMDInterfaces 
        # =========================
        
        @test !SMDGraphs.is_directed(graph)
        @test SMDGraphs.is_directed(dgraph)

        @test SMDGraphs.nv(graph) == 2 
        @test SMDGraphs.nv(dgraph) == 3

        @test SMDGraphs.ne(graph) == 0
        @test SMDGraphs.ne(dgraph) == 0

        @test SMDGraphs.edgetype(graph) == SimpleEdge{Int64}
        @test SMDGraphs.edgetype(dgraph) == SimpleEdge{Int64}

        @test SMDGraphs.vertices(graph) == [10, 7]
        @test SMDGraphs.vertices(dgraph) == [10, 7, 1]

        @test SMDGraphs.has_vertex(graph, 10)
        @test SMDGraphs.has_vertex(graph, 7)
        @test !SMDGraphs.has_vertex(graph, 1)

        @test isempty(SMDGraphs.inneighbors(graph, 10))

        SMDGraphs.add_vertex!(graph, node_c)
        @test SMDGraphs.has_vertex(graph, 1)

        # Test outer IDs
        @test SMDGraphs.get_outerid(graph, 1)  == 10
        @test SMDGraphs.get_outerid(dgraph, 3) == 1

        # Test Mapped IDs 
        @test SMDGraphs.get_mappedid(graph, 10) == 1
        @test SMDGraphs.get_mappedid(graph, 7) == 2

        # Test Mapped Nodes
        @test SMDGraphs.get_node(graph, 1) == node_c

        # Add path 
        @test !SMDGraphs.has_path(graph, 7, 10)
        SMDGraphs.add_edge!(graph, 7, 10)
        @test SMDGraphs.has_path(graph, 7, 10)
        @test SMDGraphs.has_edge(graph, 7, 10)

        @test SMDGraphs.inneighbors(graph, 10) == [7]
        @test SMDGraphs.outneighbors(graph, 10) == [7]
        @test SMDGraphs.inneighbors(graph, 7) == [10]

        @test !SMDGraphs.has_edge(graph, 10, 1)
        SMDGraphs.add_edge!(graph, 10, 1, 7)
        @test SMDGraphs.has_path(graph, 1, 7)
        @test SMDGraphs.has_edge(graph, 10, 1)
        @test !SMDGraphs.has_edge(graph, 7, 1)

        @test SMDGraphs.ne(graph) == 2
        @test SMDGraphs.edges(graph) == [Graphs.Simpl]

        SMDGraphs.add_edge!(dgraph, 10, 7, 6)
        SMDGraphs.add_edge!(dgraph, 7, 1, 3)

        @test isempty(SMDGraphs.inneighbors(dgraph, 10))
        @test SMDGraphs.inneighbors(dgraph, 7) == [10]
        @test SMDGraphs.outneighbors(dgraph, 10) == [7]

        @test SMDGraphs.ne(dgraph) == 2

        @test_throws ErrorException SMDGraphs.add_edge!(graph, 10, 8)

        @test SMDGraphs.get_path(graph, 1, 7) == [3, 1, 2]
        @test SMDGraphs.get_path(graph, 1, 10) == [3, 1]

        # Check edge cost 
        @test SMDGraphs.get_edgecosts(graph, 8, 2) == Int64[]
        @test SMDGraphs.get_edgecosts(graph, 1, 10) == [7]
        @test SMDGraphs.get_edgecosts(graph, 1, 7) == [7, 0]
        @test SMDGraphs.get_edgecosts(graph, 10, 1) == [7]

        @test SMDGraphs.get_edgecosts(dgraph, 10, 1) == [6, 3]

    end

end;
