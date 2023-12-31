% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{executeLines}
\alias{executeLines}
\title{Executes indicated lines}
\usage{
executeLines(lines, objects)
}
\arguments{
\item{lines}{String of lines to execute,for multiple lines these must be
separated by semicolons}

\item{objects}{List of named objects}
}
\value{
token for the operation
}
\description{
This function executes the given lines with objects as its dependencies. The
execution is carried out by one worker node depending on current
availability. Returns an unique token for the operation, for more information
on getting the results of the operation, see \link{getResults}.
}
\details{
The yield of the execution when completed will be the last line,therefore the
last line should not include any assignment, such as:

\code{lines<-"a<-c(1,2,3);b<-c(1,2,3);a+b;"}

where the competed operation will yield a+b

Graphs and intermediate results are not saved, therefore they should be
returned at the end of the code.

Objects must be placed in a named list where the objects names correspond to
the names used in \emph{lines}.
}
