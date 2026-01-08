using JuDO
using Documenter

DocMeta.setdocmeta!(JuDO, :DocTestSetup, :(using JuDO); recursive=true)

const _PAGES = [
        "Home" => "index.md",
        
        # Section for your Examples
        "Tutorials" => [
            "Getting Started" => "tutorials/getting_started.md",
            "Cart-Pole Swing-Up" => "tutorials/cartpole.md",
            "Space Shuttle Reentry" => "tutorials/shuttle.md",
        ],
        
        # Section for your Types and Functions
        "API Reference" => [
            "Public Interface" => "reference/public.md",
            "Types" => "reference/types.md",
            "Internals" => "reference/internals.md",
        ],
    ]

makedocs(;
    modules=[JuDO],
    authors="Haochen Tao <54142141+shawn-tao01@users.noreply.github.com> and contributors",
    repo="https://github.com/JuDO-dev/JuDO.jl/blob/{commit}{path}#{line}",
    sitename="JuDO.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://judo.dev/JuDO.jl",
        edit_link="dev",
        assets=String[],
    ),
    pages=_PAGES,
)

deploydocs(;
    repo="github.com/JuDO-dev/JuDO.jl",
    devbranch="dev",
)
