function solve_ed(sys, optimizer)
    PTDF, A = PowerSystems.buildptdf(sys.branches, sys.buses)
    
    ps_model = PSI.CanonicalModel(Model(optimizer),
                                  Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                                  Dict{String, JuMP.Containers.DenseAxisArray}(),
                                  nothing,
                                  Dict{String, 
                                  PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, length(sys.buses), sys.time_periods)),
                                  Dict{String,Any}(),
                                  nothing);
    
    PSI.construct_device!(ps_model, PSY.ThermalGen, PSI.ThermalDispatch, PSI.CopperPlatePowerModel, sys);
    PSI.construct_device!(ps_model, PSY.RenewableCurtailment, PSI.PSI.RenewableFullDispatch, PSI.CopperPlatePowerModel, sys);
    PSI.construct_device!(ps_model, PSY.PowerLoad, PSI.StaticPowerLoad, PSI.CopperPlatePowerModel, sys);
    PSI.constructnetwork!(ps_model,PSI.CopperPlatePowerModel, sys; PTDF = PTDF)
        
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
        
    JuMP.optimize!(ps_model.JuMPmodel)
        
    return get_model_result(ps_model), ps_model
        
end
