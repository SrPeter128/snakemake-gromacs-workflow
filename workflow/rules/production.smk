# Production Run
# Main MD simulation with checkpoint/restart capability
# Supports multiple replicates with different random seeds

rule production:
    input:
        structure="results/{sample}/equilibrate/npt.gro",
        topology="results/{sample}/topology/{sample}.top",
        mdp="workflow/scripts/mdp/prod.mdp",
    output:
        structure="results/{sample}/production/rep{replicate}/prod.gro",
        checkpoint="results/{sample}/production/rep{replicate}/prod.cpt",
        trajectory="results/{sample}/production/rep{replicate}/prod.xtc",
        energy="results/{sample}/production/rep{replicate}/prod_energy.edr",
    log:
        "results/{sample}/production/rep{replicate}/prod.log",
    message:
        """--- Production MD run for {wildcards.sample} (replicate {wildcards.replicate}) ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
        seed=lambda wildcards: get_prod_seed(wildcards.sample, int(wildcards.replicate)),
    shell:
        """
        cd $(dirname {output.structure})
        
        # Check for checkpoint file and restart if exists
        if [ -f prod.cpt ]; then
            gmx grompp -f ../../../../{input.mdp} \
                       -c ../../../../{input.structure} \
                       -p ../../../../{input.topology} \
                       -t prod.cpt \
                       -o prod.tpr -v > ../../../../{log} 2>&1
            gmx mdrun -deffnm prod -cpi prod.cpt -seed {params.seed} >> ../../../../{log} 2>&1
        else
            gmx grompp -f ../../../../{input.mdp} \
                       -c ../../../../{input.structure} \
                       -p ../../../../{input.topology} \
                       -o prod.tpr -v > ../../../../{log} 2>&1
            gmx mdrun -deffnm prod -seed {params.seed} >> ../../../../{log} 2>&1
        fi
        
        mv prod.gro ../../../../{output.structure}
        mv prod.cpt ../../../../{output.checkpoint}
        mv prod.xtc ../../../../{output.trajectory}
        mv prod.edr ../../../../{output.energy}
        """

