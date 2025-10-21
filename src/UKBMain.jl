module UKBMain

using CSV
using DataFrames
using CategoricalArrays
using HTTP
using Downloads
using DelimitedFiles
using YAML

include("fields_list.jl")
include("ukb_download.jl")
include("datasets_extraction.jl")
include("fields_processing.jl")

export build_fields_list, filter_and_extract

end
