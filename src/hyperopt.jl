
import Base.push!, Base.getindex
using JLD2

Base.@kwdef struct HyperoptResults{S,T,V}
    pars::S
    res::T 
    additonal_res::V = nothing
end

res(r::HyperoptResults) = r.res 
pars(r::HyperoptResults) = r.pars

""" 
    SlurmHyperoptimizer(ho::Hyperoptimizer; slurm_params::SlurmParams=nothing)

Creates a Slurm Job Array submission file and a Hyperoptimizer instance for your Hyperoptimizer needs. Takes the same arguments as Hyperoptimizer from Hyperopt + the keyword argument slurm_params.
"""
mutable struct SlurmHyperoptimizer
    sampler::AbstractHyperparameterSampler
    results::Vector{HyperoptResults}
    N_samples::Integer
    slurm_params::SlurmParams
    temp_dir
end

function SlurmHyperoptimizer(N_samples::Integer, sampler::AbstractHyperparameterSampler, slurm_params::SlurmParams, temp_dir="temp/")
    generate_slurm_file(slurm_params, N_samples)    
    mkpath(temp_dir)
    results = Vector{HyperoptResults}(undef, N_samples)
    SlurmHyperoptimizer(sampler, results, N_samples, slurm_params, temp_dir)
end

"""
    save_result(sho::SlurmHyperoptimizer, res::HyperoptResults, i::Integer)

(Temporally) saves the results `res` of job `i`. Results are later merged with `merge_results!`.
"""
function save_result(sho::SlurmHyperoptimizer, res::HyperoptResults, i::Integer)
    save_path = string(sho.temp_dir,"res-",i,".jld2")
    JLD2.@save save_path res 
end 

"""
    merge_results!(sho::SlurmHyperoptimizer)

Merges the results and store them in the `sho.results` field. Also deletes the temporal files. 
"""
function merge_results!(sho::SlurmHyperoptimizer)
    for i ∈ 1:sho.N_samples
        save_path = string(sho.temp_dir,"res-",i,".jld2")
        JLD2.@load save_path res 
        sho.results[i] = res 
    end 
    rm(sho.temp_dir, recursive=true)
    return sho
end

get_results(sho::SlurmHyperoptimizer) = res.(sho.results)
get_params(sho::SlurmHyperoptimizer) = pars.(sho.results)

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

