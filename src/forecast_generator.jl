# Base Time Series 
#dates_forecast  = collect(DateTime("1/1/2024  10:30:00", "d/m/y  H:M:S"):Minute(5):DateTime("1/1/2024  12:25:00", "d/m/y  H:M:S"));
#ini_time = DateTime("1/1/2024  10:30:00", "d/m/y  H:M:S");

#Deterministic Forecasts
#wind_forecast_data = reshape([745 729 735 711 685 667 645 622 611 614 618 620 618 615 618 590 578 580 586 600 603 603 622 626]/745,(24,1));


#wind_forecast_det = Deterministic(generators14[2], 24, Hour(1), Minute(5), ini_time, Dict(1 => TimeArray(dates_forecast, wind_forecast_data)));

#solar1_forecast_data = reshape([957	957	958	957	956	950	933	929	930	941	941]/958,(12,1));

#solar1_forecast_det = Deterministic(generators14[3], 24, Hour(1), Minute(5), ini_time, Dict(1 => TimeArray(dates_forecast, solar1_forecast_data)));

#solar2_forecast_data = reshape([10599 10623 10652 10667 10679 10687 10679 10678 10682 10667 10592 10575 10576 10588 10657 10673 10648 10596 10643 10709 10696 10686 10708 10711]/10711,(24,1));

#solar2_forecast_det = Deterministic(generators14[4], 24, Hour(1), Minute(5), ini_time, Dict(1 => TimeArray(dates_forecast, solar2_forecast_data)));

#Probabilistic Forecasts
Random.seed!(101);


function add_probabilistc(series; percentiles = 0.01:0.01:1.0)
    temp = Array{Any,1}(undef,12)
    for t in 1:12
        dist = Normal(series[t],0.0333)
        dist_t = Truncated(dist,0,1)
        temp[t] = quantile.(dist_t, percentiles)
    end
    return temp
end

function store_probabilistic(temp_array, dates)
    forecast_dict = Dict{Int64,Any}()
    for p in 1:100
        temp = Array{Float64,1}(undef,24)
        for t in 1:24
            temp[t] = temp_array[t][p]
        end
       forecast_dict[p] =  TimeArray(dates,temp)
    end
    return forecast_dict
end

function make_probabilistic(data,dates)
    res = add_probabilistc(data)
    return store_probabilistic(res,dates)
end
