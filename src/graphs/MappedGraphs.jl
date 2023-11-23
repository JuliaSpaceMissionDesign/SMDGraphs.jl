
"""
    get_node_id(b::AbstractJSMDGraphNode)   

Get the mapped-id of an `AbstractJSMDGraphNode`.

!!! warning
    This method is abstract! A concrete implementation for each concrete node shall be defined.
"""
@interface function get_node_id(::AbstractJSMDGraphNode) end 


"""
    MappedNodeGraph{N, G} <: AbstractJSMDGraph{Int}

Create a graph with mapped nodes. 

### Fields 
- `graph` -- Graph
- `mid` -- Mapped id to nodes dictionary
- `nodes` -- Mapped nodes 
- `edges` -- List of the edges between the nodes 
- `paths` -- List of the available paths in the graph

### Constructors
- `MappedNodeGraph{N}(g::G) where {G <: AbstractGraph, N <: AbstractGraphNode}`
"""
struct MappedNodeGraph{N,G} <: AbstractJSMDGraph{Int}
    graph::G
    mid::Dict{Int,Int} # mapped ids 
    nodes::Vector{N}
    paths::Dict{Int,Dict{Int,Vector{Int}}}
    edges::Dict{Int,Dict{Int,Int}}

    function MappedNodeGraph{N}(g::G) where {G<:AbstractGraph, N<:AbstractJSMDGraphNode}
        return new{N,G}(
            g,
            Dict{Int,Int}(),
            Vector{N}(undef, 0),
            Dict{Int,Dict{Int,Int}}(),
            Dict{Int,Dict{Int,Int}}(),
        )
    end
end

MappedNodeGraph{N}(g=SimpleGraph()) where {N} = MappedNodeGraph{N}(g)

"""
    MappedGraph(::Type{N}) where {N}

Construct a [`MappedNodeGraph`](@ref) from node type `N`.
"""
MappedGraph(::Type{N}) where {N} = MappedNodeGraph{N}(SimpleGraph{Int}())

"""
    MappedDiGraph(::Type{N}) where {N}

Construct a directed [`MappedNodeGraph`](@ref) from node type `N`.
"""
MappedDiGraph(::Type{N}) where {N} = MappedNodeGraph{N}(SimpleDiGraph{Int}())

"""
    get_mappedid(g::MappedNodeGraph, node::Int)

Get the mappedid associated with a node.
"""
@inline get_mappedid(g::MappedNodeGraph, node::Int) = g.mid[node]

"""
    get_outerid(g::MappedNodeGraph, id::Int)

Return the id of the node associated to the mapped id `id`.
"""
@inline get_outerid(g::MappedNodeGraph, id::Int) = get_node_id(g.nodes[id])

"""
    get_mappednode(g::MappedNodeGraph, mid::Int)

Get the node associated to the given mapped id.
"""
@inline get_mappednode(g::MappedNodeGraph, mid::Int) = @inbounds g.nodes[mid]

"""
    get_node(g::MappedNodeGraph, node::Int)

Get the node associated with a node index.
"""
@inline get_node(g::MappedNodeGraph, node::Int) = get_mappednode(g, get_mappedid(g, node))

Base.isempty(g::MappedNodeGraph) = Base.isempty(g.nodes)


# Graphs Interfaces
# =======================

has_vertex(g::MappedNodeGraph, node::Int) = haskey(g.mid, node)

function has_edge(g::MappedNodeGraph, from::Int, to::Int)    
    # Check whether from and to are registered in the graph
    (!haskey(g.mid, from) || !haskey(g.mid, to)) && return false 

    fid = get_mappedid(g, from)
    tid = get_mappedid(g, to)

    has_edge(g.graph, fid, tid)
end 

function edges(g::MappedNodeGraph)
    map(e->Graphs.SimpleEdge(get_outer_id(e.src), get_outer_id(e.dst)), edges(g.graph))
end

edgetype(g::MappedNodeGraph) = edgetype(g.graph)

is_directed(g::MappedNodeGraph) = is_directed(g.graph) 

ne(g::MappedNodeGraph) = ne(g.graph)
nv(g::MappedNodeGraph) = nv(g.graph)

function inneighbors(g::MappedNodeGraph, node::Int)
    map(get_outerid, inneighbors(g.graph, node))
end 

function outneighbors(g::MappedNodeGraph, node::Int)
    map(get_outerid, outneighbors(g.graph, node))
end
    
vertices(g::MappedNodeGraph) = map(get_node_id, g.nodes)


# JSMD Interfaces 
# =======================

function add_vertex!(g::MappedNodeGraph{T}, node::T) where {T<:AbstractJSMDGraphNode}
    nodeid = get_node_id(node)
    has_vertex(g, nodeid) && return nothing

    # insert a new vertex 
    add_vertex!(g.graph)

    # compute mapped id
    mid = nv(g.graph)

    # updates graph
    push!(g.mid, nodeid => mid)
    push!(g.nodes, node)
    return nothing
end

function add_edge!(g::MappedNodeGraph{T}, from::Int, to::Int, cost::Int=0) where {T}
    # ensure the two vertexes already exist in the graph 
    if !(has_vertex(g, from) && has_vertex(g, to))
        throw(ErrorException("The vertex $from or $to is not contained in the graph."))
    end

    fid = get_mappedid(g, from)
    tid = get_mappedid(g, to)

    add_edge!(g.graph, fid, tid)
    compute_paths!(g)

    add_edge_cost!(g, fid, tid, cost)

    return nothing
end

function has_path(g::MappedNodeGraph, from::Int, to::Int)
    return has_path(g.graph, get_mappedid(g, from), get_mappedid(g, to))
end

function get_path(g::MappedNodeGraph{T}, from::Int, to::Int) where {T}
    (has_vertex(g, from) && has_vertex(g, to)) || return Int[]
    return g.paths[from][to]
end


# Internal routines
# =======================

""" 
    add_edge_cost!(g::MappedNodeGraph, fid::Int, tid::Int, cost::Int)

Register the cost between of the edge from the node with mapped ID `fid` to the 
node with mapped ID `tid`. 
"""
function add_edge_cost!(g::MappedNodeGraph{T}, fid::Int, tid::Int, cost::Int) where {T}
    edges = get!(g.edges, fid, Dict{Int,Int}())
    push!(edges, tid => cost)
end

""" 
    add_edge_cost!(g::MappedNodeGraph{T, <:SimpleGraph}, fid::Int, tid::Int, cost::Int)

For a `SimpleGraph` type, register the edge cost between the nodes with mapped IDs 
`fid` and `tid` in both directions.  
"""
function add_edge_cost!(
    g::MappedNodeGraph{T,N}, fid::Int, tid::Int, cost::Int
) where {T,N<:SimpleGraph}

    # Add forward direction cost
    edges = get!(g.edges, tid, Dict{Int,Int}())
    push!(edges, fid => cost)

    # Add backward direction cost
    edges = get!(g.edges, fid, Dict{Int,Int}())   
    push!(edges, tid => cost)
end

"""
    compute_paths(g::MappedNodeGraph)

Compute all possible paths in the graph.
"""
function compute_paths!(g::MappedNodeGraph{T}) where {T}
    for (oiid, origin) in enumerate(g.nodes)
        oid = get_node_id(origin)

        ds = dijkstra_shortest_paths(g.graph, oiid)
        for (tiid, target) in enumerate(g.nodes)
            oiid == tiid && continue
            tid = get_node_id(target)

            path = enumerate_paths(ds, tiid)
            paths = get!(g.paths, oid, Dict{Int,Vector{Int}}())
            push!(paths, tid => path)
        end
    end
    return nothing
end

"""
    get_edgecosts(g::MappedNodeGraph, from::Int, to::Int)

Get all costs assigned to the edges between `from` and `to`. Returns an empty array if 
either `from` or `to` are not a part of `g` or if there is no path between them.
"""
function get_edgecosts(g::MappedNodeGraph{T}, from::Int, to::Int) where {T}
    path = get_path(g, from, to)
    isempty(path) && return Int[]
    edges = Vector{Int}(undef, length(path) - 1)
    for i in eachindex(edges)
        edges[i] = g.edges[path[i]][path[i + 1]]
    end
    return edges
end
