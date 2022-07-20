using SlurmHyperopt
using Documenter

DocMeta.setdocmeta!(SlurmHyperopt, :DocTestSetup, :(using SlurmHyperopt); recursive=true)

makedocs(;
    modules=[SlurmHyperopt],
    authors="Maximilian Gelbrecht <maximilian.gelbrecht@posteo.de> and contributors",
    repo="https://github.com/maximilian-gelbrecht/SlurmHyperopt.jl/blob/{commit}{path}#{line}",
    sitename="SlurmHyperopt.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://maximilian-gelbrecht.github.io/SlurmHyperopt.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/maximilian-gelbrecht/SlurmHyperopt.jl",
    devbranch="main",
)
