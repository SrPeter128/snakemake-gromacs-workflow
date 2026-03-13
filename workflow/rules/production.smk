# Production Run
# Main MD simulation with checkpoint/restart capability
# Supports multiple replicates with different random seeds

rule production:
    input:
        structure="results/{sample}/equilibrate/npt.gro",
        topology="results/{sample}/topology/{sample}.top",
        mdp="workflow/scripts/mdp/prod.mdp",
        index="results/{sample}/topology/{sample}.ndx",

    output:
        structure="results/{sample}/production/rep{replicate}/{sample}_prod.gro",
        checkpoint="results/{sample}/production/rep{replicate}/{sample}_prod.cpt",
        trajectory="results/{sample}/production/rep{replicate}/{sample}_prod.xtc",
        #energy="results/{sample}/production/rep{replicate}/{sample}_prod_energy.edr", 'TODO write out energys'
    message:
        """--- Production MD run for {wildcards.sample} (replicate {wildcards.replicate}) ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
        seed=lambda wildcards: get_prod_seed(wildcards.sample, int(wildcards.replicate)),
    shell:
        """        
        # Check for checkpoint file and restart if exists
        if [ -f prod.cpt ]; then
            gmx grompp -f {input.mdp} \
                       -c {input.structure} \
                       -p {input.topology} \
                       -t $(dirname {output.structure})/{wildcards.sample}_prod.cpt \
                       -o $(dirname {output.structure})/{wildcards.sample}_prod.tpr -v 
            cd $(dirname {output.structure})
            gmx mdrun -deffnm {wildcards.sample}_prod -cpi {wildcards.sample}_prod.cpt -ntmpi 1 -v
        else
            gmx grompp -f {input.mdp} \
                       -c {input.structure} \
                       -p {input.topology} \
                       -o $(dirname {output.structure})/{wildcards.sample}_prod.tpr -v 
            cd $(dirname {output.structure})
            gmx mdrun -deffnm {wildcards.sample}_prod -ntmpi 1 -v 
        fi

        """

