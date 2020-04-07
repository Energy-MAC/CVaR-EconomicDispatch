function PSI.update_stage!(stage::PowerSimulations._Stage{CvARopt}, step::Int64, sim::Simulation)
    # Is first run of first stage? Yes -> do nothing
    stage.canonical = PSI._build_canonical(stage.reference.transmission,
                                     stage.reference.devices,
                                    stage.reference.branches,
                                    stage.reference.services,
                                    stage.sys,
                                    stage.optimizer,
                                    verbose = false;
                                    parameters = true)
    buses = PSY.get_components(PSY.Bus, stage.sys)
    bus_count = length(buses)
    ini_time = PSY.get_forecast_initial_times(stage.sys)[stage.execution_count+1]
    cvar_network(stage.canonical, :nodal_balance_active, PSY.get_component_forecasts(RenewableDispatch, stage.sys, ini_time), bus_count)

    for (k, v) in stage.canonical.parameters
        PSI.parameter_update!(k, v, stage.key, sim)
    end

    PSI.cache_update!(stage)

    # Set initial conditions of the stage I am about to run.
    for (k, v) in stage.canonical.initial_conditions
        PSI.intial_condition_update!(k, v, stage.key, step, sim)
    end

    return

end
