
preprocessLines<-function(lines,objects){
  funct1<-"f<-function("
  funct2<-"){"
  funct3<-"}"
  funct4<-"f("
  funct5<-");"
  elemNames<-names(objects)
  processedLine<-funct1
  arguments<-paste(names(objects),collapse= ',')
  processedLine<-paste(processedLine,arguments)
  paste(processedLine,funct2,lines,funct3,";",funct4,arguments,funct5,sep="")
}

divideDataMat<-function(data,MARGIN){
  if(length(MARGIN)>1){
    if(MARGIN[1]==1){
      MARGIN<-1
    }
    else{
      MARGIN<-2
    }
  }
  if(MARGIN==2){
    data<-base::t(data)
    sequence<-cut(seq_along(data[,1]), pkg.env$n_nodes*2, labels = FALSE)
    dataS<-split(data.frame(data),sequence)
    for (i in 1:length(dataS)) {
      dataS[[i]]<-base::t(dataS[[i]])
    }
    return(dataS)
  }
  else{

    sequence<-cut(seq_along(data[,1]), pkg.env$n_nodes*2, labels = FALSE)
    return(split(data.frame(data),sequence))
  }
}
argumentsToString<-function(objects,...){
  namesObjects<-names(objects)
  str<-""
  for(i in 1:length(objects)){
    str<-paste(str,namesObjects[i],"=",namesObjects[i],",",sep="")
  }
  return(substr(str,1,nchar(str)-1))
}

serverUp<-function(resp){
  if(resp$status_code==502){
    stop("server down")
  }
}

fetchResultsSFTP<-function(file){
  tryCatch(
    {
      text_data <- as.raw(RCurl::getBinaryURL(file, userpwd = pkg.env$userpass))
      con <- gzcon(rawConnection(text_data))
      read<-readRDS(con)
      close(con)
      return(read)
    },
    error = function(e){
      token<-NULL
      stop("Server SFTP down")
    }
  )
}

waitForReady<-function(token){

  ready<-TRUE
  while(ready){
    resp<-httr::POST(pkg.env$finished_dir, body = token)
    if(rawToChar(resp$content)=="executing"){
      Sys.sleep(1)
    }
    else ready<-FALSE
  }
}


