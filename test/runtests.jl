using SlurmHyperopt
using Hyperopt
using Test

# not a good test yet (it really only checks if the code is running, not if it is doing anything useful)
@testset "SlurmHyperopt.jl" begin
   

    extra_calls = "echo \"------------------------------------------------------------\"
    echo \"SLURM JOB ID: \$SLURM_JOBID\"
    echo \"\$SLURM_NTASKS tasks\"
    echo \"------------------------------------------------------------\"
    
    module load julia/1.7.0"

    julia_call = "julia test.jl \$SLURM_JOB_NAME \$SLURM_TASK_ID"

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

    @test !isnothing(sho[1]) 
    
    @test true
end
