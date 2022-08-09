# UKBMain

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/TARGENE/TargeneCore.jl/CI/main?label=Build%20main)
![Codecov branch](https://img.shields.io/codecov/c/github/TARGENE/TargeneCore.jl/main?label=Coverage%20main)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/TARGENE/TargeneCore.jl)

This package aims at providing various command line interfaces to manipulate a UKB main dataset in order to generate `phenotypes`, `confounders` and `covariates` files. The specification of this process is done via a YAML configuration file for which a base is provided in `config/config.yaml`.

The associated docker image, hosted on [Docker Hub](https://hub.docker.com/r/olivierlabayle/ukbmain), provides an environment to run all of the commands described below and is.

## Writing the YAML configuration file

The data in a UKB main dataset is organised in fields. The fields themselves may not represent a specific trait but a list of traits organised in array and/or instances (see the [Accessing data guide](https://biobank.ndph.ox.ac.uk/~bbdatan/Accessing_UKB_data_v2.3.pdf)). An example configuration file corresponding to the traits reported by the [gene ATLAS](http://geneatlas.roslin.ed.ac.uk/) is provided in `config/config.yaml` and if you wish to run a generic PheWAS it may simply be used as it is.

This YAML file contains up to 4 main entries:
- phenotypes
- confounders
- covariates
- subset (Only accepts categorical variables for now, see below)

Each entry is further organised as a list of traits of interest. Depending on their data type, the traits can be queried in any of the following ways:

- Continuous and Integer variables: Those can be queried by providing the associated UKB field-id. This can be done either as a single field or list of fields to make the file more readable. The optional "field" keyword can be used.
- Categorical variables: Those variables will be converted to binary variables indicating the presence/absence of a specific trait. The keyword "field" must be used. Since categorical variables are encoded by the UKB, a list of required codings must be provided. Those codings can be specified as a list or single value. We also provide the ability to aggregate multiple traits into a union, using the "any" keyword together with a "name" keyword to identify the group. To be more precise about the process, the presence of a coding in any of the array/instance columns of the UKB main dataset will result in the trait (identified by the coding) being declared present. Respectively, the absence of the coding in any of the array/instance columns will result in the trait considered not declared. The caveat behind this approach is that missing values will be considered as "no trait". This behaviour is exactly what is expected when considering fields such as 40006 but may be considered inapropriate for a field such as 1707. However, this approach is quite conservative, potential limits only concern 1707, 1777 and 3079 at the moment and seem marginal given the statistics.
- Union of Categorical variables: Finally, we also provide the ability to consider the union of fields themselves to define trait with the "FIELD_1 | FIELD_2 | ..." pattern.
- Ordinal variables: Some traits are declared as categorical by the UKB but an ordinal interpretation may be more appropriate. We have identified and hardcoded a list of such traits in the `ORDINAL_FIELDS` constant.

## A Typical workflow

### 1. Extract fields-list from the YAML configuration file

This is typically used before a call to `ukbconv` which requires a list of fields of interest in a `.txt` file.

```bash
julia --project --startup-file=no scripts/build_fields_list.jl --conf CONF.yaml --output OUTPUT_FIELDS_PATH
```
### 2. Run ukbconv with the extracted fields-list 

See the man page for ukbconv, but a typical example would be:

```bash
./ukbconv ENCRYPTED_UKBMAIN_FILE csv -iOUTPUT_FIELDS_PATH -oUKBMAIN_PATH
```

where `OUTPUT_FIELDS_PATH` is the output from the previous command.

### 3. Subset/Convert/Split a CSV UKB main dataset into organised subsets

```bash
julia --project --startup-file=no src/fields_processing.jl UKBMAIN_PATH --conf CONF.yaml --out-prefix OUT_PREFIX
```

where `UKBMAIN_PATH` is the output from the previous command.