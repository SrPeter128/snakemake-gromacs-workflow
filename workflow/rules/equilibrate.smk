# Equilibration
# NVT and NPT equilibration to stabilize the system

rule nvt_equilibrate:
    input:
        structure="results/{sample}/minimize/em.gro",
        topology="results/{sample}/topology/{sample}.top",
        mdp="workflow/scripts/mdp/nvt.mdp",
        index="results/{sample}/topology/{sample}.ndx",
    output:
        structure="results/{sample}/equilibrate/nvt.gro",
    message:
        """--- NVT equilibration for {wildcards.sample} ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
    shell:
        """
        gmx grompp -f {input.mdp} \
                   -c {input.structure} \
                   -p {input.topology} \
                   -n {input.index} \
                   -o $(dirname {output.structure})/nvt.tpr -v
                
        cd $(dirname {output.structure})
        gmx mdrun -deffnm nvt -ntmpi 1 -v
        """


rule npt_equilibrate:
    input:
        structure="results/{sample}/equilibrate/nvt.gro",
        topology="results/{sample}/topology/{sample}.top",
        mdp="workflow/scripts/mdp/npt.mdp",
        index="results/{sample}/topology/{sample}.ndx",

    output:
        structure="results/{sample}/equilibrate/npt.gro",
    message:
        """--- NPT equilibration for {wildcards.sample} ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
    shell:
        """
        gmx grompp -f {input.mdp} \
                   -c {input.structure} \
                   -p {input.topology} \
                   -n {input.index} \
                   -o $(dirname {output.structure})/npt.tpr -v
                
        cd $(dirname {output.structure})
        gmx mdrun -deffnm npt -ntmpi 1 -v
        """
