# SlurmHyperopt.jl

Based on Hyperopt.jl, this small package generates Slurm HPC manager job array scripts for hyperparameter optimization.

## Usage 

First, in one script set up the hyperparameter optimization and generate the Slurm job array file. One has to set some basic properties of the Slurm file with the `SlurmParams`, the call of the Julia script with `julia_call`, the path where the slurm file should be created and can add extra lines of code like load modules etc with `extra_calls`. 

```julia 
using Hyperopt, SlurmHyperopt, JLD2 

extra_calls = "echo \"------------------------------------------------------------\"
echo \"SLURM JOB ID: \$SLURM_JOBID\"
echo \"\$SLURM_NTASKS tasks\"
echo \"------------------------------------------------------------\"
    
module load julia/1.7.0"

julia_call = "julia test.jl \$SLURM_JOB_NAME \$SLURM_ARRAY_TASK_ID"

slurm_file = "test_script.sh"

params = SlurmParams(qos="short", 
                    job_name="test",
                    account="test-account",
                    nodes=1, 
                    ntasks_per_node=1,
                    extra_calls=extra_calls,
                    julia_call=julia_call,
                    file_path=slurm_file)

N_jobs = 10
ho = Hyperoptimizer(N_jobs, a=1:10, b=[true, false], c=randn(100))
sho = SlurmHyperoptimizer(ho, params)

@save "hyperopt.jld2" sho
```

For details regarding `Hyperoptimizer` please see the Hyperopt.jl package. In the Julia script that should be optimized, load the 
`SlurmHyperoptimizer` object, do your regular computation, and then save the result in the end. 

```julia 
using JLD2, Hyperopt, SlurmHyperopt

@load "hyperopt.jld2" sho 
i_job = parse(Int,ARGS[2])  # in the Julia call, $SLURM_TASK_ID is second, that's why we use ARGS[2] here
pars = sho[i_job]   
pars # is a tuple of all hyperparameters set in the script above with the Hyperoptimizer struct

res = some_computation(pars)

@load "hyperopt.jld2" sho # reload the hyperparameter object again (maybe some parallel process wrote into it in the meanwhile)
push!(sho, pars, res)   # add the results 
@save "hyperopt.jld2" sho # save them
```

Then submit the Slurm script that was created for you and last, but not least, when all jobs are finished, you can load and inspect the `Hyperoptimizer` object, with the tools from Hyperopt.jl.



 
