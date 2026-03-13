# Snakemake-GROMACS Workflow

A modular, reproducible Snakemake workflow for running GROMACS molecular dynamics (MD) simulations with support for both all-atom (AA) and coarse-grain (CG) simulations.

## Features

- **Configuration-driven**: Fully customizable via YAML config files (no hard-coded parameters)
- **All-atom & Coarse-grain support**: User-selectable simulation type per sample
- **Production replicates**: Run multiple independent production simulations with different random seeds
- **Local & HPC execution**: Run locally or submit to SLURM clusters
- **Checkpoint & restart**: Long-running jobs can be split and restarted using GROMACS `.cpt` files
- **Reproducible**: Fixed random seeds, version control, parameter traceability
- **Modular design**: Independent rules for each simulation stage (prep, minimize, equilibrate, production, analysis)
- **MDP template files**: Pre-configured MD parameter files for easy customization

## Requirements

### External
- **GROMACS** (version 2020+): Must be installed and available as `gmx` command
  - [Installation guide](https://manual.gromacs.org/documentation/current/install-guide/index.html)
- **Snakemake** (version ≥8.0): Installed with the workflow
  - Install via pip or conda-forge

### Input Files
- Protein structure files (`.gro`, `.pdb`)
- Topology files (`.top`)
- MDP parameter files (examples provided in `workflow/scripts/mdp/`)

## Quick Start

### 1. Setup
```bash
# Clone the workflow
git clone <repo-url>
cd snakemake-gromacs-workflow
TBD
```

### 2. Prepare Input Data
Create `input/` directory with your structure and topology files:
```
input/
  ├── protein1.gro
  ├── protein1.top
  ├── protein2.gro
  └── protein2.top
```

### 3. Configure Simulation
Edit `config/config.yaml`:
```yaml
sample_sheet: "config/samples.tsv"

simulation:
  default_type: "aa"              # 'aa' or 'cg'
  force_field: "amber14sb"        # GROMACS force field
  temperature: 310                # K (physiological)
  pressure: 1.0                   # Bar
  nvt_time: 100                   # ps
  npt_time: 100                   # ps
  prod_time: 1000                 # ps (adjust as needed)

cluster:
  walltime: "24:00:00"            # Per-job time limit
  cpus: 4
  memory: 8                       # GB
  queue: "default"
```

Edit `config/samples.tsv`:
```
sample	protein_file	topology_file	sim_type	force_field	prod_replicates
protein1	input/protein1.gro	input/protein1.top	aa	amber14sb	3
protein2	input/protein2.gro	input/protein2.top	cg	martini3	2
```

### 4. Run Locally
```bash
# Dry run (check workflow)
snakemake --dry-run

# Run with 4 cores
snakemake --cores 24

# Run with conda environments for analysis
snakemake --cores 24 --use-conda
```

### 5. Run on SLURM Cluster
```bash
# Using SLURM profile
snakemake --profile profiles/slurm --jobs 10
```

## Workflow Stages

### 1. **Topology Preparation** (`prepare_topology`)
- Copies structure and topology files to results directory
- Handles AA/CG-specific parameter preparation

### 2. **Energy Minimization** (`energy_minimize`)
- Steepest descent energy minimization
- Removes steric clashes and invalid geometries
- Uses `em.mdp` parameters

### 3. **NVT Equilibration** (`nvt_equilibrate`)
- Canonical ensemble equilibration (constant V, T)
- Equilibrates at target temperature
- Uses `nvt.mdp` parameters

### 4. **NPT Equilibration** (`npt_equilibrate`)
- Isothermal-isobaric equilibration (constant P, T)
- Allows box volume to relax
- Uses `npt.mdp` parameters

### 5. **Production Run** (`production`)
- Main MD simulation with checkpoint capability
- Checkpoints written every ~10 ps (configurable)
- Supports restart from `.cpt` files for long runs
- **Supports multiple replicates** with different random seeds per sample
- Uses `prod.mdp` parameters

### 6. **Analysis** (`extract_energy`, `trajectory_analysis`)
- Energy extraction (potential, kinetic, etc.)
- RMSD calculation relative to first frame
- Radius of gyration (Rg)
- **Analyzes each production replicate independently**
- Trajectory analysis (requires MDAnalysis)

## Configuration Details

### All-Atom (AA) vs. Coarse-Grain (CG)

Per-sample simulation type is specified in `samples.tsv`:

```tsv
sample          protein_file    topology_file    sim_type    force_field
my_aa_sim       input/alanine.gro  input/alanine.top   aa          amber14sb
my_cg_sim       input/alanine.gro  input/alanine.top   cg          martini3
```

The workflow automatically:
- Selects appropriate force field defaults
- Validates parameter files
- Ensures MDP files match simulation type

### Production Replicates

Run multiple independent production MD simulations with different random seeds:

```tsv
sample          protein_file         topology_file         sim_type    force_field    prod_replicates
myprotein_aa    input/protein.gro    input/protein.top     aa          amber14sb      3
myprotein_cg    input/protein.gro    input/protein.top     cg          martini3       5
```

**Features**:
- Specify `prod_replicates` column in `samples.tsv` (default: 1)
- Each replicate uses a unique random seed (automatically generated)
- All replicates share the same equilibrated structure (from NPT)
- Analysis runs independently on each replicate
- Results organized in `results/{sample}/production/rep{N}/` directories

**Why replicates?**
- Better statistics through ensemble averaging
- Test convergence and reproducibility
- Generate confidence intervals for observables
- Explore different folding pathways (for proteins)

### MDP Files

Located in `workflow/scripts/mdp/`:
- **em.mdp**: Energy minimization (steepest descent)
- **nvt.mdp**: NVT equilibration (constant volume/temp)
- **npt.mdp**: NPT equilibration (constant pressure/temp)
- **prod.mdp**: Production run (main simulation)

Customize parameters in these files before running. Common adjustments:
- `nsteps`: Simulation length (default: suitable for testing)
- `ref_t`: Temperature (default: 310 K)
- `Pref`: Pressure (default: 1.0 bar)
- `tau_t`, `tau_p`: Coupling time constants

### Cluster Configuration

Edit `cluster` section in `config/config.yaml` and customize `profiles/slurm/config.yaml` for your cluster:

```yaml
cluster:
  walltime: "24:00:00"    # Max time per job
  cpus: 4                 # CPUs per job
  memory: 8               # Memory in GB
  queue: "normal"         # Partition name
  email: "user@email.com" # Job notifications
```

## Handling Long Simulations

For simulations exceeding cluster time limits:

1. **Configure job time limit**:
   ```yaml
   cluster:
     walltime: "24:00:00"  # 24-hour time limit
   ```

2. **Production rule restarts from checkpoint**:
   - GROMACS writes `.cpt` files regularly (every ~10 ps)
   - Snakemake re-runs production if timeout occurs
   - `-cpi` flag automatically injects checkpoint restart

3. **Adjust production time**:
   ```yaml
   simulation:
     prod_time: 50000  # Increase for longer runs (in ps)
   ```

Example workflow for 1 μs (1,000,000 ps) simulation on 24h cluster:
- Split into 5 jobs × 200 ps production each
- Each restarts from previous checkpoint
- Total compute time: manageable per queue

## Output Structure

```
results/
├── {sample}/
│   ├── topology/
│   │   ├── {sample}.gro
│   │   └── {sample}.top
│   ├── minimize/
│   │   ├── minimized.gro
│   │   ├── em_energy.edr
│   │   ├── em.trr
│   │   └── minimized.cpt
│   ├── equilibrate/
│   │   ├── nvt.gro, nvt.cpt, nvt_energy.edr
│   │   └── npt.gro, npt.cpt, npt_energy.edr
│   ├── production/
│   │   ├── prod.gro
│   │   ├── prod.xtc    (trajectory)
│   │   ├── prod.cpt    (checkpoint for restart)
│   │   └── prod_energy.edr
│   └── analysis/
│       ├── energy.xvg  (energy time series)
│       ├── rmsd.xvg    (RMSD vs. time)
│       ├── radius_gyration.xvg
│       └── report.html
```

## Troubleshooting

### GROMACS not found
```bash
# Check GROMACS installation
which gmx
gmx --version

# If not in PATH, add to environment
export PATH=/path/to/gromacs/bin:$PATH
```

### Dry-run shows missing input files
Ensure:
- Input files exist in `input/` directory
- `samples.tsv` has correct paths relative to workflow root
- File extensions match (`.gro`, `.top`)

### Job fails with "force field not recognized"
Check:
- Force field specified in `samples.tsv` matches GROMACS installation
- All force field files (.ff directories) are in GROMACS data path

### Checkpoint restart not working
Verify:
- Production `.cpt` files exist in `results/{sample}/production/`
- GROMACS version supports checkpoint feature (all modern versions do)
- Disk space available for trajectory files

### Memory errors during `gmx mdrun`
Reduce:
- Number of cores per job (decrease `cpus` in config)
- Trajectory output frequency (increase `nstxout-compressed` in `prod.mdp`)
- System size (equilibrate with smaller systems first)

## Profiles

### Local Profile (default)
```bash
snakemake --cores 4
```

### SLURM Profile
```bash
snakemake --profile profiles/slurm --jobs 10
```

Edit `profiles/slurm/config.yaml` for cluster-specific settings.

## Advanced: Customizing Analysis

Edit `workflow/rules/analysis.smk` to add custom analyses:
- Trajectory clustering
- Conformational sampling
- Free energy calculations
- Contact analysis

## Authors

- Workflow template: Snakemake Workflow Catalog
- GROMACS integration: [Your Name/Organization]

## References

- GROMACS: http://www.gromacs.org/
- Snakemake: https://snakemake.readthedocs.io/
- MARTINI force field: http://cgmartini.nl/

## License

[Add your license here]
