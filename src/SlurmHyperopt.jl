module SlurmHyperopt

abstract type AbstractHyperparameterSampler end 

include("slurm_file.jl")
include("hyperopt.jl")

export SlurmParams, SlurmHyperoptimizer, RandomSampler, ProductSampler, HyperoptResults
export merge_results!, get_params, get_results, save_result

end
