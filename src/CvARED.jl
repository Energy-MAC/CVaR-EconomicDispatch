#using Revise
using PowerSystems
using JuMP
using Ipopt
using Gurobi
using GLPK
using OSQP
#using Plots
using Random
using Distributions
using PowerSimulations
using Logging
using TimeSeries
using MathOptInterface
using LinearAlgebra
import PowerModels

gl = global_logger()
global_logger(ConsoleLogger(gl.stream, LogLevel(Logging.Warn)))

ipopt_optimizer = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=1)
Gurobi_optimizer = with_optimizer(Gurobi.Optimizer, OutputFlag = 1, MIPGap = 1e-3)
GLPK_optimizer = with_optimizer(GLPK.Optimizer, msg_lev = GLPK.MSG_ALL)
OSQP_optimizer = JuMP.with_optimizer(OSQP.Optimizer)

const PSI = PowerSimulations
const PSY = PowerSystems
const PM = PowerModels
const MOI = MathOptInterface
