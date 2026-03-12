#!/usr/bin/env bash
# SLURM job submission template for Snakemake
# This is auto-populated by Snakemake from the rule directives

# Job info
#SBATCH --job-name={rule}_{wildcards}
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

# Resource requests (from config)
#SBATCH --ntasks=1
#SBATCH --cpus-per-task={resources.cpus}
#SBATCH --mem={resources.mem}
#SBATCH --time={cluster.walltime}
#SBATCH --partition={cluster.queue}

# Optional: Account and mail
#SBATCH --account={cluster.account}
#SBATCH --mail-user={cluster.email}
#SBATCH --mail-type=END,FAIL

# Load modules if needed
# module load gromacs/2023.1

# Execute job
{exec_job}
