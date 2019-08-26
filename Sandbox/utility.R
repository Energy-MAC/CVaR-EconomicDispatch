
#' Calculate number of days in the sequence
#' @param date_start A lubridate: Start date of data to load
#' @param date_end A lubridate: End date of data to load
#' @return Number of days in requested data sequence
get_ndays <- function(date_start,date_end) {
  interval(date_start, date_end)/days(1) + 1
}

#' Calculate start day's index since the beginning of data availability
#' @param date_data_start A lubridate: Date of first day in file
#' @param date_start A lubridate: Start date of data to load
#' @return Index number of first requested day
get_start_day <- function(date_data_start, date_start){
  interval(date_data_start, date_start)/days(1) + 1
}

#' Load data from a NETCDF file of ensemble forecasts
#' Assumed file dimensions: Day x Hour x Site x Lead time x Ensemble member
#' Returns an array of data: [site x member x time]
#' Site selection and member selection can all be vectors of non-consecutive values
#' Time-point selection is a consecutive sequence
#' @param fname file name
#' @param members A vector of member indices
#' @param sites A vector of sites
#' @param lead_time Forecast lead time
#' @param date_start A lubridate: Start date of data to load
#' @param date_end A lubridate: End date of data to load
#' @param date_data_start A lubridate: Date of first day in file
#' @param truncate Boolean: Whether or not to truncate the forecasts at the site maximum power
#' @param site_max_power A vector of the maximum power at ALL sites (not just those listed in sites)
get_netcdf_forecast_data <- function(fname, members, sites, lead_time, date_start, date_end,
                                     date_data_start=lubridate::ymd(20160101),
                                     ts_per_day=24, vname="power",
                                     truncate=F, site_max_power=NA) {

  if (truncate & all(is.na(site_max_power))) stop("Vector of site maximum powers required to truncate forecasts.")

  # Calculate netcdf date constants
  ndays <- get_ndays(date_start,date_end)
  start_day <- get_start_day(date_data_start, date_start)

  dim_counts <- c(ndays, ts_per_day, 1, 1, 1)

  # Open file
  nc <- nc_open(fname)

  # Get a matrix for this member and site
  member_data <- function(member, site) {
    dim_starts <- c(start_day,1, site, lead_time, member)
    return(ncvar_get(nc, varid=vname, start=dim_starts, count=dim_counts))
  }

  # Get a [member x day x hour] matrix at this site
  site_data <- function(site) {
    m <- sapply(members, FUN = member_data, site=site, simplify ="array")
    m[which(m > site_max_power[site])] <- site_max_power[site]
    return(m)
    }

  data <- sapply(sites, site_data, simplify="array")

  # Close the file!
  nc_close(nc)

  # Return in dimensions [site x member x time]
  return(array(aperm(data, c(4, 3, 2, 1)), dim=c(length(sites), length(members), ndays*ts_per_day)))
}


#' Load data from a NETCDF file of telemetry
#' Assumed file dimensions: Day x Hour x Site
#' Returns an array of data: [site x time]
#' Site selection can be vector of non-consecutive values
#' Time-point selection is a consecutive sequence
#' @param fname file name
#' @param sites A vector of sites
#' @param date_start A lubridate: Start date of data to load
#' @param date_end A lubridate: End date of data to load
get_netcdf_telemetry_data <- function(fname, sites, date_start, date_end,
                                     date_data_start=lubridate::ymd(20160101),
                                     ts_per_day=288, vname="hsl_power") {

  # Calculate netcdf date constants
  ndays <- get_ndays(date_start,date_end)
  start_day <- get_start_day(date_data_start, date_start)
  dim_counts <- c(ndays, ts_per_day, 1)

  # Open file
  nc <- nc_open(fname)

  site_data <- function(site) {
    return(ncvar_get(nc, varid=vname, start=c(start_day,1,site), count=dim_counts))
  }

  data <- sapply(sites, site_data, simplify="array")

  # Close the file!
  nc_close(nc)

  # Return in dimensions [site x time]
  return(array(aperm(data, c(3,2,1)), dim=c(length(sites), ndays*ts_per_day)))
}
