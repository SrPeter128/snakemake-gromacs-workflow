# Execution Profiles

This directory contains Snakemake profiles for different execution environments.

## Local Profile (default)

Run workflow on your local machine using available cores.

### Usage
```bash
snakemake --cores 4          # Use 4 cores
snakemake --cores all        # Use all available cores
```

### Configuration
Adjust in main `config/config.yaml`:
- `cluster.cpus`: Not used for local execution
- `cluster.memory`: Not strictly enforced (advisory)

---

## SLURM Profile

Submit jobs to a SLURM-managed HPC cluster.

### Usage
```bash
snakemake --profile profiles/slurm --jobs 10
```

This submits up to 10 jobs simultaneously to the cluster.

### Configuration Files

**profiles/slurm/config.yaml**: Snakemake-SLURM settings
- Job submission parameters
- Queue/partition selection
- Resource limits

**config/config.yaml (cluster section)**:
- Job-specific parameters (cpus, memory, walltime)
- Email notifications

### Setup Steps

1. **Verify SLURM availability**:
```bash
which sinfo
sinfo -s          # List available partitions
```

2. **Customize profiles/slurm/config.yaml**:
```yaml
executor: slurm
account: "your_project"
partition: "normal"
time: 1440        # Minutes (24 hours)
mem: 8G
cpus: 4
mail-type: "END,FAIL"
mail-user: "your.email@institution.edu"
```

3. **Customize config/config.yaml cluster section**:
```yaml
cluster:
  walltime: "24:00:00"     # Must match SLURM time
  cpus: 4
  memory: 8
  queue: "normal"          # Partition name
  email: "your@email.edu"
```

4. **Run with SLURM profile**:
```bash
snakemake --profile profiles/slurm --jobs 5
```

### Resource Management

**Understanding resource allocation**:
- `cpus`: Threads per GROMACS job (typically 4-8)
- `memory`: RAM per job (scales with system size)
- `walltime`: Maximum job duration (critical for long simulations)

**Example for 4 parallel jobs**:
```bash
snakemake --profile profiles/slurm --jobs 4
# Submits 4 jobs, each requesting:
#   - 4 CPUs (from config.yaml)
#   - 8 GB RAM
#   - 24-hour time limit
```

### Job Time Limits & Long Simulations

SLURM enforces wall-clock time limits. For simulations exceeding these limits:

1. **Configure shorter production runs**:
```yaml
simulation:
  prod_time: 200000  # 400 ps per job
```

2. **GROMACS handles restarts automatically**:
- Production rule detects existing `.cpt` checkpoint
- Injects `-cpi` flag for restart
- Snakemake resubmits if job times out

3. **Example**: 1 μs (1,000,000 ps) simulation on 24h cluster
```yaml
# Split into 5 jobs × 200 ps each
prod_time: 200000
```

### Monitoring SLURM Jobs

```bash
# View submitted jobs
squeue -u $USER

# Check job status
scontrol show job <jobid>

# View job error
tail slurm-<jobid>.out

# Cancel a job
scancel <jobid>
```

### Common Issues

**Issue**: "Job stuck in queue"
- Check partition availability: `sinfo -s`
- Verify resource requests aren't excessive
- Check account/project allocation

**Issue**: "QOSMaxMemoryPerNode exceeded"
- Reduce `memory` in config.yaml
- Or use less CPU cores

**Issue**: "Time limit reached"
- Increase `walltime` in config.yaml (if cluster allows)
- Or split simulations into shorter runs

**Issue**: "Mail notifications not working"
- Verify SLURM mail plugin installed: `scontrol show config | grep MailProg`
- Check email is valid

### Advanced Configuration

**Using job arrays for multiple replicates**:
```bash
snakemake --profile profiles/slurm --jobs 20 \
  --config sample_sheet="config/samples_replicates.tsv"
```

**Using GPU nodes** (if available):
Edit `profiles/slurm/config.yaml`:
```yaml
gres: "gpu:1"          # Request 1 GPU
partition: "gpu_queue"
```

GROMACS uses GPUs with: `gmx mdrun -gpu`

### Further Resources

- [Snakemake SLURM integration](https://snakemake.readthedocs.io/en/stable/executing/cluster.html)
- [SLURM documentation](https://slurm.schedmd.com/sbatch.html)
- [GROMACS on HPC clusters](https://manual.gromacs.org/documentation/current/user-guide/mdrun-performance.html)
