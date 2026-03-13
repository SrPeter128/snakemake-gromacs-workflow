# Energy Minimization
# Minimize the potential energy of the system to remove steric clashes

rule energy_minimize:
    input:
        structure="results/{sample}/topology/{sample}.gro",
        topology="results/{sample}/topology/{sample}.top",
        index="results/{sample}/topology/{sample}.ndx",
        mdp="workflow/scripts/mdp/em.mdp",
    output:
        structure="results/{sample}/minimize/em.gro",
    message:
        """--- Energy minimization for {wildcards.sample} ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
    shell:
        """
        base_dir=$PWD
        gmx grompp -f {input.mdp} \
                   -c {input.structure} \
                   -p {input.topology} \
                   -n {input.index} \
                   -o $(dirname {output.structure})/em.tpr -v
        echo $PWD
        cd $(dirname {output.structure})
        gmx mdrun -deffnm em -ntmpi 1 -v
        
        #mv em.gro $base_dir/{output.structure}
        """
