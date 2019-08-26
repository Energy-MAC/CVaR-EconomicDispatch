using CSV
using TimeSeries
using Distributions
using Statistics
using DataFrames
using Dates


dir_ercot_data_folder = "/Users/jdlara/Dropbox/Documents/UCB/NREL Work/ERCOT_data/TEXAS2k_B"
SysMatpowerdata = joinpath(dir_ercot_data_folder,"case_ACTIVSg2000.m")
sys_cvar = PowerSystems.parse_standard_files(SysMatpowerdata);

complementary_data = CSV.File(joinpath(dir_ercot_data_folder,"generator_data_ramp_time_vals.csv")) |> DataFrame
for t in PSY.get_components(PSY.ThermalStandard, sys_cvar)
    row = parse(Int64, t.name)
    t.tech.ramplimits = (up = complementary_data[row, :RAMP_60]/600000, down = complementary_data[row, :RAMP_60]/600000)
    t.tech.timelimits = (up = complementary_data[row, :MINIMUM_UP_TIME]*1.0, down = complementary_data[row, :MINIMUM_DOWN_TIME]*1.0)
end
#Normalize Load values
for L in PSY.get_components(PSY.PowerLoad, sys_cvar)
    L.maxactivepower /= 100
end
#Normalize Generator Ratings
for G in PSY.get_components(PSY.RenewableGen, sys_cvar)
    G.tech.rating /= 100
end
pop!(sys_cvar.components, PSY.FixedAdmittance);
for (k,v) in sys_cvar.components[PSY.RenewableDispatch]
    k == "1" && continue
    pop!(sys_cvar.components[PSY.RenewableDispatch], k)
end
ed_gen_csv_data = PowerSystems.read_time_array(joinpath(dir_ercot_data_folder, "ed_ts_folder_test/ed_gen_file_siip.csv"));
ts = getindex(ed_gen_csv_data,Symbol(1))./maximum(values(getindex(ed_gen_csv_data,Symbol(1))))
ts = ts[205:216]
μ = values(std(ts))[1]
series = Vector{Float64}(undef, 12)
for i in 1:12
    series[i] = μ*(1+rand())
end
σ = values(mean(ts))[1]
function add_probabilistc(series, σ; percentiles = 0.01:0.01:1.0)
    temp = Array{Any,1}(undef,12)
    for t in 1:12
        dist = Truncated(Normal(series[t],σ),0,1)
        dist_t = Truncated(dist,0,1)
        temp[t] = quantile.(dist_t, percentiles)
        prob = pdf(dist_t, temp[t])
    end
    return temp, prob
end
prob_forecast, prob = add_probabilistc(series, σ);
df = DataFrame(prob_forecast[1]')
for n in 2:12
    push!(df, prob_forecast[n]')
end
df[:timestamp] = timestamp(ts)
comp = collect(PSY.get_components(PSY.RenewableGen, sys_cvar))[1]
prob = PSY.Probabilistic(comp, "ED Forecast", prob, TimeArray(df, timestamp = :timestamp))
PSY.add_forecasts!(sys_cvar, [prob]);

# Create the load forecasts from files
ed_load_csv_data = PowerSystems.read_time_array(joinpath(dir_ercot_data_folder, "ed_ts_folder_test/ed_demand_file_siip.csv"));

loads = PSY.get_components(PSY.PowerLoad, sys_cvar)
ed_load_forecasts = Vector{PSY.Deterministic{PSY.PowerLoad}}(undef, length(loads))
for (ix,d) in enumerate(loads)
    data = getindex(ed_load_csv_data,Symbol(d.name))
    ed_load_forecasts[ix] = PSY.Deterministic(d, "ED", Minute(5), timestamp(ts)[1], TimeArray(timestamp(data[1:12]), ones(12)))
end

PSY.add_forecasts!(sys_cvar,ed_load_forecasts)
bus = collect(get_components(Bus, sys_cvar))[1]
interruptible = InterruptibleLoad("Iload", true, bus, "P", 660.0, 0.0, PSY.TwoPartCost(15000.0, 2400.0))
PSY.add_component!(sys_cvar, interruptible)
il_forecast = PSY.Deterministic(interruptible, "ED", Minute(5), timestamp(ts)[1], TimeArray(timestamp(ts), ones(12)))
PSY.add_forecasts!(sys_cvar,[il_forecast])
ren_cvar = collect(PSY.get_components(PSY.RenewableGen, sys_cvar))[1]
ren_cvar.tech.rating=300.0;

# UC data
sys_uc = deepcopy(sys_cvar);
PSY.remove_forecast!(sys_uc, collect(PSY.get_forecasts(PSY.Probabilistic{PSY.RenewableDispatch}, sys_uc ,timestamp(ts)[1]))[1])
ren_uc = collect(PSY.get_components(PSY.RenewableGen, sys_uc))[1]
ren_uc.tech.rating=300*df[!,50][1];

# ED data
sys_ed = deepcopy(sys_uc);
comp = collect(PSY.get_components(PSY.RenewableGen, sys_ed))[1]
det = PSY.Deterministic(comp, "ED Forecast", TimeArray(df[!,101], df[!,50]))
ren_ed = collect(PSY.get_components(PSY.RenewableGen, sys_ed))[1]
ren_ed.tech.rating=300.0;
PSY.add_forecasts!(sys_ed,[det])


