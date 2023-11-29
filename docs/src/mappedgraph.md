
# Mapped-Node Graphs

```@meta
CurrentModule = SMDGraphs
DocTestSetup = quote 
    using SMDGraphs
    import JSMDInterfaces.Graph: AbstractJSMDGraphNode
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
properties. First, we will define our custom node type, which must be 
a sub-type of `AbstractJSMDGraphNode`:

```julia
import JSMDInterfaces.Graph: AbstractJSMDGraphNode 

struct SpaceBody{T} <: AbstractGraphNode
    radius::T
    density::T
    id::Int 
    name::String
end
```

Before using this structure as node, the function [`SMDGraphs.get_node_id`](@ref) must be implemented for this data-type. For this reason, we have included within `SpaceBody` an integer field to store the ID of the body.

```julia
SMDGraphs.get_node_id(body::SpaceBody) = body.id
```

We are now ready to create our custom graph. The `MappedNodeGraph`
constructor is called as follows:

```julia
import SMDGraphs: MappedGraph
graph = MappedGraph(SpaceBody{Float64})
```

This line will create an empty `SimpleGraph` with nodes of type `SpaceBody{Float64}`.
A directed `SimpleDiGraph` graph is also supported by replacing the above line 
with the `MappedDiGraph` constructor. To avoid allocations, all the nodes must belong 
to the same concrete type.

To show the capabilities of mapped graphs, we will define a bunch of custom bodies and add
them to the graph. 

```julia
# Define some custom bodies 
earth = SpaceBody(6378.0, 5.51, 399, "Earth")
sun = SpaceBody(696340.0, 1.41, 10, "Sun")
moon = SpaceBody(1737.4, 3.34, 301, "Moon")

# Populate the graph with these bodies
SMDGraphs.add_vertex!(graph, earth)
SMDGraphs.add_vertex!(graph, sun)
SMDGraphs.add_vertex!(graph, moon)
```

Please note that the order in which these bodies are added to the graph does not matter, 
because it will only affect the inner ID associated to each node. To access the items 
stored inside the graph, we can use either their user-defined ID or the internal one. The latter is retrieved with the [`SMDGraphs.get_mappedid`](@ref) function:

```julia-repl
julia> SMDGraphs.get_node(graph, 399)
SpaceBody{Float64}(6378.0, 5.51, 399, "Earth")

julia> SMDGraphs.get_mappedid(graph, 301)
3

julia> SMDGraphs.get_mappednode(graph, 3)
SpaceBody{Float64}(1737.4, 3.34, 301, "Moon")
```
Here we have retrieved Earth's property through its nominal ID and exploited 
`get_mappedid` and `get_mappednode` to discover the internal ID of the Moon and
access its content.

Connections between the items in the graph are easily added as follows: 
```julia
SMDGraphs.add_edge!(graph, 10, 399)
SMDGraphs.add_edge!(graph, 399, 301)
```
By providing an additional integer input to `add_edge!`, a weight factor 
can be associated to the edge. The default weight is null.

Finally, the path between two nodes is retrived as: 
```julia-repl
julia> path = SMDGraphs.get_path(graph, 10, 301);
julia> print(path)
[2, 1, 3]
```

Note that `get_path` returns an integer vector of internal IDs instead of the user-defined ones. This enables a faster retrieval of the nodes via [`SMDGraphs.get_mappednode`](@ref), allowing to skip the dictionary lookup for the ID mapping of each node in the path.