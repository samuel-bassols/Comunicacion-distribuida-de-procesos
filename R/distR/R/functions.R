#' distR
#'
#' Distributed system for computations. This package allows for
#' distributed computations in R's apply family of functions as well as
#' distributed computations writen by the user.This packages is to be used in
#' the client node when the worker nodes have been set up.
#'
#' @section Functions:
#' \link{setupWorkspace}
#' \link{ExecuteLines}
#' \link{getResults}
#' \link{distApply}
#' \link{distTApply}
#' \link{distLApply}
#' \link{distSApply}
#'
#'
#' @docType package
#' @name distR
NULL




pkg.env <- NULL



.onLoad <- function(...) {
  pkg.env <<-
    new.env(parent = emptyenv()) # when package is loaded, create new
                                 #environment to store needed variables
}

#' Sets up the configuration
#'
#' Reads the configuration.txt file and configures the environment. For more
#' information read the setup documentation
#'
#' @param filePath = "configuration.txt" Path to the input file
#' @export
setupWorkspace <- function(filePath = "configuration.txt") {

  conf <-
    read.table(
      filePath,
      sep = " ",
      comment.char = "#",
      header = FALSE,
      row.names = 1
    )
  assign("n_nodes", as.numeric(conf["n_nodes", 1]), envir = pkg.env)
  assign("in_dir", conf["in_dir", 1], envir = pkg.env)
  assign("out_dir", conf["out_dir", 1], envir = pkg.env)
  assign("userpass", conf["userpass", 1], envir = pkg.env)
  assign("start_dir", conf["start_dir", 1], envir = pkg.env)
  assign("finished_dir", conf["finished_dir", 1], envir = pkg.env)
  assign("retrieved_dir", conf["retrieved_dir", 1], envir = pkg.env)
  assign("user", conf["user", 1], envir = pkg.env)
  print("To see the execution progress check:")
  print(conf["web_page",1])
}



#' Executes indicated lines
#'
#' This function executes the given lines with objects as its dependencies. The
#' execution is carried out by one worker node depending on current
#' availability. Returns an unique token for the operation, for more information
#' on getting the results of the operation, see \link{getResults}.
#'
#' The yield of the execution when completed will be the last line,therefore the
#' last line should not include any assignment, such as:
#'
#' \code{lines<-"a<-c(1,2,3);b<-c(1,2,3);a+b;"}
#'
#' where the competed operation will yield a+b
#'
#' Graphs and intermediate results are not saved, therefore they should be
#' returned at the end of the code.
#'
#' Objects must be placed in a named list where the objects names correspond to
#' the names used in \emph{lines}.
#'
#' @param lines String of lines to execute,for multiple lines these must be
#'   separated by semicolons
#' @param objects List of named objects
#' @return token for the operation
#' @export
executeLines <- function(lines, objects) {

  token <- uuid::UUIDgenerate()
  #upload data file
  fil <- tempfile("temp", fileext = ".rds")
  saveRDS(objects, file = fil)

  #upload lines to execute
  lines <- preprocessLines(lines, objects)
  #print(lines)

  #ftp upload
  tryCatch(
    {
      RCurl::ftpUpload(fil,
                paste(pkg.env$in_dir, token, ".rds", sep = ""),
                userpwd = pkg.env$userpass)

      RCurl::ftpUpload(I(paste(lines,"\n",sep="")),
                to=paste(pkg.env$in_dir, token, ".txt", sep = ""),
                userpwd= pkg.env$userpass
      )
    },
    error = function(e){
      token<-NULL
      stop("Server FTP down")
    }
  )

  resp<-httr::POST(paste(pkg.env$start_dir,"?user=",pkg.env$user,sep=""), body = token)
  #print(paste(pkg.env$start_dir,"?user=",pkg.env$user,sep=""))
  serverUp(resp)
  token<-list(token=list(token),MARGIN=NULL)
  return(token)
}






#' Obtain the results of a computation
#'
#' Given the token of a previous computation return the R object that results from the operation.
#' This function blocks the system until the data has been retrieved, therefore should be used when the data returned is necessary for the users script to continue.
#' @param token Token from a previous computation
#'
#' @return R object corresponding to the results
#' @export
getResults <- function(token) {
  #apply token
  token_obj<-token
  result<-NULL
  token_list<-token_obj$token
  for(i in 1:length(token_list)){
    token<-token_list[[i]]
    resp<-httr::POST(pkg.env$finished_dir, body = token)
    serverUp(resp)
    if(rawToChar(resp$content)=="not_found"){
      stop("Execution for token not started")
    }

    #check if the file is ready
    waitForReady(token)
    resp<-httr::POST(pkg.env$finished_dir, body = token)
    if(rawToChar(resp$content)=="error"){
      file <- paste(pkg.env$out_dir, token, ".txt", sep = "")
      stop(RCurl::getURL(file, userpwd = pkg.env$userpass))
    }
    file <- paste(pkg.env$out_dir, token, ".rds", sep = "")
    data<-fetchResultsSFTP(file)
    if(is.null(token_obj$MARGIN)){
      result<-append(result,data)
    }
    else if(length(token_obj$MARGIN)==1&&(token_obj$MARGIN==1||
                                         token_obj$MARGIN==2)){
      if(!is.null(dim(data))){
        result<-cbind(result,data)
      }

      else{
        result<-c(result,data)
      }

    }else{
      if(is.na(dim(data)[3])){
        result<-rbind(result,data)
      }
      else{
        result<-abind::abind(result,data,along=2)
      }
    }
  }
  return(result)
}






#' Computes the distributed R apply function
#'
#' This function works the same way as \link[base]{apply}
#' Returns an unique token for the operation, for more information
#' on getting the results of the operation, see \link{getResults}.
#' @param X an array, including a matrix.
#' @param MARGIN  a vector which specifies the direction to which the function
#' will be applied to X.
#' @param ... Arguments of \link[base]{apply}
#'
#' @return token for the operation
#' @export
distApply <- function(X, MARGIN,...) {
  arggs <- c(as.list(environment()), list(...))

  dataDiv <- divideDataMat(X,MARGIN)
  arggsString <- argumentsToString(arggs[-1])
  tokenF<-list(token=list(),MARGIN=NULL)
  for (i in 1:length(dataDiv)) {
    lines <- paste("apply(elem,", arggsString, ")", sep = "")
    #print(lines)
    #print(data.frame(dataDiv[i]))
    arggsF <- append(arggs[-1], list(elem = data.frame(dataDiv[i])))
    token <- executeLines(lines, arggsF)
    tokenF$token<-append(tokenF$token, token$token)
  }
  tokenF$MARGIN=MARGIN
  return(tokenF)
}

#' Computes the distributed R tapply function
#'
#' This function works the same way as \link[base]{tapply}
#' Returns an unique token for the operation, for more information
#' on getting the results of the operation, see \link{getResults}.
#' @param X an array, including a matrix.
#' @param INDEX  factor of the same length as X.
#' @param ... Arguments of \link[base]{tapply}
#'
#' @return token for the operation
#' @export
distTApply <- function(X ,INDEX,...) {
  arggs <- c(as.list(environment()), list(...))
  dataDiv <- split(X,INDEX)
  #print(data)
  arggsString <- argumentsToString(arggs[-c(1:2)])
  #print(arggsString)
  tokenF<-list(token=list(),MARGIN=NULL)
  for (i in 1:length(dataDiv)) {
    lines <- paste("apply(elem,", arggsString,",","MARGIN" ,")", sep = "")
    arggsF <- append(arggs[-c(1:2)], list(elem = data.frame(dataDiv[i])))
    arggsF<-append(arggsF,list(MARGIN=2))
    token <- executeLines(lines, arggsF)
    tokenF$token<-append(tokenF$token, token$token)
  }
  tokenF$MARGIN=NULL
  return(tokenF)
}

#' Computes the distributed R lapply function.
#'
#' This function works the same way as \link[base]{lapply}
#' Returns an unique token for the operation, for more information
#' on getting the results of the operation, see \link{getResults}.
#' @param X a vector (atomic or list) if not coerced to list
#' @param ... Arguments of \link[base]{lapply}
#'
#' @return token for the operation
#' @export
distLApply <- function(X, ...) {
  arggs <- c(as.list(environment()), list(...))
  Xsplit<-split(as.list(X), cut(seq_along(as.list(X)), pkg.env$n_nodes*2, labels = FALSE))
  tokenF<-list(token=list(),MARGIN=NULL)
  arggsString <- argumentsToString(arggs[-1])

  for(i in Xsplit){
    lines <- paste("lapply(elem,", arggsString,")", sep = "")
    arggsF <- append(arggs[-1], list(elem = i))
    token <- executeLines(lines, arggsF)
    tokenF$token<-append(tokenF$token, token$token)
  }
  tokenF$MARGIN=NULL
  return(tokenF)
}
#' Computes the distributed R sapply function
#'
#' This function works the same way as \link[base]{sapply}
#' Returns an unique token for the operation, for more information
#' on getting the results of the operation, see \link{getResults}.
#' @param X a vector (atomic or list) if not coerced to list
#' @param ... Arguments of \link[base]{sapply}
#'
#' @return token for the operation
#' @export
distSApply <- function(X, ...) {
  arggs <- c(as.list(environment()), list(...))
  Xsplit<-split(as.list(X), cut(seq_along(as.list(X)), pkg.env$n_nodes*2, labels = FALSE))
  tokenF<-list(token=list(),MARGIN=NULL)
  arggsString <- argumentsToString(arggs[-1])
  for(i in Xsplit){
    lines <- paste("sapply(elem,", arggsString,")", sep = "")
    arggsF <- append(arggs[-1], list(elem = i))
    token <- executeLines(lines, arggsF)
    tokenF$token<-append(tokenF$token, token$token)
  }
  tokenF$MARGIN=NULL
  return(tokenF)
}


