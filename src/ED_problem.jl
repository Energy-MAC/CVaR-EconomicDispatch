function solve_ed(sys, optimizer)
    Net = PS.CopperPlatePowerModel
    m = Model(optimizer);
    netinjection = PS.instantiate_network(Net, sys);
    PS.constructdevice!(m, netinjection, ThermalGen, PS.ThermalDispatch, Net, sys)
    PS.constructdevice!(m, netinjection, RenewableGen, PS.RenewableCurtail, Net, sys)
    PS.constructnetwork!(m, [(device=Line, formulation=PS.PiLine)], netinjection, Net, sys)
    @objective(m, Min, m.obj_dict[:objective_function])
    JuMP.optimize!(m)
    return get_model_result(m)
end