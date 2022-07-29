using Test
using UKBMain

@testet "Test selectable_codings" begin
    encoding = UKBMain.download_and_read_datacoding(19)
    coding = "A34"
    result = UKBMain.selectable_codings(coding, encoding)
    @test result == ["A34"]
    coding = "A22"
    result = UKBMain.selectable_codings(coding, encoding)
    @test result == ["A220", "A221", "A222", "A227", "A228", "A229"]
    coding = "J40-J47"
    result = UKBMain.selectable_codings(coding, encoding)
    @test result == ["J40", "J410", "J411", "J418", "J42", "J430", 
                    "J431", "J432", "J438", "J439", "J440", "J441", 
                    "J448", "J449", "J450", "J451", "J458", "J459", "J46", "J47"]
    coding = "C00-C14"
    result = UKBMain.selectable_codings(coding, encoding)
    @test result == ["C000", "C001", "C002", "C003", "C004", "C005", "C006", 
                     "C008", "C009", "C01", "C020", "C021", "C022", "C023", 
                     "C024", "C028", "C029", "C030", "C031", "C039", "C040", 
                     "C041", "C048", "C049", "C050", "C051", "C052", "C058", 
                     "C059", "C060", "C061", "C062", "C068", "C069", "C07", 
                     "C080", "C081", "C088", "C089", "C090", "C091", "C098", 
                     "C099", "C100", "C101", "C102", "C103", "C104", "C108", 
                     "C109", "C110", "C111", "C112", "C113", "C118", "C119", 
                     "C12", "C130", "C131", "C132", "C138", "C139", "C140", 
                     "C142", "C148"]
end