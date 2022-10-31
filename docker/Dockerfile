FROM julia:1.7.2-bullseye

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/Amsterdam

ENV JULIA_DEPOT_PATH=/opt

RUN apt-get update && apt-get install -y wget unzip procps

## Install ukbconv

RUN wget -nd biobank.ctsu.ox.ac.uk/ukb/util/ukbconv

RUN mv ukbconv /usr/local/bin

RUN chmod +x /usr/local/bin/ukbconv

# Install package

COPY . /UKBMain.jl

WORKDIR /UKBMain.jl

RUN julia -q --project -e'using Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.precompile(); Pkg.test()'