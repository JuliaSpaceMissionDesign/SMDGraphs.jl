using Documenter, SMDGraphs

makedocs(;
    authors="Julia Space Mission Design Development Team",
    sitename="SMDGraphs.jl",
    modules=[SMDGraphs],
    pages=[
        "Home" => "index.md", 
        "Graph Types" => [
            "Mapped Graphs" => "mappedgraph.md"
        ],
        "API" => "api.md"
    ],

)

deploydocs(; repo="github.com/JuliaSpaceMissionDesign/SMDGraphs.jl", branch="gh-pages")
