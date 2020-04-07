using Revise
using PowerSystems
using JuMP
using Ipopt
using Gurobi
#using Plots
using PowerSimulations
using Logging
using TimeSeries
using MathOptInterface
using LinearAlgebra
import PowerModels

gl = global_logger()
global_logger(ConsoleLogger(gl.stream, LogLevel(Logging.Warn)))

ipopt_optimizer = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=1)
Gurobi_optimizer = with_optimizer(Gurobi.Optimizer, OutputFlag = 0, MIPGap = 0.003)

const PSI = PowerSimulations
const PSY = PowerSystems
const PM = PowerModels
const MOI = MathOptInterface


struct CvARopt <: PSI.AbstractOperationModel end
include("src/cvar_network.jl")
include("src/cvar_devices.jl")
include("src/cvar_stage_update.jl")

dates = [
"2018-08-26"
 "2018-09-23"
 "2018-07-01"
 "2018-09-13"
 "2018-08-27"
 "2018-09-17"
 "2018-10-11"
 "2018-10-12"
 "2018-09-11"
 "2018-10-03"
    ]

base_dir = "/Users/jdlara/Dropbox/Code/CVaR-EconomicDispatch/data"
#ed_system = PSY.System(joinpath(base_dir, "ed-$(dates[1]).json"))
#uc_system = PSY.System(joinpath(base_dir, "uc-$(dates[1]).json"))

## UC Model Ref

branches = Dict{Symbol, DeviceModel}()

services = Dict{Symbol, PSI.ServiceModel}()

devices = Dict{Symbol, DeviceModel}(:Generators => DeviceModel(PSY.ThermalStandard, PSI.ThermalStandardUnitCommitment),
                                    :DRen => DeviceModel(PSY.RenewableDispatch, PSI.RenewableFixed),
                                    :FRen => DeviceModel(PSY.RenewableFix, PSI.RenewableFixed),
                                    :Loads =>  DeviceModel(PSY.InterruptibleLoad, PSI.StaticPowerLoad),
                                    )

model_ref_uc= ModelReference(CopperPlatePowerModel, devices, branches, services);

## ED Model Ref
branches = Dict{Symbol, DeviceModel}()

services = Dict{Symbol, PSI.ServiceModel}()

devices = Dict{Symbol, DeviceModel}(:Generators => DeviceModel(PSY.ThermalStandard, PSI.ThermalRampLimited, SemiContinuousFF(:P, :ON)),
                                    :DRen => DeviceModel(PSY.RenewableDispatch, PSI.RenewableFullDispatch),
                                    :FRen => DeviceModel(PSY.RenewableFix, PSI.RenewableFixed),
                                    :Loads =>  DeviceModel(PSY.InterruptibleLoad, PSI.StaticPowerLoad),
                                    )
model_ref_ed= ModelReference(CopperPlatePowerModel, devices, branches, services);

ix = 1
    ed_system = PSY.System(joinpath(base_dir, "ed-$(dates[ix]).json"))
    uc_system = PSY.System(joinpath(base_dir, "uc-$(dates[ix]).json"))
    stages = Dict(1 => Stage(model_ref_uc, 1, uc_system, Gurobi_optimizer,  Dict(0 => Sequential())),
    2 => Stage(model_ref_ed, 96, ed_system, Gurobi_optimizer, Dict(1 => Synchronize(24,4), 0 => Sequential()), TimeStatusChange(:ON_ThermalStandard)))
    sim = Simulation("test-ED-$(ix)", 1, stages, "/Users/jdlara/Desktop/"; verbose = false)
    run_sim_model!(sim; verbose = true)

#=

branches = Dict{Symbol, DeviceModel}()

services = Dict{Symbol, PSI.ServiceModel}()

devices = Dict{Symbol, DeviceModel}(:Generators => DeviceModel(PSY.ThermalStandard, PSI.ThermalStandardUnitCommitment),
                                    :DRen => DeviceModel(PSY.RenewableDispatch, PSI.RenewableFixed),
                                    :FRen => DeviceModel(PSY.RenewableFix, PSI.RenewableFixed),
                                    :Loads =>  DeviceModel(PSY.InterruptibleLoad, PSI.StaticPowerLoad),
                                    )

model_ref_uc= ModelReference(CopperPlatePowerModel, devices, branches, services);

branches = Dict{Symbol, DeviceModel}()

services = Dict{Symbol, PSI.ServiceModel}()

devices = Dict{Symbol, DeviceModel}(:Generators => DeviceModel(PSY.ThermalStandard, PSI.ThermalRampLimited, SemiContinuousFF(:P, :ON)),
                                    :Ren => DeviceModel(PSY.RenewableDispatch, RenewableCvAR),
                                    :FRen => DeviceModel(PSY.RenewableFix, PSI.RenewableFixed),
                                    :ILoads =>  DeviceModel(PSY.InterruptibleLoad, PSI.DispatchablePowerLoad),
                                    )

model_ref_cvar= ModelReference(CVaRModel, devices, branches, services)

for ix in [7, 8, 10]
    sys_cvar = PSY.System(joinpath(base_dir, "prob-ed-$(dates[ix]).json"))
    uc_system = PSY.System(joinpath(base_dir, "uc-$(dates[ix]).json"))
    stages = Dict(1 => Stage(model_ref_uc, 1, uc_system, Gurobi_optimizer,  Dict(0 => Sequential())),
    2 => Stage(CvARopt, model_ref_cvar, 96, sys_cvar, Gurobi_optimizer, Dict(1 => Synchronize(24,4), 0 => Sequential()), TimeStatusChange(:ON_ThermalStandard)))
    sim = Simulation("test-CvAr2-$(ix)", 1, stages, "/Users/jdlara/Desktop/"; verbose = false)
    run_sim_model!(sim; verbose = true)
end
=#
