using Revise
using PowerSystems
using JuMP
using Ipopt
using Gurobi
using PyPlot
using Random
using Distributions
using PowerSimulations
using Logging
using TimeSeries
using MathOptInterface

const MOI = MathOptInterface

#gl = global_logger()
#global_logger(ConsoleLogger(gl.stream, LogLevel(Logging.Debug)))

ipopt_optimizer = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=1)
Gurobi_optimizer = with_optimizer(Gurobi.Optimizer)

const PSI = PowerSimulations
const PSY = PowerSystems


include("utils.jl")
include("ED_problem.jl")
include("CvARED.jl")
include("forecast_generator.jl")