"""
    struct SlurmParams 

Holds all user defined parameters for the Slurm script. The constructor works with keyword arguments. If a field is `nothing`, it is omitted in the script. Hyphens "-" are replaced by underscores "_" compared to regular Slurm names. Currently: 

    * `qos`
    * `job_name`
    * `account`
    * `output = nothing` if output and error are nothing, they are automatically generated based on the job name and the job array task index
    * `error = nothing`
    * `partition = nothing`
    * `gres = nothing`
    * `nodes = nothing`
    * `ntasks_per_node = nothing`
    * `workdir = nothing`
    * `mail_type = nothing`
    * `mail_user = nothing`
    * `parallel_jobs = nothing`: how many jobs can run at the same time?
    * `file_path = ""`: path to Slurm script file to be saved
    * `extra_calls = ""`: string with extra calls, e.g. loading modules etc
    * `julia_call = ""`: julia call 

"""
Base.@kwdef struct SlurmParams 
    qos 
    job_name
    account 
    output = nothing
    error = nothing 
    partition = nothing
    gres = nothing 
    nodes = nothing
    ntasks_per_node = nothing 
    workdir = nothing 
    mail_type = nothing 
    mail_user = nothing
    parallel_jobs = nothing # how many jobs can run at the same time?
    file_path = ""
    extra_calls = ""
    julia_call = ""
end

"""
    generate_slurm_file(p::SlurmParams, N_jobs::Integer)

Generates the Slurm script file based on a `SlurmParams` instance.
"""
function generate_slurm_file(p::SlurmParams, N_jobs)

    touch(p.file_path)
    f = open(p.file_path, "w")

    write(f, "#!/bin/bash \n\n")
    # first generate the slurm script
    write_slurm_line(f, "#SBATCH --qos=", p.qos)
    write_slurm_line(f, "#SBATCH --job-name=", p.job_name)
    write_slurm_line(f, "#SBATCH --account=", p.account)

    if isnothing(p.output)
        output = string(p.job_name,"-%a-%A-%j.out")
    end 
    write_slurm_line(f, "#SBATCH --output=", output)

    if isnothing(p.error)
        error = string(p.job_name,"-%a-%A-%j.err")
    end 
    write_slurm_line(f, "#SBATCH --error=", error)
    write_slurm_line(f, "#SBATCH --nodes=", p.nodes)
    write_slurm_line(f, "#SBATCH --ntasks-per-node=", p.ntasks_per_node)
    write_slurm_line(f, "#SBATCH --partition=", p.partition)
    write_slurm_line(f, "#SBATCH --gres=", p.gres)
    write_slurm_line(f, "#SBATCH --workdir=", p.workdir)

    if !(isnothing(p.parallel_jobs))
        write(f, "#SBATCH --array=1-", N_jobs,"%", p.parallel_jobs)
    else 
        write_slurm_line(f, "#SBATCH --array=1-", N_jobs)
    end

    write_slurm_line(f, "#SBATCH --mail-type=", p.mail_type)
    write_slurm_line(f, "#SBATCH --mail-user=", p.mail_user)

    write(f, "\n\n")
    # then the extra calls that need to be made
    write(f, p.extra_calls)
    write(f, "\n\n")
    
    # then the call of the julia script
    write(f, p.julia_call)

    close(f)
end

function write_slurm_line(f, str, prop)
    if !(isnothing(prop))
        write(f, string(str, prop, "\n"))
    end
end