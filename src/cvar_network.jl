struct CVaRModel<:PM.DCPlosslessForm end

function PSI._internal_network_constructor(canonical::PSI.CanonicalModel,
                            system_formulation::Type{CVaRModel},
                            sys::PSY.System; kwargs...)
    
    buses = PSY.get_components(PSY.Bus, sys)
    bus_count = length(buses)
    ini_time = PSY.get_forecasts_initial_time(sys_cvar)
    devices = get_components(RenewableDispatch, sys_cvar)
    cvar_network(canonical, :nodal_balance_active, get_forecasts(sys_cvar, ini_time, devices), bus_count)

    return

end

function cvar_network(ps_m::PSI.CanonicalModel, expression::Symbol, prob_forecast, bus_count::Int64)

    prob_forecast = collect(prob_forecast)[1]    
    time_steps = PSI.model_time_steps(ps_m)
    probabilities = PSY.get_probabilities(prob_forecast)
    @assert sum(probabilities) == 1
    M = length(probabilities)
    devices_netinjection = PSI._remove_undef!(ps_m.expressions[expression])

    ps_m.variables[:delta_rhs] = PSI._container_spec(ps_m.JuMPmodel, time_steps)
    ps_m.variables[:delta_lhs] = PSI._container_spec(ps_m.JuMPmodel, time_steps)

    ps_m.variables[:u_rhs] = PSI._container_spec(ps_m.JuMPmodel, 1:length(probabilities), time_steps)
    ps_m.variables[:u_lhs] = PSI._container_spec(ps_m.JuMPmodel, 1:length(probabilities), time_steps)

    ps_m.constraints[:cvar_rhs] = PSI.JuMPConstraintArray(undef, time_steps)
    ps_m.constraints[:cvar_lhs] = PSI.JuMPConstraintArray(undef, time_steps)

    ps_m.constraints[:u_rhs_simplex] = PSI.JuMPConstraintArray(undef, time_steps)
    ps_m.constraints[:u_lhs_simplex] = PSI.JuMPConstraintArray(undef, time_steps)
    prob_forecast_data = values(prob_forecast.data)

    for t in time_steps

        ps_m.variables[:delta_rhs][t] = JuMP.@variable(ps_m.JuMPmodel, lower_bound = 0, base_name = "delta_{rhs_{$(t)}}")
        ps_m.variables[:delta_lhs][t] = JuMP.@variable(ps_m.JuMPmodel, lower_bound = 0, base_name = "delta_{lhs_{$(t)}}")

        for (ix, q) in enumerate(probabilities)
            ps_m.variables[:u_rhs][ix,t] =  JuMP.@variable(ps_m.JuMPmodel, lower_bound = 0, upper_bound = q/0.1, base_name = "u_{rhs_{$(t),$(q)}}")
            ps_m.variables[:u_lhs][ix,t] =  JuMP.@variable(ps_m.JuMPmodel, lower_bound = 0, upper_bound = q/0.1, base_name = "u_{lhs_{$(t),$(q)}}")
        end

        ps_m.constraints[:u_rhs_simplex][t] = JuMP.@constraint(ps_m.JuMPmodel, sum(ps_m.variables[:u_rhs][:,t])  == 1)
        ps_m.constraints[:u_lhs_simplex][t] = JuMP.@constraint(ps_m.JuMPmodel, sum(ps_m.variables[:u_lhs][:,t])  == 1)

        sys_bal = sum(ps_m.expressions[expression].data[1:bus_count, t])

        ps_m.constraints[:cvar_rhs][t] = JuMP.@constraint(ps_m.JuMPmodel,
                                           (sys_bal + sum((ps_m.variables[:u_rhs][ix,t]*(prob_forecast_data[t,ix]) for (ix,q) in enumerate(probabilities)))) >= ps_m.variables[:delta_rhs][t]);
        ps_m.constraints[:cvar_lhs][t] = JuMP.@constraint(ps_m.JuMPmodel,
                                          -(sys_bal + sum((ps_m.variables[:u_lhs][ix,t]*(prob_forecast_data[t,ix]) for (ix,q) in enumerate(probabilities)))) >= ps_m.variables[:delta_lhs][t]);

    end

    risk_cost = sum((5000*ps_m.variables[:delta_rhs][t] - 5000*ps_m.variables[:delta_lhs][t])^2 for t in time_steps)

    ps_m.cost_function += risk_cost

    return

end
