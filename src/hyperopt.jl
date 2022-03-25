using Hyperopt
import Base.push!, Base.getindex

""" 
    SlurmHyperoptimizer(ho::Hyperoptimizer; slurm_params::SlurmParams=nothing)

Creates a Slurm Job Array submission file and a Hyperoptimizer instance for your Hyperoptimizer needs. Takes the same arguments as Hyperoptimizer from Hyperopt + the keyword argument slurm_params.
"""
struct SlurmHyperoptimizer
    ho::Hyperoptimizer
    slurm_params::SlurmParams

    function SlurmHyperoptimizer(ho::Hyperoptimizer, slurm_params::SlurmParams)
        generate_slurm_file(slurm_params, ho.iterations)    
        new(ho, slurm_params)
    end
end

"""
    push!(ho::SlurmHyperoptimizer, pars, res)

Adds the results to the SlurmHyperoptimizer object add the end of each task.

"""
function push!(ho::SlurmHyperoptimizer, pars, res)
    push!(ho.ho.history, pars)
    push!(ho.ho.results, res)
end

"""
    get_index(ho::SlurmHyperoptimizer, i::Integer)

Very hacky way how to index a Hyperoptimizer object.
"""
function getindex(ho::SlurmHyperoptimizer, i::Integer)
    @assert i <= ho.ho.iterations

    for (ii,iho) ∈ enumerate(ho.ho)
        if i==ii
            return iho 
        end 
    end
    error("Something went wrong if you can read this.")
end
