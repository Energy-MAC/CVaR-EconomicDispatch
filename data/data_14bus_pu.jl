using PowerSystems
using TimeSeries


dates  = collect(DateTime("10:30:00", "H:M:S"):Minute(5):DateTime("11:25:00", "H:M:S"));

nodes14= [
                Bus(1 , "Bus 1"  , "SF" ,      0 , 1.06  , (min=0.94, max=1.06), 69),
                Bus(2 , "Bus 2"  , "PV" ,  -4.98 , 1.045 , (min=0.94, max=1.06), 69),
                Bus(3 , "Bus 3"  , "PV" , -12.72 , 1.01  , (min=0.94, max=1.06), 69),
                Bus(4 , "Bus 4"  , "PQ" ,  -10.33, 1.019 , (min=0.94, max=1.06), 69),
                Bus(5 , "Bus 5"  , "PQ" , -8.78  , 1.02  , (min=0.94, max=1.06), 69),
                Bus(6 , "Bus 6"  , "PV" , -14.22 , 1.07  , (min=0.94, max=1.06), 13.8),
                Bus(7 , "Bus 7"  , "PQ" ,  -13.37, 1.062 , (min=0.94, max=1.06), 13.8),
                Bus(8 , "Bus 8"  , "PV" , -13.36 , 1.09  , (min=0.94, max=1.06), 18),
                Bus(9 , "Bus 9"  , "PQ" ,  -14.94, 1.056 , (min=0.94, max=1.06), 13.8),
                Bus(10, "Bus 10" , "PQ" ,  -15.1 , 1.051 , (min=0.94, max=1.06), 13.8),
                Bus(11, "Bus 11" , "PQ" ,  -14.79, 1.057 , (min=0.94, max=1.06), 13.8),
                Bus(12, "Bus 12" , "PQ" ,  -15.07, 1.055 , (min=0.94, max=1.06), 13.8),
                Bus(13, "Bus 13" , "PQ" , -15.16 , 1.05  , (min=0.94, max=1.06), 13.8),
                Bus(14, "Bus 14" , "PQ" ,  -16.04, 1.036 , (min=0.94, max=1.06), 13.8)
            ]

branches14 = [
                Line("Line1",  true, (from=nodes14[1],to=nodes14[2]),   0.01938, 0.05917, (from=0.0264, to=0.0264,), 18.046, 1.04),
                Line("Line2",  true, (from=nodes14[1],to=nodes14[5]),   0.05403, 0.22304, (from=0.0246, to=0.0246,), 4.896, 1.04),
                Line("Line3",  true, (from=nodes14[2],to=nodes14[3]),   0.04699, 0.19797, (from=0.0219, to=0.0219,), 5.522, 1.04),
                Line("Line4",  true, (from=nodes14[2],to=nodes14[4]),   0.05811, 0.17632, (from=0.0,    to=0.0,   ), 6.052, 1.04),
                Line("Line5",  true, (from=nodes14[2],to=nodes14[5]),   0.05695, 0.17388, (from=0.0173, to=0.0173,), 6.140, 1.04),
                Line("Line6",  true, (from=nodes14[3],to=nodes14[4]),   0.06701, 0.17103, (from=0.0064, to=0.0064,), 6.116, 1.04),
                Line("Line7",  true, (from=nodes14[4],to=nodes14[5]),   0.01335, 0.04211, (from=0.0, to=0.0), 25.434, 1.04),
                TapTransformer("Trans3", true, (from=nodes14[4],to=nodes14[7]),  0.0    , 0.20912,  0.0, 0.978,  20.0),
                TapTransformer("Trans1", true, (from=nodes14[4],to=nodes14[9]),  0.0    , 0.55618,  0.0, 0.969,  20.0),
                TapTransformer("Trans2", true, (from=nodes14[5],to=nodes14[6]),  0.0    , 0.25202,  0.0, 0.932,  20.0),
                Line("Line8",  true, (from=nodes14[6],to=nodes14[11]),  0.09498, 0.19890, (from=0.0, to=0.0), 5.373, 1.04),
                Line("Line9",  true, (from=nodes14[6],to=nodes14[12]),  0.12291, 0.25581, (from=0.0, to=0.0), 2.020, 1.04),
                Line("Line10", true, (from=nodes14[6],to=nodes14[13]),  0.06615, 0.13027, (from=0.0, to=0.0), 4.458, 1.04),
                Transformer2W("Trans4", true, (from=nodes14[7],to=nodes14[8]),  0.0      , 0.17615,  0.0,    20.0),
                Line("Line16", true, (from=nodes14[7],to=nodes14[9]),   0.0,     0.11001, (from=0.0, to=0.0), 12.444, 1.04),
                Line("Line11", true, (from=nodes14[9],to=nodes14[10]),  0.03181, 0.08450, (from=0.0, to=0.0), 5.097, 1.04),
                Line("Line12", true, (from=nodes14[9],to=nodes14[14]),  0.12711, 0.27038, (from=0.0, to=0.0), 3.959, 1.04),
                Line("Line13", true, (from=nodes14[10],to=nodes14[11]), 0.08205, 0.19207, (from=0.0, to=0.0), 7.690, 1.04),
                Line("Line14", true, (from=nodes14[12],to=nodes14[13]), 0.22092, 0.19988, (from=0.0, to=0.0), 6.378, 1.04),
                Line("Line15", true, (from=nodes14[13],to=nodes14[14]), 0.17093, 0.34802, (from=0.0, to=0.0), 10.213, 1.04)
            ]

solar_ts_ed = [947,	940, 958, 957, 946,	940, 923, 929, 930,	941, 941, 940]/(1.2*958)
solar_ts_fr = [940,	950, 942, 947, 946,	943, 943, 939, 938,	941, 941, 940]/(1.2*958)


generators14_r = [ThermalDispatch("Bus1", true, nodes14[1],
                TechThermal(2.0, (min=1.0, max=2.0), -0.169, (min=-990.0, max=990.0), nothing, nothing),
                EconThermal(0.40, x -> 0.04303*x^2 + 20*x, 0.0, 0.0, 0.0, nothing)
                ),
                ThermalDispatch("Bus2", true, nodes14[2],
                TechThermal(0.40, (min=0.3, max=1.40), 0.42, (min=-990.0, max=990.0), nothing, nothing),
                EconThermal(1.40, x -> 0.05*x^2 + 20*x, 0.0, 0.0, 0.0, nothing)
                ),
                ThermalDispatch("Bus6", true, nodes14[6],
                TechThermal(0.0, (min=0.2, max=1.0), 0.12, (min=-990.0, max=990.0), nothing, nothing),
                (EconThermal(1.0, x -> 0.01*x^2 + 40*x, 0.0, 0.0, 0.0, nothing))
                ),
                RenewableCurtailment("SolarBus3", true, nodes14[3],
                    0.5,
                    EconRenewable(22.0, nothing),
                    TimeSeries.TimeArray(dates,solar_ts_ed)
                ),
                RenewableCurtailment("SolarBus8", true, nodes14[8],
                    0.5,
                    EconRenewable(22.0, nothing),
                    TimeSeries.TimeArray(dates,solar_ts_ed)
                )
            ];

generators14_f = [ThermalDispatch("Bus1", true, nodes14[1],
                TechThermal(2.0, (min=1.5, max=2.0), -0.169, (min=-990.0, max=990.0), nothing, nothing),
                EconThermal(0.40, x -> 0.04303*x^2 + 20*x, 0.0, 0.0, 0.0, nothing)
                ),
                ThermalDispatch("Bus2", true, nodes14[2],
                TechThermal(0.40, (min=0.3, max=1.40), 0.42, (min=-990.0, max=990.0), nothing, nothing),
                EconThermal(1.40, x -> 0.05*x^2 + 20*x, 0.0, 0.0, 0.0, nothing)
                ),
                ThermalDispatch("Bus6", true, nodes14[6],
                TechThermal(0.0, (min=0.2, max=1.0), 0.12, (min=-990.0, max=990.0), nothing, nothing),
                (EconThermal(1.0, x -> 0.01*x^2 + 40*x, 0.0, 0.0, 0.0, nothing))
                ),
                RenewableCurtailment("SolarBus3", true, nodes14[3],
                    0.5,
                    EconRenewable(22.0, nothing),
                    TimeSeries.TimeArray(dates,solar_ts_fr)
                ),
                RenewableCurtailment("SolarBus8", true, nodes14[8],
                    0.5,
                    EconRenewable(22.0, nothing),
                    TimeSeries.TimeArray(dates,solar_ts_fr)
                )
            ];


loadz1_ts = [ 0.792729978
            0.723201574
            0.710952098
            0.677672816
            0.668249175
            0.67166919
            0.687608809
            0.711821241
            0.756320618
            0.7984057
            0.827836527
            0.840362459]

loadz2_ts = [ 0.831093782
              0.689863228
              0.666058513
              0.627033103
              0.624901388
              0.62858924
              0.650734211
              0.683424321
              0.750876413
              0.828347191
              0.884248576
              0.888523615]

loadz3_ts = [ 0.871297342
              0.670489749
              0.642812243
              0.630092987
              0.652991383
              0.671971681
              0.716278493
              0.770885833
              0.810075243
              0.85562361
              0.892440566
              0.910660449]

loads14 = [PowerLoad("Bus2", true, nodes14[2], 0.217, 0.127, TimeArray(dates, loadz1_ts)),
          PowerLoad("Bus3", true, nodes14[3], 0.942, 0.19, TimeArray(dates, loadz1_ts)),
          PowerLoad("Bus4", true, nodes14[4], 0.778, -0.039, TimeArray(dates, loadz3_ts)),
          PowerLoad("Bus5", true, nodes14[5], 0.376, 0.016, TimeArray(dates, loadz1_ts)),
          PowerLoad("Bus6", true, nodes14[6], 0.212, 0.075, TimeArray(dates, loadz2_ts)),
          PowerLoad("Bus9", true, nodes14[9], 0.295, 0.166, TimeArray(dates, loadz3_ts)),
          PowerLoad("Bus10", true, nodes14[10], 0.19, 0.058, TimeArray(dates, loadz2_ts)),
          PowerLoad("Bus11", true, nodes14[11], 0.035, 0.018, TimeArray(dates, loadz2_ts)),
          PowerLoad("Bus12", true, nodes14[12], 0.061, 0.016, TimeArray(dates, loadz2_ts)),
          PowerLoad("Bus13", true, nodes14[13], 0.235, 0.058, TimeArray(dates, loadz2_ts)),
          PowerLoad("Bus14", true, nodes14[14], 0.249, 0.050, TimeArray(dates, loadz2_ts))
          ]
