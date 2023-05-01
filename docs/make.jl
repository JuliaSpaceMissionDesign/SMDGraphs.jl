using Documenter, SMDGraphs 

makedocs(;
    authors="Julia Space Mission Design Development Team",
    sitename="SMDGraphs.jl",
    modules=[SMDGraphs],
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(; 
    repo="github.com/JuliaSpaceMissionDesign/SMDGraphs.jl",
)