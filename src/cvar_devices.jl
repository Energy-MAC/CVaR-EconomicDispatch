struct RenewableCvAR<:PSI.AbstractRenewableDispatchForm end

function PSI._internal_device_constructor!(canonical_model::PSI.CanonicalModel,                                      
                                       device_model::PSI.DeviceModel{PSY.RenewableDispatch, RenewableCvAR},
                                       ::Type{CVaRModel},
                                       sys::PSY.System;
                                       kwargs...)
    
    return

end