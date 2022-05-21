FROM julia:1.7.2-bullseye

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/Amsterdam

ENV JULIA_DEPOT_PATH=/opt

RUN apt-get update && apt-get install -y wget unzip procps

COPY . /UKBMain

WORKDIR /UKBMain

RUN julia -q --project -e'using Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.precompile(); Pkg.test()'