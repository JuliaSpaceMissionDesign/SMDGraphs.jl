
# Mapped-Node Graphs

```@meta
CurrentModule = SMDGraphs
DocTestSetup = quote 
    using SMDGraphs
end
```

Mapped-Node graphs enable graph operations on any custom user-defined 
concrete type, effectively replacing the integer nodes of the [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl)
graph, with the desired type. To enforce type-stability and avoid allocations, 
the linking between the inner graph nodes and the custom nodes is achieved via 
an integer mapping. Therefore, the only requirement is that an integer ID can 
be associated to the custom type. The user will then be able to retrieve the 
items in the nodes through this ID.

## Usage
Suppose that you want to create a graph to connect items that store planetary bodies 
properties. First, we will define our custom type, which must be 
a sub-type of [`SMDGraphs.AbstractGraphNode`](@ref):

```julia
struct BodyProperties{T} <: SMDGraphs.AbstractGraphNode
    radius::T
    density::T
    id::Int 
    name::String
end
```

Before using this structure as node, the function [`SMDGraphs.get_node_id`](@ref) must be implemented for this data-type. For this reason, we have included within `BodyProperties` an integer
field storing the ID of the body.

```julia
SMDGraphs.get_node_id(body::BodyProperties) = body.id
```

We are now ready to create our custom graph. The `MappedNodeGraph`
constructor can be called as follows:

```julia
import SMDGraphs: MappedGraph
graph = MappedGraph(BodyProperties{Float64})
```

This line will create an empty `SimpleGraph` with nodes of type `BodyProperties{Float64}`.
A directed `SimpleDiGraph` graph is also supported by replacing the above line 
with the `MappedDiGraph` constructor.

To show the capabilities of mapped graphs, we will define a bunch of custom bodies and add
them to the graph. 

```julia
# Define some custom bodies 
earth = BodyProperties(6378.0, 5.51, 399, "Earth")
venus = BodyProperties(6051.8, 5.24, 299, "Venus")
moon = BodyProperties(1737.4, 3.34, 301, "Moon")

# Populate the graph with these bodies
SMDGraphs.add_vertex!(graph, earth)
SMDGraphs.add_vertex!(graph, venus)
SMDGraphs.add_vertex!(graph, moon)
```

Please note that the order in which these bodies are added to the graph does not matter, 
because it will only affect the inner ID associated to each node. To access the items 
stored inside the graph, we can use either their user-defined ID or the internal one. The latter is retrieved with the [`SMDGraphs.get_mappedid`](@ref) function:

```julia-repl
julia> SMDGraphs.get_node(graph, 399)
BodyProperties{Float64}(6378.0, 5.51, 399, "Earth")

julia> SMDGraphs.get_mappedid(graph, 399) 
1

julia> SMDGraphs.get_mappedid(graph, 301)
3

julia> SMDGraphs.get_mappednode(graph, 3)
BodyProperties{Float64}(1737.4, 3.34, 301, "Moon")
```

Connections between the items in the graph are easily added as follows: 
```julia
SMDGraphs.add_edge!(graph, 299, 399)
SMDGraphs.add_edge!(graph, 399, 301)
```

