# SlurmHyperopt.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://maximilian-gelbrecht.github.io/SlurmHyperopt.jl/dev/)
[![Build Status](https://github.com/maximilian-gelbrecht/SlurmHyperopt.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/maximilian-gelbrecht/SlurmHyperopt.jl/actions/workflows/CI.yml?query=branch%3Amain)


This small package generates Slurm HPC manager job array scripts for hyperparameter optimization. 

## Usage 

First, in one script set up the hyperparameter optimization and generate the Slurm job array file. One has to set some basic properties of the Slurm file with the `SlurmParams`, the call of the Julia script with `julia_call`, the path where the slurm file should be created and can add extra lines of code like load modules etc with `extra_calls`. 

```julia 
using SlurmHyperopt, JLD2 

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
sampler = RandomSampler(N_1=5:15, N_2=5:15, N_3=5:15, N_4=5:15, activation=["relu","selu","swish","tanh"])
sho = SlurmHyperoptimizer(N_jobs, sampler, params)

@save "hyperopt.jld2" sho
```
Here, also the Hyperparameter sampling method, a `RandomSampler`, is initialized and the ranges from which hyperparameters are chosen are specified. In the Julia script that should be optimized, load the 
`SlurmHyperoptimizer` object, do your regular computation, and then save the result in the end. Alternatively a `ProductSampler` can be chosen that will iterate over all parameter configurations specified. 

```julia 
using JLD2, Hyperopt, SlurmHyperopt

@load "hyperopt.jld2" sho 
i_job = parse(Int,ARGS[2])  # in the Julia call, $SLURM_TASK_ID is second, that's why we use ARGS[2] here
pars = sho[i_job]   
pars # is a named tuple of all hyperparameters set in the script above with the Hyperoptimizer struct

res = some_computation(pars)

SlurmHyperopt.save_result(sho, HyperoptResults(pars=pars, res=l), i_job)
```

Then submit the Slurm script that was created for you and last, but not least, when all jobs are finished, you first have to merge all the results of all jobs and then you can evaluate the optimiziaton:

```julia 
using JLD2, SlurmHyperopt, DataFrames

@load "hyperopt.jld2" sho
merge_results!(sho) # this command deletes the temporary files, so better save sho again
@save "hyperopt.jld2" sho

pars = get_params(sho) # get all the parameters 
res = get_results(sho) # get only the results 

df = DataFrame(sho) # return the pars and results as a DataFrame

# your evaluation here 
```



 
