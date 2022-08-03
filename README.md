# UKBMain

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://olivierlabayle.github.io/UKBMain.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://olivierlabayle.github.io/UKBMain.jl/dev)
[![Build Status](https://github.com/olivierlabayle/UKBMain.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/olivierlabayle/UKBMain.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/olivierlabayle/UKBMain.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/olivierlabayle/UKBMain.jl)

This package aims at providing various command line interfaces to manipulate a UKB main dataset in order to generate `phenotypes`, `confounders`, `covariates` and `treatments` files. The specification of this process is done via a YAML configuration file for which a base is provided in `config/config.yaml`.

The associated docker image, hosted on [Docker Hub](https://hub.docker.com/r/olivierlabayle/ukbmain), provides an environment to run all of the commands described below.

## Writing the YAML configuration file

The data in a UKB main dataset is organised in fields. The fields themselves may not represent a specific trait but a list of traits organised in array and/or instances (see the [Accessing data guide](https://biobank.ndph.ox.ac.uk/~bbdatan/Accessing_UKB_data_v2.3.pdf)). An example configuration file corresponding to the traits reported by the [gene ATLAS](http://geneatlas.roslin.ed.ac.uk/) is provided in `config/config.yaml` and if you want to run a generic PheWAS it may simply be used as it is.

This YAML file contains up to 5 main entries:

- phenotypes
- confounders
- covariates
- treatments
- subset

Each entry is further organised as a list of traits of interest. Depending on their data type, the traits can be queried in any of the following ways:

- Continuous and Integer variables: Those can be queried by providing the associated UKB field-id. This can be done either as a single field or list of fields to make the file more readable. The optional "field" keyword can be used. Only the first column (`-0.0`) of the field, usually corresponding to the first assessment visit, is used.
- Categorical variables: The behavior is different depending on the field and output file:
  - Disease fields 40006, 20002, 41202, 41204: The keyword `field` must be used. Those variables are encoded by the UKB as lists and will be converted to binary variables indicating the presence/absence of a specific trait. When encoded by ICD10 codes, those traits can be defined either by the exact code or by parent codes or blocks. For instance the code `A010` represents Typhoid Fever while the code `A01` represents Typhoid and paratyphoid fevers. Further `A01-A03` represents either Typhoid and paratyphoid fevers, Other Salmonella infections or Shigellosis. Further definition of aggregated diseases can be defined by the keywords `any` and `name` where `any` is a list of codes and `name` is the name of the aggregate. Finally, we also provide the ability to consider the union of fields themselves, as long as they are encoded in the same way (for instance 41202, 41204) to define trait with the "FIELD_1 | FIELD_2 | ..." pattern.
  - Other categorical variables: Only the first column (`-0.0`) is used and will be one hot encoded (except for extra treatments). If no codings are specified, all codes will be extracted, otherwise only those specified will be extracted.
  - Categorical variables for treatments: Values are simply extracted per the given codes (or all codes if none is provided).
- Ordinal variables: Some traits are declared as categorical by the UKB but an ordinal interpretation may be more appropriate. We have identified and hardcoded a list of such traits in the `ORDINAL_FIELDS` constant.

For further examples, look into the `test/config` folder.
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
julia --project --startup-file=no src/fields_processing.jl UKBMAIN_PATH --conf CONF.yaml --out-prefix OUT_PREFIX --withdrawal-list WITHDRAWAL_LIST
```

where `UKBMAIN_PATH` is the output from the previous command.