getReturns <- function(dex, cum=T, ids=NULL, rdb=NULL, dxn=P_DXN, idn=P_IDN, rtn=P_RTN, gm=T)
{
  # Forms a panel of returns for the given ids/periods; optionally computes the cumulative returns
  #
  # Args:
  #   dex: list of time periods
  #   ids: list of ids (NULL = use all available)
  #   rdb: data frame containing return data (default = NULL: use global default)
  #   dxn: column name for dex (default = P_DXN)
  #   idn: column name for ids (default = P_IDN)
  #   rtn: column name for returns (default = P_RTN)
  #   gm: geometric sum if true; arithmetic sum otherwise
  #   parms: list of parameters (TODO)
  #
  # Returns:
  #   Table containing ids and cumulative returns
  
  # Get global default return data set if none is specified
  if(is.null(rdb)) rdb = get(P_RETDB, globalenv())
  
  # Order dex and ids
  dex <- dex[order(dex)]
  if(!is.null(ids)) ids <- ids[order(ids)]
  
  # Pre-slice the data
  slc <- rdb[rdb[,dxn]>=min(dex) & rdb[,dxn]<=max(dex),c(dxn, idn, rtn)]
  rm(rdb)
  
  # Put IDs into a data frame
  if(!is.null(ids)) {
    out <- as.data.frame(ids)
    names(out) <- idn
  } else {
    out <- as.data.frame(slicer(slc, dex[length(dex)], NULL)[,idn])
    names(out) <- idn
  }
  
  # Initialize cumulative returns
  out[,"cret"] <- 1
  
  # Merge in returns from the specified periods
  for (cd in dex) {
    # Merge in current period returns
    out <- merge(out, slicer(slc, cd, NULL)[,c(idn, rtn)], by=idn, all=T)
    # Add to the cumulative returns
    if (gm) {
      out[,"cret"] <- out[,"cret"] * pmax(0, 1 + out[,rtn])
    } else {
      out[,"cret"] <- out[,"cret"] + out[,rtn]
    }
    # Rename returns to keep if the full panel is requested
    if(!cum) out[,paste0('r',cd)] <- out[,rtn]
    # Remove current period returns
    out[,rtn] <- NULL
  }
  
  # If geometric sum, convert gross to net returns
  # If arithmetic sum, remove the initial value of 1
  out[,"cret"] <- out[,"cret"] - 1
  # if (!gm)
  
  # Remove NA entries only if cumulative returns are requested
  if(cum) out <- out[!is.na(out[,"cret"]), ]
  
  # Remove cumulative returns (cret) if they are not wanted
  if(!cum) out[,"cret"] <- NULL
  
  # print(head(out))
  
  return(out)
  
}

# cr = getReturns(501:512, cum=F, gm=F)
# cr = cr[order(cr$permno),]
# cr2 = cumReturns(501:512, gm=T)
# cr2 = cr2[order(cr2$permno),]
# all(cr[,3:14]==cr2[,3:14])
# plot(cr$cret[1:100],cr2$cret[1:100])
# copy(cr2[1:100,],col.names=T)
# rm(cr,cr2)