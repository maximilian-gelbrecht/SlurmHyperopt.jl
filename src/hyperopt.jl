
import Base.push!, Base.getindex

""" 
    SlurmHyperoptimizer(ho::Hyperoptimizer; slurm_params::SlurmParams=nothing)

Creates a Slurm Job Array submission file and a Hyperoptimizer instance for your Hyperoptimizer needs. Takes the same arguments as Hyperoptimizer from Hyperopt + the keyword argument slurm_params.
"""
mutable struct SlurmHyperoptimizer{S,T,V}
    sampler::AbstractHyperparameterSampler
    pars::S 
    res::T
    additional_res::V
    N_samples::Integer
    slurm_params::SlurmParams
end


function SlurmHyperoptimizer(N_samples::Integer, sampler::AbstractHyperparameterSampler, slurm_params::SlurmParams)
    generate_slurm_file(slurm_params, N_samples)    
    SlurmHyperoptimizer(sampler, [], [], [], N_samples, slurm_params)
end

"""
    push!(ho::SlurmHyperoptimizer, pars, res, additonal_res=nothing)

Adds the results to the SlurmHyperoptimizer object add the end of each task.

"""
function push!(ho::SlurmHyperoptimizer, pars, res, additonal_res=nothing)
    push!(ho.pars, pars)
    push!(ho.res, res)
    push!(ho.additional_res, additonal_res)
end


"""
    get_index(ho::SlurmHyperoptimizer, i::Integer)

Very hacky way how to index a Hyperoptimizer object, that respect its history, in case the individual samples are not independend (as for Hyperband)
"""
function Base.getindex(ho::SlurmHyperoptimizer, i::Integer)
    @assert i <= ho.N_samples
    return ho.sampler(ho.pars, ho.res)
end

function Base.iterate(iter::SlurmHyperoptimizer, state=1)
    if state>iter.N
        return nothing
    else  
        return (iter.sampler(iter.pars, iter.res), state+1)
    end
end

# reimplement RandomSampler
abstract type AbstractHyperparameterSampler end
struct RandomSampler <: AbstractHyperparameterSampler
    par_dic
    par_names 
end

RandomSampler(;kwargs...) = RandomSampler(kwargs, keys(kwargs))

function (samp::RandomSampler)(pars, res)
    Dict([key => rand(samp.par_dic[key]) for key in samp.par_names]...)
end 

