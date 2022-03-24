module SlurmHyperopt

include("slurm_file.jl")
include("hyperopt.jl")

export SlurmParams, SlurmHyperoptimizer

end
