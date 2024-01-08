# To-DO: For hyperband and bayasian, do a version where every k jobs, the results are already merged

import Base.push!, Base.getindex, Base.show
using JLD2, DataFrames

Base.@kwdef struct HyperoptResults{S,T,V,P}
    pars::S
    res::T 
    additonal_res::V = nothing
    model_pars::P = nothing
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

function SlurmHyperoptimizer(N_samples::Integer, sampler::AbstractHyperparameterSampler, slurm_params::SlurmParams, temp_dir="temp-hyperopt/")
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
    mkpath(sho.temp_dir) # make sure the folder is really there
    save_path = string(sho.temp_dir,"res-",i,".jld2")
    JLD2.@save save_path res 
end 

"""
    merge_results!(sho::SlurmHyperoptimizer; delete_temp_files=false, N_samples::Union{Nothing, Int}=nothing)

Merges the results and store them in the `sho.results` field. Also deletes the temporal files if `delete_temp_files==true`. In case `N_samples` is provided, the routine tries to merge that many files, if `nothing` is provided it takes the `N_samples` set in `sho`.
"""
function merge_results!(sho::SlurmHyperoptimizer; delete_temp_files=false, N_samples::Union{Nothing, Int}=nothing)

    N_samples = isnothing(N_samples) ? sho.N_samples : N_samples
    
    for i ∈ 1:N_samples
        save_path = string(sho.temp_dir,"res-",i,".jld2")
        if isfile(save_path)
            JLD2.@load save_path res 
            sho.results[i] = res 
        else 
            @warn "File number %i not found" i
            sho.results[i] = HyperoptResults(nothing, nothing, nothing, nothing)
        end
    end
    
    if delete_temp_files
        delete_temp_files!(sho)
    end

    return sho
end

function delete_temp_files!(sho::SlurmHyperoptimizer)
    rm(sho.temp_dir, recursive=true)
end

get_results(sho::SlurmHyperoptimizer) = res.(sho.results)
get_params(sho::SlurmHyperoptimizer) = pars.(sho.results)

function get_param(sho::SlurmHyperoptimizer, key::Symbol)
    if key ∈ sho.sampler.par_names 
        params = pars.(sho.results)
        return [i_param[key] for i_param ∈ params]
    else 
        error("Parameter name not found.")
    end
end

"""
    DataFrames(sho::SlurmHyperoptimizer)

Returns the results and parameters as a DataFrame
"""
function DataFrames.DataFrame(sho::SlurmHyperoptimizer) 
    DataFrame(Dict([key => get_param(sho, key) for key in sho.sampler.par_names]...,:results => get_results(sho)))
end

"""
    get_index(ho::SlurmHyperoptimizer, i::Integer)

Very hacky way how to index a Hyperoptimizer object, that respect its history, in case the individual samples are not independend (as for Hyperband)
"""
function Base.getindex(ho::SlurmHyperoptimizer, i::Integer)
    @assert i <= ho.N_samples
    return ho.sampler(ho.results)
end

function Base.iterate(iter::SlurmHyperoptimizer, state=1)
    if state>iter.N
        return nothing
    else  
        return (iter.sampler(ho.results), state+1)
    end
end

Base.show(io::IO, ho::SlurmHyperoptimizer) = "SlurmHyperoptimizer"

# reimplement RandomSampler
abstract type AbstractHyperparameterSampler end
struct RandomSampler <: AbstractHyperparameterSampler
    par_dic
    par_names 
end

RandomSampler(;kwargs...) = RandomSampler(kwargs, keys(kwargs))

function (samp::RandomSampler)(results)
    Dict([key => rand(samp.par_dic[key]) for key in samp.par_names]...)
end 

