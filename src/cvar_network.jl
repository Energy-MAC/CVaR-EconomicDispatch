struct CVaRModel<:PM.DCPlosslessForm end

function PSI._internal_network_constructor(canonical::PSI.CanonicalModel,
                            system_formulation::Type{CVaRModel},
                            sys::PSY.System; kwargs...)

    #buses = PSY.get_components(PSY.Bus, sys)
    #bus_count = length(buses)
    #ini_time = PSY.get_forecasts_initial_time(sys)
    #cvar_network(canonical, :nodal_balance_active, PSY.get_component_forecasts(RenewableDispatch, sys, ini_time), bus_count)

    return

end

function cvar_network(canonical_model::PSI.CanonicalModel, expression::Symbol, prob_forecast, bus_count::Int64)

    prob_forecast = collect(prob_forecast)[1]
    time_steps = PSI.model_time_steps(canonical_model)
    M = length(prob_forecast.percentiles)
    probabilities = collect(ones(M)*1/M)
    @assert sum(probabilities) - 1.0 <= eps()
    devices_netinjection = PSI._remove_undef!(canonical_model.expressions[expression])

    canonical_model.variables[:delta_rhs] = PSI._container_spec(canonical_model.JuMPmodel, time_steps)
    canonical_model.variables[:delta_lhs] = PSI._container_spec(canonical_model.JuMPmodel, time_steps)

    canonical_model.variables[:u_rhs] = PSI._container_spec(canonical_model.JuMPmodel, 1:length(probabilities), time_steps)
    canonical_model.variables[:u_lhs] = PSI._container_spec(canonical_model.JuMPmodel, 1:length(probabilities), time_steps)

    canonical_model.constraints[:cvar_rhs] = PSI.JuMPConstraintArray(undef, time_steps)
    canonical_model.constraints[:cvar_lhs] = PSI.JuMPConstraintArray(undef, time_steps)

    canonical_model.constraints[:u_rhs_simplex] = PSI.JuMPConstraintArray(undef, time_steps)
    canonical_model.constraints[:u_lhs_simplex] = PSI.JuMPConstraintArray(undef, time_steps)
    prob_forecast_data = values(prob_forecast.data)

    canonical_model.variables[:slack] = PSI._container_spec(canonical_model.JuMPmodel, time_steps)

    for t in time_steps

        canonical_model.variables[:delta_rhs][t] = JuMP.@variable(canonical_model.JuMPmodel, lower_bound = 0, base_name = "delta_{rhs_{$(t)}}")
        canonical_model.variables[:delta_lhs][t] = JuMP.@variable(canonical_model.JuMPmodel, lower_bound = 0, base_name = "delta_{lhs_{$(t)}}")
        canonical_model.variables[:slack][t]  = JuMP.@variable(canonical_model.JuMPmodel, lower_bound = 0)

        for (ix, q) in enumerate(probabilities)
            canonical_model.variables[:u_rhs][ix,t] =  JuMP.@variable(canonical_model.JuMPmodel, lower_bound = 0, upper_bound = q/0.1, base_name = "u_{rhs_{$(t),$(ix)}}")
            canonical_model.variables[:u_lhs][ix,t] =  JuMP.@variable(canonical_model.JuMPmodel, lower_bound = 0, upper_bound = q/0.1, base_name = "u_{lhs_{$(t),$(ix)}}")
        end

        canonical_model.constraints[:u_rhs_simplex][t] = JuMP.@constraint(canonical_model.JuMPmodel, sum(canonical_model.variables[:u_rhs][:,t])  == sum(probabilities))
        canonical_model.constraints[:u_lhs_simplex][t] = JuMP.@constraint(canonical_model.JuMPmodel, sum(canonical_model.variables[:u_lhs][:,t])  == sum(probabilities))

        sys_bal = sum(canonical_model.expressions[expression].data[1:bus_count, t])

        canonical_model.constraints[:cvar_rhs][t] = JuMP.@constraint(canonical_model.JuMPmodel,
                                           (sys_bal - canonical_model.variables[:slack][t] + sum(canonical_model.variables[:u_rhs][ix,t]*prob_forecast_data[t,ix] for ix in 1:M)) >= canonical_model.variables[:delta_rhs][t]);
        canonical_model.constraints[:cvar_lhs][t] = JuMP.@constraint(canonical_model.JuMPmodel,
                                          -(sys_bal - canonical_model.variables[:slack][t]+ sum(canonical_model.variables[:u_lhs][ix,t]*prob_forecast_data[t,ix] for ix in 1:M)) >= canonical_model.variables[:delta_lhs][t]);

    end

    risk_cost = sum((5000*canonical_model.variables[:delta_rhs][t] - 5000*canonical_model.variables[:delta_lhs][t])^2 + 5000*canonical_model.variables[:slack][t] for t in time_steps)

    canonical_model.cost_function += risk_cost

    return

end
