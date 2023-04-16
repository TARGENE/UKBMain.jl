module TestFieldsProcessing

using DataFrames
using Test
using UKBMain

@testset "Test misc functions" begin
    data = DataFrame(
        A = [1.0, missing, 2.0],
        B = [1, missing, 2],
        C = [1., 2., 3.]
    )
    intA = UKBMain.maybe_convert_to_int(data.A)
    @test eltype(intA) === Union{Missing, Int}
    intB = UKBMain.maybe_convert_to_int(data.B)
    @test intB === data.B
    intC = UKBMain.maybe_convert_to_int(data.C)
    @test eltype(intC) === Int


end

end

true