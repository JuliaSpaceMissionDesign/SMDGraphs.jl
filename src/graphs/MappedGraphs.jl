
"""
    MappedNodeGraph{N, G}

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
struct MappedNodeGraph{N,G}
    graph::G
    mid::Dict{Int,Int} # mapped ids 
    nodes::Vector{N}
    paths::Dict{Int,Dict{Int,Vector{Int}}}
    edges::Dict{Int,Dict{Int,Int}}

    function MappedNodeGraph{N}(g::G) where {G<:AbstractGraph,N<:AbstractGraphNode}
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

"""
    has_vertex(g, node)

Return true if `node` is contained in the graph `g`.
"""
@inline has_vertex(g::MappedNodeGraph, node::Int) = haskey(g.mid, node)

"""
    has_path(g, from, to)

Return true if there is a path between `from` and `to` in the graph `g`.
"""
function has_path(g::MappedNodeGraph, from::Int, to::Int)
    return has_path(g.graph, get_mappedid(g, from), get_mappedid(g, to))
end

"""
    add_vertex!(g, node)

Add `node` to the graph `g`.
"""
function add_vertex!(g::MappedNodeGraph{T}, node::T) where {T<:AbstractGraphNode}
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

"""
    add_edge!(g::MappedNodeGraph, from::Int, to::Int, [cost])

Add an edge between `from` and `to` to `g`. 
Optionally assign a `cost` to the edge.
"""
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

""" 
    add_edge_cost!(g::MappedNodeGraph, fid::Int, tid::Int, cost::Int)

Register the cost between of the edge from the node with mapped ID `fid` to the 
node with mapped ID `tid`. 
"""
function add_edge_cost!(g::MappedNodeGraph{T}, fid::Int, tid::Int, cost::Int) where {T}
    edges = get!(g.edges, fid, Dict{Int,Int}())
    return push!(edges, tid => cost)
end

""" 
    add_edge_cost!(g::MappedNodeGraph, fid::Int, tid::Int, cost::Int)

For a `SimpleGraph` type, register the edge cost between the nodes with mapped IDs 
`fid` and `tid` in both directions.  
"""
function add_edge_cost!(
    g::MappedNodeGraph{T,N}, fid::Int, tid::Int, cost::Int
) where {T,N<:SimpleGraph}
    edges = get!(g.edges, fid, Dict{Int,Int}())
    edges = get!(g.edges, tid, Dict{Int,Int}())

    push!(edges, tid => cost)
    return push!(edges, fid => cost)
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
    get_path(g::MappedNodeGraph, from::Int, to::Int)

Get the nodes on the path between and including `from` and `to`. Returns an empty array if 
either `from` or `to` are not a part of `g` or if there is no path between them. 
"""
function get_path(g::MappedNodeGraph{T}, from::Int, to::Int) where {T}
    (has_vertex(g, from) && has_vertex(g, to)) || return Int[]
    return g.paths[from][to]
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
