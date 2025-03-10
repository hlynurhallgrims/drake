% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/outdated.R
\name{missed}
\alias{missed}
\title{Report any import objects required by your drake_plan
plan but missing from your workspace or file system.
\lifecycle{stable}}
\usage{
missed(config)
}
\arguments{
\item{config}{Internal runtime parameter list
produced by both \code{\link[=drake_config]{drake_config()}} and \code{\link[=make]{make()}}.}
}
\value{
Character vector of names of missing objects and files.
}
\description{
Checks your workspace/environment and
file system.
}
\examples{
\dontrun{
isolate_example("Quarantine side effects.", {
if (suppressWarnings(require("knitr"))) {
load_mtcars_example() # Get the code with drake_example("mtcars").
config <- drake_config(my_plan)
missed(config) # All the imported files and objects should be present.
rm(reg1) # Remove an import dependency from you workspace.
missed(config) # Should report that reg1 is missing.
}
})
}
}
\seealso{
\code{\link[=outdated]{outdated()}}
}
