struct RenewableCvAR<:PSI.AbstractRenewableDispatchForm end

function include_parameters(canonical_model::PSI.CanonicalModel,
                            ts_data::Vector{Tuple{String, Int64, Float64, Vector{Float64}}},
                            param_reference::PSI.UpdateRef,
                            expression::Symbol,
                            multiplier::Float64 = 1.0)


    time_steps = PSI.model_time_steps(canonical_model)
    PSI._add_param_container!(canonical_model, param_reference, (r[1] for r in ts_data), time_steps)
    param = PSI.par(canonical_model, param_reference)
    expr = PSI.exp(canonical_model, expression)

    for t in time_steps, r in ts_data
        param[r[1], t] = PJ.add_parameter(canonical_model.JuMPmodel, r[4][t]);
    end

    return

end

function _get_time_series(forecasts::Vector{PSY.Deterministic{R}}) where {R<:PSY.RenewableGen}

    names = Vector{String}(undef, length(forecasts))
    ratings = Vector{Float64}(undef, length(forecasts))
    series = Vector{Vector{Float64}}(undef, length(forecasts))

    for (ix, f) in enumerate(forecasts)
        component = PSY.get_component(f)
        names[ix] = PSY.get_name(component)
        series[ix] = values(PSY.get_data(f))
        ratings[ix] = PSY.get_tech(component).rating
    end

    return names, ratings, series

end


function PSI._internal_device_constructor!(canonical_model::PSI.CanonicalModel,
                                       device_model::PSI.DeviceModel{PSY.RenewableDispatch, RenewableCvAR},
                                       ::Type{CVaRModel},
                                       sys::PSY.System;
                                       kwargs...)

    return

end
