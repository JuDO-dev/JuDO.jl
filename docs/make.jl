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
    ],
)

deploydocs(;
    repo="github.com/JuDO-dev/JuDO.jl",
    devbranch="dev",
)
