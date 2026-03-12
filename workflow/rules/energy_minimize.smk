# Energy Minimization
# Minimize the potential energy of the system to remove steric clashes

rule energy_minimize:
    input:
        structure="results/{sample}/topology/{sample}.gro",
        topology="results/{sample}/topology/{sample}.top",
        mdp="workflow/scripts/mdp/em.mdp",
    output:
        structure="results/{sample}/minimize/minimized.gro",
        checkpoint="results/{sample}/minimize/minimized.cpt",
        trajectory="results/{sample}/minimize/em.trr",
        energy="results/{sample}/minimize/em_energy.edr",
    log:
        "results/{sample}/minimize/em.log",
    message:
        """--- Energy minimization for {wildcards.sample} ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
    shell:
        """
        cd $(dirname {output.structure})
        gmx grompp -f ../../../../{input.mdp} \
                   -c ../../../../{input.structure} \
                   -p ../../../../{input.topology} \
                   -o em.tpr -v > ../../../../{log} 2>&1
        
        gmx mdrun -deffnm em >> ../../../../{log} 2>&1
        
        mv em.gro ../../../../{output.structure}
        mv em.cpt ../../../../{output.checkpoint}
        mv em.trr ../../../../{output.trajectory}
        mv em.edr ../../../../{output.energy}
        """
