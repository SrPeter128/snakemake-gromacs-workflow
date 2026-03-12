# Equilibration
# NVT and NPT equilibration to stabilize the system

rule nvt_equilibrate:
    input:
        structure="results/{sample}/minimize/minimized.gro",
        topology="results/{sample}/topology/{sample}.top",
        mdp="workflow/scripts/mdp/nvt.mdp",
    output:
        structure="results/{sample}/equilibrate/nvt.gro",
        checkpoint="results/{sample}/equilibrate/nvt.cpt",
        trajectory="results/{sample}/equilibrate/nvt.trr",
        energy="results/{sample}/equilibrate/nvt_energy.edr",
    log:
        "results/{sample}/equilibrate/nvt.log",
    message:
        """--- NVT equilibration for {wildcards.sample} ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
    shell:
        """
        cd $(dirname {output.structure})
        gmx grompp -f ../../../../{input.mdp} \
                   -c ../../../../{input.structure} \
                   -p ../../../../{input.topology} \
                   -o nvt.tpr -v > ../../../../{log} 2>&1
        
        gmx mdrun -deffnm nvt >> ../../../../{log} 2>&1
        
        mv nvt.gro ../../../../{output.structure}
        mv nvt.cpt ../../../../{output.checkpoint}
        mv nvt.trr ../../../../{output.trajectory}
        mv nvt.edr ../../../../{output.energy}
        """


rule npt_equilibrate:
    input:
        structure="results/{sample}/equilibrate/nvt.gro",
        topology="results/{sample}/topology/{sample}.top",
        mdp="workflow/scripts/mdp/npt.mdp",
    output:
        structure="results/{sample}/equilibrate/npt.gro",
        checkpoint="results/{sample}/equilibrate/npt.cpt",
        trajectory="results/{sample}/equilibrate/npt.trr",
        energy="results/{sample}/equilibrate/npt_energy.edr",
    log:
        "results/{sample}/equilibrate/npt.log",
    message:
        """--- NPT equilibration for {wildcards.sample} ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
    shell:
        """
        cd $(dirname {output.structure})
        gmx grompp -f ../../../../{input.mdp} \
                   -c ../../../../{input.structure} \
                   -p ../../../../{input.topology} \
                   -o npt.tpr -v > ../../../../{log} 2>&1
        
        gmx mdrun -deffnm npt >> ../../../../{log} 2>&1
        
        mv npt.gro ../../../../{output.structure}
        mv npt.cpt ../../../../{output.checkpoint}
        mv npt.trr ../../../../{output.trajectory}
        mv npt.edr ../../../../{output.energy}
        """
