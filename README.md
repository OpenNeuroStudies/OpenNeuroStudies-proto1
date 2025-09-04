This is a prototype super-dataset to 

- bring together all datasets among OpenNeuroDatasets,
  OpenNeuroDerivatives, and potentially other locations/resources into BIDS
  "study" DatasetType datasets.
- provide dahsboards (overall, per study, per dataset, per subject/session) to overview
  the status and summarize across
  - bids-validation
  - mriqc
  - fmriprep
  - potentially harmonity of acquisition in the original raw dataset

It is built using [code/layout_as_studies.sh](code/layout_as_studies.sh) script
prototype, which produced overall [studies.tsv](studies.tsv) file and then per
each study `derivatives.tsv` such as
[study-ds000002/derivatives.tsv](https://github.com/OpenNeuroStudies/OpenNeuroStudies/blob/main/study-ds000002/derivatives.tsv).

For more TODOs etc see the initial https://github.com/OpenNeuroStudies/OpenNeuroStudies/issues/1 .
