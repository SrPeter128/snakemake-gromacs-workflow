# Energy Minimization
# Minimize the potential energy of the system to remove steric clashes

rule energy_minimize:
    input:
        structure="results/{sample}/topology/{sample}.gro",
        topology="results/{sample}/topology/{sample}.top",
        index="results/{sample}/topology/{sample}.ndx",
        mdp="workflow/scripts/mdp/em.mdp",
    output:
        structure="results/{sample}/minimize/minimized.gro",
        checkpoint="results/{sample}/minimize/minimized.cpt",
        trajectory="results/{sample}/minimize/em.trr",
        energy="results/{sample}/minimize/em_energy.edr",
    message:
        """--- Energy minimization for {wildcards.sample} ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
    shell:
        """
        #cd $(dirname {output.structure})
        gmx grompp -f {input.mdp} \
                   -c {input.structure} \
                   -p {input.topology} \
                   -n {input.index} \
                   -o $(dirname {output.structure})/em.tpr -v 
                
                
        cd $(dirname {output.structure})
        gmx mdrun -deffnm em 
        
        mv em.gro ../../../../{output.structure}
        mv em.cpt ../../../../{output.checkpoint}
        mv em.trr ../../../../{output.trajectory}
        mv em.edr ../../../../{output.energy}
        """
