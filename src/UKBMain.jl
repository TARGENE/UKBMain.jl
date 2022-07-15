module UKBMain
using CSV
using DataFrames
using CategoricalArrays
using MLJModels
using MLJModelInterface
using MLJBase
using HTTP
using Downloads
using DelimitedFiles
using SparseArrays
using YAML

include("fields_list.jl")
include("ukb_download.jl")

export build_fields_list, csvmerge

function csvmerge(parsed_args)
    csv₁ = CSV.read(parsed_args["csv1"], DataFrame)
    csv₂ = CSV.read(parsed_args["csv2"], DataFrame)
    CSV.write(parsed_args["out"], innerjoin(csv₁, csv₂, on=:SAMPLE_ID))
end

end
