using JuDO
using Documenter

DocMeta.setdocmeta!(JuDO, :DocTestSetup, :(using JuDO); recursive=true)

makedocs(;
    modules=[JuDO],
    authors="Haochen Tao <54142141+shawn-tao01@users.noreply.github.com> and contributors",
    repo="https://github.com/JuDO-dev/JuDO.jl/blob/{commit}{path}#{line}",
    sitename="JuDO.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuDO-dev.github.io/JuDO.jl",
        edit_link="dev",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Tutorials" => [
        "Solving a DOP" => "Tutorials/solving_a_dop.md",
        ],
        "Manual" => [
            "Dynamic Optimization Model" => "Manual/model.md",
            "Phase" => "Manual/phase.md",
            "Dynamic Variable" => "Manual/variable.md",
            "Constraints" => "Manual/constraints.md",
            "Derivatives" => "Manual/derivative.md",
            "Objective" => "Manual/objective.md",
            "Solutions" => "Manual/solutions.md",
        ],
        "API Reference" => ["API.md"],
    ],
)

deploydocs(;
    repo="github.com/JuDO-dev/JuDO.jl",
    devbranch="dev",
)
