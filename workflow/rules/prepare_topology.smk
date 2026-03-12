# Prepare system topology and structure files
# This rule prepares .gro and .top files from input structures
# Handles both all-atom (AA) and coarse-grain (CG) simulations

rule prepare_topology:
    input:
        structure="input/{sample}.gro",
        topology="input/{sample}.top",
    output:
        structure="results/{sample}/topology/{sample}.gro",
        topology="results/{sample}/topology/{sample}.top",
    log:
        "results/{sample}/topology/{sample}.log",
    message:
        """--- Preparing topology for {wildcards.sample} ({params.sim_type}) ---"""
    params:
        sim_type=lambda wildcards: get_sim_type(wildcards.sample),
    shell:
        """
        cp {input.structure} {output.structure}
        cp {input.topology} {output.topology}
        echo "Prepared topology for {params.sim_type} simulation" > {log}
        """
