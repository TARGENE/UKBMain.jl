using UKBMain
using Documenter

DocMeta.setdocmeta!(UKBMain, :DocTestSetup, :(using UKBMain); recursive=true)

makedocs(;
    modules=[UKBMain],
    authors="Olivier Labayle",
    repo="https://github.com/olivierlabayle/UKBMain.jl/blob/{commit}{path}#{line}",
    sitename="UKBMain.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://olivierlabayle.github.io/UKBMain.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/olivierlabayle/UKBMain.jl",
    devbranch="main",
)
