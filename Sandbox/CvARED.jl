function solve_cvar_ed(sys, prob_forecast, optimizer)
    PTDF, A = PowerSystems.buildptdf(sys.branches, sys.buses)
    gen_set = [g.name for g in sys.generators.thermal]
    
    
    M = length(prob_forecast[1])
    ϵ = 0.15
    
    ps_model = PSI.CanonicalModel(Model(optimizer),
                                  Dict{String, JuMP.Containers.DenseAxisArray{JuMP.VariableRef}}(),
                                  Dict{String, JuMP.Containers.DenseAxisArray}(),
                                  nothing,
                                  Dict{String, 
                                  PSI.JumpAffineExpressionArray}("var_active" => PSI.JumpAffineExpressionArray(undef, length(sys.buses), sys.time_periods)),
                                  Dict{String,Any}(),
                                  nothing);
    
    PSI.construct_device!(ps_model, PSY.ThermalGen, PSI.ThermalDispatch, PSI.CopperPlatePowerModel, sys);
    #PSI.construct_device!(ps_model, PSY.RenewableCurtailment, PSI.PSI.RenewableFullDispatch, PSI.CopperPlatePowerModel, sys);
    
    PSI.construct_device!(ps_model, PSY.PowerLoad, PSI.StaticPowerLoad, PSI.CopperPlatePowerModel, sys);
    #PSI.constructnetwork!(ps_model,PSI.CopperPlatePowerModel, sys; PTDF = PTDF)
     
    ps_model.variables["delta_rhs"] = JuMP.Containers.DenseAxisArray{JuMP.variable_type(ps_model.JuMPmodel)}(undef, 1:sys.time_periods)
    ps_model.variables["delta_lhs"] = JuMP.Containers.DenseAxisArray{JuMP.variable_type(ps_model.JuMPmodel)}(undef, 1:sys.time_periods)
    
    ps_model.variables["u_rhs"] = JuMP.Containers.DenseAxisArray{JuMP.variable_type(ps_model.JuMPmodel)}(undef, 1:length(prob_forecast[1]), 1:sys.time_periods)
    ps_model.variables["u_lhs"] = JuMP.Containers.DenseAxisArray{JuMP.variable_type(ps_model.JuMPmodel)}(undef, 1:length(prob_forecast[1]), 1:sys.time_periods)
    
    ps_model.constraints["cvar_rhs"] = JuMP.Containers.DenseAxisArray{JuMP.ConstraintRef}(undef, 1:sys.time_periods)
    ps_model.constraints["cvar_lhs"] = JuMP.Containers.DenseAxisArray{JuMP.ConstraintRef}(undef, 1:sys.time_periods)
    
    ps_model.constraints["u_rhs_simplex"] = JuMP.Containers.DenseAxisArray{JuMP.ConstraintRef}(undef, 1:sys.time_periods)
    ps_model.constraints["u_lhs_simplex"] = JuMP.Containers.DenseAxisArray{JuMP.ConstraintRef}(undef, 1:sys.time_periods)
    
    
    for t in 1:sys.time_periods
        
        ps_model.variables["delta_rhs"][t] = @variable(ps_model.JuMPmodel, lower_bound = 0, base_name = "delta_{rhs_{$(t)}}")
        ps_model.variables["delta_lhs"][t] = @variable(ps_model.JuMPmodel, lower_bound = 0, base_name = "delta_{lhs_{$(t)}}")
        
        for s in 1:length(prob_forecast[1])
            ps_model.variables["u_rhs"][s,t] =  @variable(ps_model.JuMPmodel, lower_bound = 0, upper_bound = prob_forecast[t][s]/(ϵ), base_name = "u_{rhs_{$(t),$(s)}}")
            ps_model.variables["u_lhs"][s,t] =  @variable(ps_model.JuMPmodel, lower_bound = 0, upper_bound = prob_forecast[t][s]/(ϵ), base_name = "u_{lhs_{$(t),$(s)}}")
        end
        
         ps_model.constraints["u_rhs_simplex"][t] = @constraint(ps_model.JuMPmodel, sum(ps_model.variables["u_rhs"][s,t] for s = 1:M)  == 1)
         ps_model.constraints["u_lhs_simplex"][t] = @constraint(ps_model.JuMPmodel, sum(ps_model.variables["u_lhs"][s,t] for s = 1:M)  == 1)
            
         P = sum(ps_model.variables["Pth"][:,t])
         load = sum(d.maxactivepower * values(d.scalingfactor)[t] for d in sys.loads)
        
         ps_model.constraints["cvar_rhs"][t] = @constraint(ps_model.JuMPmodel,
                                           (P + sum((ps_model.variables["u_rhs"][s,t]*(prob_forecast[t][s] - load) for s = 1:M))) >= ps_model.variables["delta_rhs"][t]);
         ps_model.constraints["cvar_lhs"][t] = @constraint(ps_model.JuMPmodel, 
                                            -(P + sum((ps_model.variables["u_lhs"][s,t]*(prob_forecast[t][s] - load) for s = 1:M))) >= ps_model.variables["delta_lhs"][t]);
        
    end
    
    risk_cost = sum((5000*ps_model.variables["delta_rhs"][t] - 5000*ps_model.variables["delta_lhs"][t])^2 for t in 1:sys.time_periods)
    
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function + risk_cost)
        
    JuMP.optimize!(ps_model.JuMPmodel)
    @assert !(termination_status(ps_model.JuMPmodel) == MOI.INFEASIBLE_OR_UNBOUNDED)
        
    return ps_model
        
end


