# import basic packages
import pandas as pd
from snakemake.utils import validate

# read sample sheet
samples = (
    pd.read_csv(config["sample_sheet"], sep="\t", dtype={"sample": str})
    .set_index("sample", drop=False)
    .sort_index()
)

# Set default values for optional columns
if "prod_replicates" not in samples.columns:
    samples["prod_replicates"] = 1
samples["prod_replicates"] = samples["prod_replicates"].fillna(1).astype(int)

# validate sample sheet and config file
validate(samples, schema="../schemas/samples.schema.yaml")
validate(config, schema="../schemas/config.schema.yaml")

# helper functions
def get_sim_type(sample):
    return samples.loc[sample, "sim_type"]

def get_prod_replicates(sample):
    return int(samples.loc[sample, "prod_replicates"])

def get_prod_seed(sample, replicate_id):
    """Generate a unique seed for each production replicate based on sample and replicate ID"""
    # Use base seed 42 + sample hash + replicate_id to ensure variety
    base_seed = 42
    sample_hash = sum(ord(c) for c in sample) % 1000
    return base_seed + sample_hash + (replicate_id * 100000)

