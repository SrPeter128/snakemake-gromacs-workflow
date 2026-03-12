# Post-simulation Analysis
# Extract energy, RMSD, and other metrics from trajectories

rule extract_energy:
    input:
        energy="results/{sample}/production/prod_energy.edr",
    output:
        energy_xvg="results/{sample}/analysis/energy.xvg",
    log:
        "results/{sample}/analysis/extract_energy.log",
    message:
        """--- Extracting energy for {wildcards.sample} ---"""
    shell:
        """
        # Extract potential energy using echo to provide input
        echo "10 0" | gmx energy -f {input.energy} \
                                  -o {output.energy_xvg} > {log} 2>&1
        """


rule trajectory_analysis:
    input:
        trajectory="results/{sample}/production/prod.xtc",
        structure="results/{sample}/production/prod.gro",
    output:
        rmsd="results/{sample}/analysis/rmsd.xvg",
        rg="results/{sample}/analysis/radius_gyration.xvg",
    log:
        "results/{sample}/analysis/trajectory_analysis.log",
    message:
        """--- Analyzing trajectory for {wildcards.sample} ---"""
    shell:
        """
        echo "1 1" | gmx rms -f {input.trajectory} \
                              -s {input.structure} \
                              -o {output.rmsd} > {log} 2>&1
        
        echo "1" | gmx gyrate -f {input.trajectory} \
                             -s {input.structure} \
                             -o {output.rg} >> {log} 2>&1
        """


rule generate_report:
    input:
        energy="results/{sample}/analysis/energy.xvg",
        rmsd="results/{sample}/analysis/rmsd.xvg",
        rg="results/{sample}/analysis/radius_gyration.xvg",
    output:
        report="results/{sample}/analysis/report.html",
    log:
        "results/{sample}/analysis/generate_report.log",
    message:
        """--- Generating analysis report for {wildcards.sample} ---"""
    shell:
        """
        cat > {output.report} <<'EOF'
        <!DOCTYPE html>
        <html>
        <head>
            <title>MD Simulation Analysis - {wildcards.sample}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                h1 {{ color: #333; }}
                .section {{ margin: 20px 0; padding: 10px; border-left: 4px solid #007bff; }}
            </style>
        </head>
        <body>
            <h1>Molecular Dynamics Simulation Analysis Report</h1>
            <div class="section">
                <h2>Sample: {wildcards.sample}</h2>
                <p>Analysis completed successfully.</p>
                <p>Output files:</p>
                <ul>
                    <li>Energy: energy.xvg</li>
                    <li>RMSD: rmsd.xvg</li>
                    <li>Radius of Gyration: radius_gyration.xvg</li>
                </ul>
            </div>
        </body>
        </html>
        EOF
        """
