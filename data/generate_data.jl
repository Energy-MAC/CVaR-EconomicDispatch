using CSV
using TimeSeries
using Distributions
using Statistics
using DataFrames
using Dates

#######################Read MatPower Data########################
dir_ercot_data_folder = "data/TEXAS2k_B"
SysMatpowerdata = joinpath(dir_ercot_data_folder,"case_ACTIVSg2000.m")
sys_cvar = PowerSystems.parse_standard_files(SysMatpowerdata);
sys_ed = PowerSystems.parse_standard_files(SysMatpowerdata);
sys_uc = PowerSystems.parse_standard_files(SysMatpowerdata);
systems = [sys_cvar, sys_ed, sys_uc]

complementary_data = CSV.File(joinpath(dir_ercot_data_folder,"generator_data_ramp_time_vals.csv")) |> DataFrame
for s in systems
	for t in PSY.get_components(PSY.ThermalStandard, s)
		row = parse(Int64, t.name)
		t.tech.ramplimits = (up = complementary_data[row, :RAMP_60]/600000, down = complementary_data[row, :RAMP_60]/600000)
		t.tech.timelimits = (up = complementary_data[row, :MINIMUM_UP_TIME]*1.0, down = complementary_data[row, :MINIMUM_DOWN_TIME]*1.0)
		end
	#Normalize Load values, make them 1/BasePower Since time series aren't in scaling factors
	for L in PSY.get_components(PSY.PowerLoad, s)
		L.maxactivepower /= 100
	end
	#Normalize Generator Ratings
	for G in PSY.get_components(PSY.RenewableGen, s)
		G.tech.rating /= 100
	end
	pop!(s.components, PSY.FixedAdmittance);
	for (k,v) in sys_cvar.components[PSY.RenewableDispatch]
		k == "1" && continue
		pop!(s.components[PSY.RenewableDispatch], k)
	end
end

###########################Assign Load Time Series##############################
ed_load_csv_data = PowerSystems.read_timeseries(joinpath(dir_ercot_data_folder, "ed_ts_folder_test/ed_demand_file_siip.csv"));
for s in [sys_cvar, sys_ed]
    loads = PSY.get_components(PSY.PowerLoad, s)
    ed_load_forecasts = Vector{PSY.Deterministic{PSY.PowerLoad}}(undef, length(loads))
    for (ix,d) in enumerate(loads)
        data = getindex(ed_load_csv_data, Symbol(d.name))
        ed_load_forecasts[ix] = PSY.Deterministic(d, "ED", Minute(5), timestamp(data[150:161])[1], TimeArray(timestamp(data[150:161]), values(data[150:161])))
    end
    PSY.add_forecasts!(s, ed_load_forecasts)
end

uc_load_csv_data = PowerSystems.read_timeseries(joinpath(dir_ercot_data_folder, "da_ts_folder_test/da_demand_file_siip.csv"));
for s in [sys_uc]
    loads = PSY.get_components(PSY.PowerLoad, s)
    uc_load_forecasts = Vector{PSY.Deterministic{PSY.PowerLoad}}(undef, length(loads))
    for (ix,d) in enumerate(loads)
        data = getindex(uc_load_csv_data, Symbol(d.name))
        uc_load_forecasts[ix] = PSY.Deterministic(d, "UC", Hour(1), timestamp(data)[1], TimeArray(timestamp(data), values(data)))
    end
    PSY.add_forecasts!(s, uc_load_forecasts)
end


####################Assign Renewable Time Series##################################
ed_gen_csv_data = PowerSystems.read_timeseries(joinpath(dir_ercot_data_folder, "ed_ts_folder_test/ed_gen_file_siip.csv"));
ts = getindex(ed_gen_csv_data,Symbol(1))./maximum(values(getindex(ed_gen_csv_data,Symbol(1))))
comp = collect(PSY.get_components(PSY.RenewableGen, sys_ed))[1]
comp.tech.rating=300.0;
det = PSY.Deterministic(comp, "ED Forecast", ts[150:161])
PSY.add_forecasts!(sys_ed,[det])

da_gen_csv_data = PowerSystems.read_timeseries(joinpath(dir_ercot_data_folder, "da_ts_folder_test/da_gen_file_siip.csv"));
ts = getindex(da_gen_csv_data,Symbol(1))./maximum(values(getindex(da_gen_csv_data,Symbol(1))))
comp = collect(PSY.get_components(PSY.RenewableGen, sys_uc))[1]
det = PSY.Deterministic(comp, "DA Forecast", ts)
ren_ed = collect(PSY.get_components(PSY.RenewableGen, sys_uc))[1]
ren_ed.tech.rating=300.0;
PSY.add_forecasts!(sys_uc,[det])


#######################Make Probabilistic Forecast########################
ed_gen_csv_data = PowerSystems.read_timeseries(joinpath(dir_ercot_data_folder, "ed_ts_folder_test/ed_gen_file_siip.csv"));
ts = getindex(ed_gen_csv_data,Symbol(1))./maximum(values(getindex(ed_gen_csv_data,Symbol(1))))
μ = values(std(ts))[1]
series = zeros(12)
for i in 1:12
    series[i] = μ*(1+rand())
end
σ = values(mean(ts))[1]
function make_probabilistc(series, σ; percentiles = 0.01:0.01:1.0)
    prob = zeros(length(percentiles))
	temp = Array{Any,1}(undef,length(series))
    for t in 1:length(series)
        dist = Truncated(Normal(series[t],σ),series[t]*0.7,series[t]*1.3)
        temp[t] = quantile.(dist, percentiles)
        prob = pdf.(dist, temp[t])
    end
	return temp, normalize(prob,1)
end

prob_forecast, probabilities = make_probabilistc(series, σ);
df = DataFrame(prob_forecast[1]')
for n in 2:length(series)
    push!(df, prob_forecast[n]')
end
df[!,:timestamp] = timestamp(ts)[150:161]

#### Attach forecast to cvar system ####
comp = collect(PSY.get_components(PSY.RenewableGen, sys_cvar))[1]
ren_ed.tech.rating=300.0;
prob_forecast = PSY.Probabilistic(comp, "CVaR Forecast", probabilities, TimeArray(df, timestamp = :timestamp))
PSY.add_forecasts!(sys_cvar, [prob_forecast]);

#split_forecasts!(sys_cvar, 
#    get_forecasts(Probabilistic, sys_cvar, Dates.DateTime("2019-08-26T00:00:00")),
#    Dates.Minute(60),
#    12)

@assert get_forecast_initial_times(sys_ed) == get_forecast_initial_times(sys_cvar)
