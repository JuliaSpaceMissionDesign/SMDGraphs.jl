import Graphs: AbstractGraph

"""
AbstractGraphNode

Abstract type for all graph nodes types.
"""
abstract type AbstractGraphNode end 

"""
    get_node_id(b::AbstractGraphNode)   

Get the mapped-id of an `AbstractGraphNode`.

!!! warning
    This method is abstract! A concrete implementation for each concrete node shall be defined.
"""
function get_node_id(b::T) where {T <: AbstractGraphNode}
    throw(ErrorException("`get_node_id` shall be implemented for $T"))
end