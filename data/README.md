# Data Included In This Snapshot

This directory contains derived, analysis-ready files needed for Tier A manuscript
reproduction.

Included:

- `behavioral/`: processed task-level CSVs for RISK, PIT, and TwoStep sessions 1 and 2.
- `demographics/`: discovery/replication allocation and age metadata used by analyses.
- `exclusions/`: analysis exclusion lists and RT exclusion tables.
- `parameter_estimates/`: canonical `samp10k` cached Stan summaries, subject maps,
  participant parameter estimates, and Spearman/ICC reliability exports.

Excluded:

- Raw Pavlovia exports.
- Questionnaire data and noncanonical task/model families.
- Large Stan posterior draw archives (`*.tsv.gz`).
- Local filesystem symlinks and lab-storage paths.
- Non-`samp10k` duplicate summaries, participant estimates, and reliability exports.

The bundled files are de-identified derived research data for reproducing manuscript
statistics. Confirm consent, IRB, and repository-access requirements before changing a
private copy of this repository to public.

## Anonymization note

Participant identifiers in this copy have been replaced by a random one-to-one relabeling
(applied identically in every file, so within- and across-file links between rows are
unchanged and all analyses run as before). The mapping was not retained; identifiers here do
not correspond to any lab records.
