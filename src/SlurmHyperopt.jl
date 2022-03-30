module SlurmHyperopt

abstract type AbstractHyperparameterSampler end 

include("slurm_file.jl")
include("hyperopt.jl")

export SlurmParams, SlurmHyperoptimizer, RandomSampler, HyperoptResults
export merge_results!

end
