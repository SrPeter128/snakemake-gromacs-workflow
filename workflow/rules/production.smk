# Production Run
# Main MD simulation with checkpoint/restart capability

rule production:
    input:
        structure="results/{sample}/equilibrate/npt.gro",
        topology="results/{sample}/topology/{sample}.top",
        mdp="workflow/scripts/mdp/prod.mdp",
    output:
        structure="results/{sample}/production/prod.gro",
        checkpoint="results/{sample}/production/prod.cpt",
        trajectory="results/{sample}/production/prod.xtc",
        energy="results/{sample}/production/prod_energy.edr",
    log:
        "results/{sample}/production/prod.log",
    message:
        """--- Production MD run for {wildcards.sample} ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
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
            gmx mdrun -deffnm prod -cpi prod.cpt >> ../../../../{log} 2>&1
        else
            gmx grompp -f ../../../../{input.mdp} \
                       -c ../../../../{input.structure} \
                       -p ../../../../{input.topology} \
                       -o prod.tpr -v > ../../../../{log} 2>&1
            gmx mdrun -deffnm prod >> ../../../../{log} 2>&1
        fi
        
        mv prod.gro ../../../../{output.structure}
        mv prod.cpt ../../../../{output.checkpoint}
        mv prod.xtc ../../../../{output.trajectory}
        mv prod.edr ../../../../{output.energy}
        """
