# Configuration Guide

This document explains all configuration options for the Snakemake-GROMACS workflow.

## config.yaml

### sample_sheet
Path to TSV file containing samples to simulate.
- **Type**: string
- **Example**: `"config/samples.tsv"`

### simulation

All MD simulation parameters.

#### default_type
Default simulation type if not overridden in samples.tsv.
- **Type**: string
- **Options**: `"aa"` (all-atom) or `"cg"` (coarse-grain)
- **Default**: `"aa"`
- **Note**: Can be overridden per-sample in `samples.tsv`

#### force_field
GROMACS force field identifier. Determines:
- Interaction parameters
- Atom types
- Bonded parameters
- VdW cutoffs

Common force fields:
- **All-atom**: `amber14sb`, `amber99sb`, `gromos54a7`, `charmm36m`, `oplsaa`
- **Coarse-grain**: `martini`, `martini3`, `martini2`

Note: Ensure force field files are installed in your GROMACS data directory.

#### temperature
Simulation temperature in Kelvin.
- **Type**: number
- **Default**: `310` (physiological temperature, ~37°C)
- **Range**: Any positive value, typically 298-373 K
- **Used in**: NVT and NPT equilibration, production runs

#### pressure
Target pressure in Bar.
- **Type**: number
- **Default**: `1.0` (standard atmospheric pressure)
- **Used in**: NPT equilibration and production runs

#### nvt_time
Duration of NVT (constant volume) equilibration in picoseconds.
- **Type**: number
- **Default**: `100` (100 ps)
- **Recommendation**: 50-200 ps for most systems

#### npt_time
Duration of NPT (constant pressure) equilibration in picoseconds.
- **Type**: number
- **Default**: `100` (100 ps)
- **Recommendation**: 50-200 ps for most systems

#### prod_time
Duration of production MD run in picoseconds.
- **Type**: number
- **Default**: `1000` (1 ns)
- **Scaling**:
  - Test/validation: 1-10 ns
  - Standard: 100 ns - 1 μs
  - Protein folding: 1-10 μs+

**Important**: For long simulations on clusters, GROMACS checkpoint files allow continuation across job submissions.

### cluster

Cluster/HPC configuration for job submission.

#### walltime
Maximum wall-clock time per job in format `HH:MM:SS`.
- **Type**: string
- **Default**: `"24:00:00"` (24 hours)
- **Importance**: Critical for long simulations; set slightly less than cluster max
- **Example**: `"48:00:00"` for 2-day limit

**Strategy for long simulations**:
- If your simulation needs 1 μs (1,000,000 ps) but cluster allows 24h:
- Configure multiple shorter production runs (~200 ps each)
- GROMACS checkpoints allow continuation automatically

#### cpus
Number of CPU cores per simulation job.
- **Type**: number
- **Default**: `4`
- **Recommendation**: 4-16 depending on system size
- **Trade-off**: More CPUs = faster but higher resource contention

#### memory
Memory allocation per job in GB.
- **Type**: number
- **Default**: `8`
- **Estimation**: 
  - Small systems (<1000 atoms): 4-8 GB
  - Medium systems (1000-10000 atoms): 8-16 GB
  - Large systems (>10000 atoms): 16-64 GB

#### queue
SLURM partition/queue name.
- **Type**: string
- **Default**: `"default"`
- **Example**: `"gpu"`, `"normal"`, `"long"`, `"interactive"`

**To list available queues**:
```bash
sinfo -s
```

#### email
Email address for job notifications (optional).
- **Type**: string
- **Default**: `""`
- **Requires**: SLURM configured with mail plugin

### output

Output file handling.

#### keep_trajectories
Whether to keep intermediate trajectory files (.trr, .xtc).
- **Type**: boolean
- **Default**: `true`
- **Note**: Trajectories can be large; set to `false` to save disk space

#### compress_trajectories
Whether to compress trajectory files.
- **Type**: boolean
- **Default**: `true`
- **Note**: Compressed trajectories (.xtc) take ~5-10x less space than uncompressed

### analysis

Post-simulation analysis options.

#### extract_energy
Extract energy metrics (potential, kinetic, total).
- **Type**: boolean
- **Default**: `true`

#### calculate_rmsd
Calculate RMSD relative to first frame.
- **Type**: boolean
- **Default**: `true`

#### calculate_rg
Calculate radius of gyration.
- **Type**: boolean
- **Default**: `true`

---

## samples.tsv

Tab-separated file defining simulations to run.

### Columns

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| sample | string | yes | Sample identifier (used in output paths) |
| protein_file | string | yes | Path to structure file (.gro or .pdb) |
| topology_file | string | yes | Path to topology file (.top) |
| sim_type | string | yes | Simulation type: `aa` or `cg` |
| force_field | string | no | Force field (overrides config default) |
| replicate | integer | no | Replicate number (default: 1) |

### Example
```tsv
sample          protein_file            topology_file            sim_type    force_field
alanine_aa      input/ala_aa.gro        input/ala_aa.top         aa          amber14sb
alanine_cg      input/ala_cg.gro        input/ala_cg.top         cg          martini3
lysozyme_aa     input/lysozyme.gro      input/lysozyme.top       aa          amber99sb
```

### Notes
- File paths are relative to workflow root
- Duplicate samples with `replicate > 1` create independent runs
- Force field override allows different force fields per sample

---

## MDP Files

MD parameter files control simulation details. Located in `workflow/scripts/mdp/`.

### Modifying MDP Files

Key parameters to adjust:

| Parameter | File | Effect | Example |
|-----------|------|--------|---------|
| `nsteps` | all | Total simulation length | `nsteps = 50000` = 100 ps (with dt=0.002) |
| `dt` | all | Time step in ps | `dt = 0.001` for 1 fs steps |
| `ref_t` | nvt, npt, prod | Temperature setpoint | `ref_t = 310` for 37°C |
| `Pref` | npt, prod | Pressure setpoint | `Pref = 1.0` for 1 atm |
| `tau_t` | nvt, npt, prod | Temperature coupling | `tau_t = 0.1` stronger coupling |
| `tau_p` | npt, prod | Pressure coupling | `tau_p = 2.0` |
| `nstxout-compressed` | prod | Trajectory save frequency | Save every Nth step |

### Template customization for different systems

**For protein AA simulations**:
- Use `amber14sb` force field
- `nvt_time = 100 ps`
- `npt_time = 100 ps`

**For CG simulations (MARTINI)**:
- Use `martini3` force field
- Adjust `dt = 0.020` (larger time step for CG)
- `ref_t = 310` for room temperature in CG

---

## Cluster-Specific Setup

### SLURM Configuration

Edit `profiles/slurm/config.yaml`:

```yaml
executor: slurm
jobs: 10
account: "my_account"
partition: "normal"
time: "24:00:00"
mem: 8G
cpus-per-task: 4
mail-type: END
mail-user: user@institution.edu
```

### GROMACS Modules on HPC

If using module system:
```bash
module load gromacs/2023.1
snakemake --profile profiles/slurm --jobs 5
```

Or set in Snakefile:
```python
shell.prefix("module load gromacs/2023.1; ")
```

---

## Troubleshooting Configuration

**Issue**: "Unrecognized force field"
- Check force field name against GROMACS installation
- Verify `.ff` directory exists in GROMACS data path

**Issue**: "Insufficient memory"
- Reduce `memory` in cluster config
- Or increase for larger systems

**Issue**: "Simulation too slow"
- Increase `cpus` for parallelization
- Check MDP `dt` value (too small = slow)

**Issue**: "Output files too large"
- Set `keep_trajectories: false`
- Reduce `nstxout-compressed` frequency in .mdp files
- Compress output with `compress_trajectories: true`
