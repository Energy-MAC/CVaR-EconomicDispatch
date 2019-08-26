function cvar_network(ps_m::CanonicalModel, expression::Symbol, prob_forecast, bus_count::Int64)

    time_steps = model_time_steps(ps_m)
    quantiles = PSY.get_quantiles(prob_forecast)
    quantiles = quantiles./sum(quantiles)
    @assert sum(quantiles) == 1
    M = length(quantiles)
    devices_netinjection = _remove_undef!(ps_m.expressions[expression])

    ps_m.variables[:delta_rhs] = _container_spec(ps_m.JuMPmodel, time_steps)
    ps_m.variables[:delta_lhs] = _container_spec(ps_m.JuMPmodel, time_steps)

    ps_m.variables[:u_rhs] = _container_spec(ps_m.JuMPmodel, quantiles, time_steps)
    ps_m.variables[:u_lhs] = _container_spec(ps_m.JuMPmodel, quantiles, time_steps)

    ps_m.constraints[:cvar_rhs] = JuMPConstraintArray(undef, time_steps)
    ps_m.constraints[:cvar_lhs] = JuMPConstraintArray(undef, time_steps)

    ps_m.constraints[:u_rhs_simplex] = JuMPConstraintArray(undef, time_steps)
    ps_m.constraints[:u_lhs_simplex] = JuMPConstraintArray(undef, time_steps)
    prob_forecast_data = values(prob_forecast.data)

    for t in time_steps

        ps_m.variables[:delta_rhs][t] = JuMP.@variable(ps_m.JuMPmodel, lower_bound = 0, base_name = "delta_{rhs_{$(t)}}")
        ps_m.variables[:delta_lhs][t] = JuMP.@variable(ps_m.JuMPmodel, lower_bound = 0, base_name = "delta_{lhs_{$(t)}}")

        for q in quantiles
            ps_m.variables[:u_rhs][q,t] =  JuMP.@variable(ps_m.JuMPmodel, lower_bound = 0, upper_bound = q/0.1, base_name = "u_{rhs_{$(t),$(q)}}")
            ps_m.variables[:u_lhs][q,t] =  JuMP.@variable(ps_m.JuMPmodel, lower_bound = 0, upper_bound = q/0.1, base_name = "u_{lhs_{$(t),$(q)}}")
        end

        ps_m.constraints[:u_rhs_simplex][t] = JuMP.@constraint(ps_m.JuMPmodel, sum(ps_m.variables[:u_rhs][q,t] for q in quantiles)  == 1)
        ps_m.constraints[:u_lhs_simplex][t] = JuMP.@constraint(ps_m.JuMPmodel, sum(ps_m.variables[:u_lhs][q,t] for q in quantiles)  == 1)

        sys_bal = sum(ps_m.expressions[expression].data[1:bus_count, t])

        ps_m.constraints[:cvar_rhs][t] = JuMP.@constraint(ps_m.JuMPmodel,
                                           (sys_bal + sum((ps_m.variables[:u_rhs][q,t]*(prob_forecast_data[t,ix]) for (ix,q) in enumerate(quantiles)))) >= ps_m.variables[:delta_rhs][t]);
        ps_m.constraints[:cvar_lhs][t] = JuMP.@constraint(ps_m.JuMPmodel,
                                          -(sys_bal + sum((ps_m.variables[:u_lhs][q,t]*(prob_forecast_data[t,ix]) for (ix,q) in enumerate(quantiles)))) >= ps_m.variables[:delta_lhs][t]);

    end

    risk_cost = sum((5000*ps_m.variables[:delta_rhs][t] - 5000*ps_m.variables[:delta_lhs][t])^2 for t in time_steps)

    ps_m.cost_function += risk_cost

    return

end
