#' @title See the time it took to build each target.
#' \lifecycle{maturing}
#' @description Applies to targets in your plan, not imports or files.
#' @seealso [predict_runtime()]
#' @export
#' @return A data frame of times, each from [system.time()].
#' @inheritParams cached
#' @param ... Targets to load from the cache: as names (symbols) or
#'   character strings. If the `tidyselect` package is installed,
#'   you can also supply `dplyr`-style `tidyselect`
#'   commands such as `starts_with()`, `ends_with()`, and `one_of()`.
#' @param list Character vector of targets to select.
#' @param targets_only Deprecated.
#' @param digits How many digits to round the times to.
#' @param type Type of time you want: either `"build"`
#'   for the full build time including the time it took to
#'   store the target, or `"command"` for the time it took
#'   just to run the command.
#' @param verbose Deprecated on 2019-09-11.
#' @examples
#' \dontrun{
#' isolate_example("Quarantine side effects.", {
#' if (suppressWarnings(require("knitr"))) {
#' if (requireNamespace("lubridate")) {
#' # Show the build times for the mtcars example.
#' load_mtcars_example() # Get the code with drake_example("mtcars").
#' make(my_plan) # Build all the targets.
#' print(build_times()) # Show how long it took to build each target.
#' }
#' }
#' })
#' }
build_times <- function(
  ...,
  path = NULL,
  search = NULL,
  digits = 3,
  cache = drake::drake_cache(path = path),
  targets_only = NULL,
  verbose = NULL,
  jobs = 1,
  type = c("build", "command"),
  list = character(0)
) {
  deprecate_verbose(verbose)
  deprecate_search(search)
  deprecate_targets_only(targets_only) # 2019-01-03 # nolint
  if (is.null(cache)) {
    return(weak_as_tibble(empty_times()))
  }
  cache <- decorate_storr(cache)
  eval(parse(text = "require(methods, quietly = TRUE)")) # needed for lubridate
  targets <- c(as.character(match.call(expand.dots = FALSE)$...), list)
  if (requireNamespace("tidyselect", quietly = TRUE)) {
    targets <- drake_tidyselect_cache(
      ...,
      list = list,
      cache = cache,
      namespaces = "meta"
    )
  }
  if (!length(targets)) {
    targets <- parallel_filter(
      x = cache$list(namespace = "meta"),
      f = function(target) {
        !is_imported_cache(target = target, cache = cache) &&
        !is_encoded_path(target)
      },
      jobs = jobs
    )
  }
  if (!length(targets)) {
    return(weak_as_tibble(empty_times()))
  }
  type <- match.arg(type)
  out <- lightly_parallelize(
    X = targets,
    FUN = fetch_runtime,
    jobs = 1,
    cache = cache,
    type = type
  )
  out <- parallel_filter(out, f = is.data.frame, jobs = jobs)
  out <- do.call(drake_bind_rows, out)
  out <- drake_bind_rows(out, empty_times())
  out <- round_times(out, digits = digits)
  out <- to_build_duration_df(out)
  out <- out[order(out$target), ]
  tryCatch(
    weak_as_tibble(out),
    error = error_tibble_times
  )
}

error_tibble_times <- function(e) {
  stop(
    "Failed converting a data frame of times to a tibble. ",
    "Please install version 1.2.1 or greater of the pillar package.",
    call. = FALSE
  )
}

round_times <- function(times, digits) {
  for (col in time_columns) {
    if (length(times[[col]])) {
      times[[col]] <- round(times[[col]], digits = digits)
    }
  }
  times
}

to_build_duration_df <- function(times) {
  eval(parse(text = "require(methods, quietly = TRUE)")) # needed for lubridate
  for (col in time_columns) {
    if (length(times[[col]])) {
      times[[col]] <- to_build_duration(times[[col]])
    }
  }
  times
}

time_columns <- c("elapsed", "user", "system")

# From lubridate issue 472,
# we need to round to the nearest second
# for times longer than a minute.
to_build_duration <- function(x) {
  assert_pkg("lubridate")
  round_these <- x >= 60
  x[round_these] <- round(x[round_these], digits = 0)
  lubridate::dseconds(x)
}

fetch_runtime <- function(key, cache, type) {
  x <- read_from_meta(
    key = key,
    field = paste0("time_", type),
    cache = cache
  )
  if (is_bad_time(x)) {
    x <- empty_times()
  } else if (inherits(x, "proc_time")) {
    x <- runtime_entry(runtime = x, target = key)
  }
  weak_as_tibble(x)
}

is_bad_time <- function(x) {
  !length(x) || is.na(x[1])
}

empty_times <- function() {
  list(
    target = character(0),
    elapsed = numeric(0),
    user = numeric(0),
    system = numeric(0)
  )
}
