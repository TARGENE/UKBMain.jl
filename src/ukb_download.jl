download_fields_metadata(;output="fields_metadata.txt") = 
    Downloads.download("biobank.ndph.ox.ac.uk/ukb/scdown.cgi?fmt=txt&id=1", output)

read_fields_metadata(;input="fields_metadata.txt") =
    CSV.read(input, DataFrame)

function download_datacoding_6(;output="ukb_datacoding_6.tsv")
    open(output, "w") do io
        HTTP.post(
            "https://biobank.ndph.ox.ac.uk/showcase/codown.cgi", 
            Dict(
                "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                "Accept-Encoding"=>"gzip, deflate, br",
                "Accept-Language"=>"en-GB,en;q=0.5",
                "Connection"=>"keep-alive",
                "Content-Length"=>"4",
                "Content-Type"=>"application/x-www-form-urlencoded",
                "Host"=> "biobank.ndph.ox.ac.uk",
                "Origin"=>"https://biobank.ndph.ox.ac.uk",
                "Referer"=> "https://biobank.ndph.ox.ac.uk/showcase/coding.cgi?id=6",
                "Sec-Fetch-Dest"=>"document",
                "Sec-Fetch-Mode"=> "navigate",
                "Sec-Fetch-Site"=> "same-origin",
                "Sec-Fetch-User"=>"?1",
                "Upgrade-Insecure-Requests"=> "1",
        ),
            Dict("id"=>"6");
            response_stream=io
        )
    end
end

function read_datacoding_6(;input="ukb_datacoding_6.tsv")
    data = CSV.read(input, DataFrame)
    data = filter(:coding => !=(-1), data)
    return data[:, [:coding, :meaning]]
end

function download_datacoding_19(;output="ukb_datacoding_19.tsv")
    open(output, "w") do io
        HTTP.post(
            "https://biobank.ndph.ox.ac.uk/showcase/codown.cgi", 
            Dict(
                "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                "Accept-Encoding"=>"gzip, deflate, br",
                "Accept-Language"=>"en-GB,en;q=0.5",
                "Connection"=>"keep-alive",
                "Content-Length"=>"5",
                "Content-Type"=>"application/x-www-form-urlencoded",
                "Host"=> "biobank.ndph.ox.ac.uk",
                "Origin"=>"https://biobank.ndph.ox.ac.uk",
                "Referer"=> "https://biobank.ndph.ox.ac.uk/showcase/coding.cgi?id=19",
                "Sec-Fetch-Dest"=>"document",
                "Sec-Fetch-Mode"=> "navigate",
                "Sec-Fetch-Site"=> "same-origin",
                "Sec-Fetch-User"=>"?1",
                "Upgrade-Insecure-Requests"=> "1",
        ),
            Dict("id"=>"19");
            response_stream=io
        )
    end
end


function read_datacoding_19(;input="ukb_datacoding_19.tsv")
    data = CSV.read(input, DataFrame)
    return data[:, [:coding, :meaning]]
end


function download_and_read_codings()
    download_datacoding_6()
    download_datacoding_19()

    return Dict(6=>read_datacoding_6(), 19 => read_datacoding_19())
end