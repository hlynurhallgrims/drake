#' @title Interpret the plan and prepare for [make()]
#' \lifecycle{maturing}
#' @description [drake_config()] does all the preprocessing that
#'   [make()] needs to build targets. This includes interpreting
#'   the plan (from [drake_plan()]) and analyzing how all the
#'   targets fit together. The result is a list of objects
#'   that [make()] needs to keep track of everything during runtime.
#' @details Once you create a list with [drake_config()],
#'   do not modify it by hand.
#'
#'   Utility functions such as [outdated()],
#'   [vis_drake_graph()], and [predict_runtime()] require output from
#'   [drake_config()] for the `config` argument.
#'   If you supply a [drake_config()] object to the `config`
#'   argument of [make()], then `drake` will ignore all the other arguments
#'   because it already has everything it needs in `config`.
#' @inheritSection recoverable Recovery
#' @export
#' @return The master internal configuration list of a project.
#' @seealso [make()], [drake_plan()], [vis_drake_graph()]
#' @param plan Workflow plan data frame.
#'   A workflow plan data frame is a data frame
#'   with a `target` column and a `command` column.
#'   (See the details in the [drake_plan()] help file
#'   for descriptions of the optional columns.)
#'   Targets are the objects that drake generates,
#'   and commands are the pieces of R code that produce them.
#'   You can create and track custom files along the way
#'   (see [file_in()], [file_out()], and [knitr_in()]).
#'   Use the function [drake_plan()] to generate workflow plan
#'   data frames.
#'
#' @param targets Character vector, names of targets to build.
#'   Dependencies are built too. Together, the `plan` and
#'   `targets` comprise the workflow network
#'   (i.e. the `graph` argument).
#'   Changing either will change the network.
#'
#' @param envir Environment to use. Defaults to the current
#'   workspace, so you should not need to worry about this
#'   most of the time. A deep copy of `envir` is made,
#'   so you don't need to worry about your workspace being modified
#'   by `make`. The deep copy inherits from the global environment.
#'   Wherever necessary, objects and functions are imported
#'   from `envir` and the global environment and
#'   then reproducibly tracked as dependencies.
#'
#' @param verbose Integer, control printing to the console/terminal.
#'   - `0`: print nothing.
#'   - `1`: print targets, retries, and failures.
#'   - `2`: also show a spinner when preprocessing tasks are underway.
#'
#' @param hook Deprecated.
#'
#' @param skip_targets Logical, whether to skip building the targets
#'   in `plan` and just import objects and files.
#'
#' @param parallelism Character scalar, type of parallelism to use.
#'   For detailed explanations, see the
#'   [high-performance computing chapter](https://books.ropensci.org/drake/hpc.html) # nolint
#'   of the user manual.
#'
#'   You could also supply your own scheduler function
#'   if you want to experiment or aggressively optimize.
#'   The function should take a single `config` argument
#'   (produced by [drake_config()]). Existing examples
#'   from `drake`'s internals are the `backend_*()` functions:
#'   - `backend_loop()`
#'   - `backend_clustermq()`
#'   - `backend_future()`
#'   However, this functionality is really a back door
#'   and should not be used for production purposes unless you really
#'   know what you are doing and you are willing to suffer setbacks
#'   whenever `drake`'s unexported core functions are updated.
#'
#' @param jobs Maximum number of parallel workers for processing the targets.
#'   You can experiment with [predict_runtime()]
#'   to help decide on an appropriate number of jobs.
#'   For details, visit
#'   <https://books.ropensci.org/drake/time.html>.
#'
#' @param jobs_preprocess Number of parallel jobs for processing the imports
#'   and doing other preprocessing tasks.
#'
#' @param packages Character vector packages to load, in the order
#'   they should be loaded. Defaults to `rev(.packages())`, so you
#'   should not usually need to set this manually. Just call
#'   [library()] to load your packages before `make()`.
#'   However, sometimes packages need to be strictly forced to load
#'   in a certain order, especially if `parallelism` is
#'   `"Makefile"`. To do this, do not use [library()]
#'   or [require()] or [loadNamespace()] or
#'   [attachNamespace()] to load any libraries beforehand.
#'   Just list your packages in the `packages` argument in the order
#'   you want them to be loaded.
#'
#' @param lib_loc Character vector, optional.
#'   Same as in `library()` or `require()`.
#'   Applies to the `packages` argument (see above).
#'
#' @param prework Expression (language object), list of expressions,
#'   or character vector.
#'   Code to run right before targets build.
#'   Called only once if `parallelism` is `"loop"`
#'   and once per target otherwise.
#'   This code can be used to set global options, etc.
#'
#' @param prepend Deprecated.
#' @param command Deprecated.
#' @param args Deprecated.
#' @param recipe_command Deprecated.
#'
#' @param log_progress Logical, whether to log the progress
#'   of individual targets as they are being built. Progress logging
#'   creates extra files in the cache (usually the `.drake/` folder)
#'   and slows down `make()` a little.
#'   If you need to reduce or limit the number of files in the cache,
#'   call `make(log_progress = FALSE, recover = FALSE)`.
#'
#' @param cache drake cache as created by [new_cache()].
#'   See also [drake_cache()].
#'
#' @param fetch_cache Deprecated.
#'
#' @param timeout `deprecated`. Use `elapsed` and `cpu` instead.
#'
#' @param cpu Same as the `cpu` argument of `setTimeLimit()`.
#'   Seconds of cpu time before a target times out.
#'   Assign target-level cpu timeout times with an optional `cpu`
#'   column in `plan`.
#'
#' @param elapsed Same as the `elapsed` argument of `setTimeLimit()`.
#'   Seconds of elapsed time before a target times out.
#'   Assign target-level elapsed timeout times with an optional `elapsed`
#'   column in `plan`.
#'
#' @param retries Number of retries to execute if the target fails.
#'   Assign target-level retries with an optional `retries`
#'   column in `plan`.
#'
#' @param force Logical. If `FALSE` (default) then `drake`
#'   imposes checks if the cache was created with an old
#'   and incompatible version of drake.
#'   If there is an incompatibility, `make()` stops to
#'   give you an opportunity to
#'   downgrade `drake` to a compatible version
#'   rather than rerun all your targets from scratch.
#'
#' @param graph An `igraph` object from the previous `make()`.
#'   Supplying a pre-built graph could save time.
#'
#' @param trigger Name of the trigger to apply to all targets.
#'   Ignored if `plan` has a `trigger` column.
#'   See [trigger()] for details.
#'
#' @param skip_imports Logical, whether to totally neglect to
#'   process the imports and jump straight to the targets. This can be useful
#'   if your imports are massive and you just want to test your project,
#'   but it is bad practice for reproducible data analysis.
#'   This argument is overridden if you supply your own `graph` argument.
#'
#' @param skip_safety_checks Logical, whether to skip the safety checks
#'   on your workflow. Use at your own peril.
#'
#' @param lazy_load Either a character vector or a logical. Choices:
#'   - `"eager"`: no lazy loading. The target is loaded right away
#'     with [assign()].
#'   - `"promise"`: lazy loading with [delayedAssign()]
#'   - `"bind"`: lazy loading with active bindings:
#'     `bindr::populate_env()`.
#'   - `TRUE`: same as `"promise"`.
#'   - `FALSE`: same as `"eager"`.
#'
#'   `lazy_load` should not be `"promise"`
#'   for `"parLapply"` parallelism combined with `jobs` greater than 1.
#'   For local multi-session parallelism and lazy loading, try
#'   `library(future); future::plan(multisession)` and then
#'   `make(..., parallelism = "future_lapply", lazy_load = "bind")`.
#'
#'   If `lazy_load` is `"eager"`,
#'   drake prunes the execution environment before each target/stage,
#'   removing all superfluous targets
#'   and then loading any dependencies it will need for building.
#'   In other words, drake prepares the environment in advance
#'   and tries to be memory efficient.
#'   If `lazy_load` is `"bind"` or `"promise"`, drake assigns
#'   promises to load any dependencies at the last minute.
#'   Lazy loading may be more memory efficient in some use cases, but
#'   it may duplicate the loading of dependencies, costing time.
#'
#' @param session_info Logical, whether to save the `sessionInfo()`
#'   to the cache. This behavior is recommended for serious [make()]s
#'   for the sake of reproducibility. This argument only exists to
#'   speed up tests. Apparently, `sessionInfo()` is a bottleneck
#'   for small [make()]s.
#'
#' @param cache_log_file Name of the CSV cache log file to write.
#'   If `TRUE`, the default file name is used (`drake_cache.CSV`).
#'   If `NULL`, no file is written.
#'   If activated, this option writes a flat text file
#'   to represent the state of the cache
#'   (fingerprints of all the targets and imports).
#'   If you put the log file under version control, your commit history
#'   will give you an easy representation of how your results change
#'   over time as the rest of your project changes. Hopefully,
#'   this is a step in the right direction for data reproducibility.
#'
#' @param seed Integer, the root pseudo-random number generator
#'   seed to use for your project.
#'   In [make()], `drake` generates a unique
#'   local seed for each target using the global seed
#'   and the target name. That way, different pseudo-random numbers
#'   are generated for different targets, and this pseudo-randomness
#'   is reproducible.
#'
#'   To ensure reproducibility across different R sessions,
#'   `set.seed()` and `.Random.seed` are ignored and have no affect on
#'   `drake` workflows. Conversely, `make()` does not usually
#'   change `.Random.seed`,
#'   even when pseudo-random numbers are generated.
#'   The exception to this last point is
#'   `make(parallelism = "clustermq")`
#'   because the `clustermq` package needs to generate random numbers
#'   to set up ports and sockets for ZeroMQ.
#'
#'   On the first call to `make()` or `drake_config()`, `drake`
#'   uses the random number generator seed from the `seed` argument.
#'   Here, if the `seed` is `NULL` (default), `drake` uses a `seed` of `0`.
#'   On subsequent `make()`s for existing projects, the project's
#'   cached seed will be used in order to ensure reproducibility.
#'   Thus, the `seed` argument must either be `NULL` or the same
#'   seed from the project's cache (usually the `.drake/` folder).
#'   To reset the random number generator seed for a project,
#'   use `clean(destroy = TRUE)`.
#'
#' @param caching Character string, either `"master"` or `"worker"`.
#'   - `"master"`: Targets are built by remote workers and sent back to
#'     the master process. Then, the master process saves them to the
#'     cache (`config$cache`, usually a file system `storr`).
#'     Appropriate if remote workers do not have access to the file system
#'     of the calling R session. Targets are cached one at a time,
#'     which may be slow in some situations.
#'   - `"worker"`: Remote workers not only build the targets, but also
#'     save them to the cache. Here, caching happens in parallel.
#'     However, remote workers need to have access to the file system
#'     of the calling R session. Transferring target data across
#'     a network can be slow.
#'
#' @param keep_going Logical, whether to still keep running [make()]
#'   if targets fail.
#'
#' @param session Deprecated. Has no effect now.
#'
#' @param pruning_strategy Deprecated. See `memory_strategy`.
#'
#' @param memory_strategy Character scalar, name of the
#'   strategy `drake` uses to load/unload a target's dependencies in memory.
#'   You can give each target its own memory strategy,
#'   (e.g. `drake_plan(x = 1, y = target(f(x), memory_strategy = "lookahead"))`)
#'   to override the global memory strategy. Choices:
#'
#' - `"speed"`: Once a target is newly built or loaded in memory,
#'   just keep it there.
#'   This choice maximizes speed and hogs memory.
#' - `"autoclean"`: Just before building each new target,
#'   unload everything from memory except the target's direct dependencies.
#'   After a target is built, discard it from memory.
#'   (Set `garbage_collection = TRUE` to make sure it is really gone.)
#'   This option conserves memory, but it sacrifices speed because
#'   each new target needs to reload
#'   any previously unloaded targets from storage.
#' - `"preclean"`: Just before building each new target,
#'   unload everything from memory except the target's direct dependencies.
#'   After a target is built, keep it in memory until `drake` determines
#'   they can be unloaded.
#'   This option conserves memory, but it sacrifices speed because
#'   each new target needs to reload
#'   any previously unloaded targets from storage.
#' - `"lookahead"`: Just before building each new target,
#'   search the dependency graph to find targets that will not be
#'   needed for the rest of the current `make()` session.
#'   After a target is built, keep it in memory until the next
#'   memory management stage.
#'   In this mode, targets are only in memory if they need to be loaded,
#'   and we avoid superfluous reads from the cache.
#'   However, searching the graph takes time,
#'   and it could even double the computational overhead for large projects.
#' - `"unload"`: Just before building each new target,
#'   unload all targets from memory.
#'   After a target is built, **do not** keep it in memory.
#'   This mode aggressively optimizes for both memory and speed,
#'   but in commands and triggers,
#'   you have to manually load any dependencies you need using `readd()`.
#' - `"none"`: Do not manage memory at all.
#'   Do not load or unload anything before building targets.
#'   After a target is built, **do not** keep it in memory.
#'   This mode aggressively optimizes for both memory and speed,
#'   but in commands and triggers,
#'   you have to manually load any dependencies you need using `readd()`.
#'
#' For even more direct
#' control over which targets `drake` keeps in memory, see the
#' help file examples of [drake_envir()].
#' Also see the `garbage_collection` argument of `make()` and
#' `drake_config()`.
#'
#' @param makefile_path Deprecated.
#'
#' @param console_log_file Optional character scalar of a file name or
#'   connection object (such as `stdout()`) to dump maximally verbose
#'   log information for [make()] and other functions (all functions that
#'   accept a `config` argument, plus `drake_config()`).
#'   If you choose to use a text file as the console log,
#'   it will persist over multiple function calls
#'   until you delete it manually.
#'   Fields in each row the log file, from left to right:
#'       - The node name (short host name) of the
#'         computer (from `Sys.info()["nodename"]`).
#'       - The process ID (from `Sys.getpid()`).
#'       - A timestamp with the date and time (in microseconds).
#'       - A brief description of what `drake` was doing.`
#'   The fields are separated by pipe symbols (`"|"`).
#'
#' @param ensure_workers Deprecated.
#'
#' @param garbage_collection Logical, whether to call `gc()` each time
#'   a target is built during [make()].
#'
#' @param template A named list of values to fill in the `{{ ... }}`
#'   placeholders in template files (e.g. from [drake_hpc_template_file()]).
#'   Same as the `template` argument of `clustermq::Q()` and
#'   `clustermq::workers`.
#'   Enabled for `clustermq` only (`make(parallelism = "clustermq")`),
#'   not `future` or `batchtools` so far.
#'   For more information, see the `clustermq` package:
#'   <https://github.com/mschubert/clustermq>.
#'   Some template placeholders such as `{{ job_name }}` and `{{ n_jobs }}`
#'   cannot be set this way.
#'
#' @param sleep Optional function on a single numeric argument `i`.
#'   Default: `function(i) 0.01`.
#'
#'   To conserve memory, `drake` assigns a brand new closure to
#'   `sleep`, so your custom function should not depend on in-memory data
#'   except from loaded packages.
#'
#'   For parallel processing, `drake` uses
#'   a central master process to check what the parallel
#'   workers are doing, and for the affected high-performance
#'   computing workflows, wait for data to arrive over a network.
#'   In between loop iterations, the master process sleeps to avoid throttling.
#'   The `sleep` argument to `make()` and `drake_config()`
#'   allows you to customize how much time the master process spends
#'   sleeping.
#'
#'   The `sleep` argument is a function that takes an argument
#'   `i` and returns a numeric scalar, the number of seconds to
#'   supply to `Sys.sleep()` after iteration `i` of checking.
#'   (Here, `i` starts at 1.)
#'   If the checking loop does something other than sleeping
#'   on iteration `i`, then `i` is reset back to 1.
#'
#'   To sleep for the same amount of time between checks,
#'   you might supply something like `function(i) 0.01`.
#'   But to avoid consuming too many resources during heavier
#'   and longer workflows, you might use an exponential
#'   back-off: say,
#'   `function(i) { 0.1 + 120 * pexp(i - 1, rate = 0.01) }`.
#'
#' @param hasty_build A user-defined function.
#'   In "hasty mode" (`make(parallelism = "hasty")`)
#'   this is the function that evaluates a target's command
#'   and returns the resulting value. The `hasty_build` argument
#'   has no effect if `parallelism` is any value other than "hasty".
#'
#'   The function you pass to `hasty_build` must have arguments `target`
#'   and `config`. Here, `target` is a character scalar naming the
#'   target being built, and `config` is a configuration list of
#'   runtime parameters generated by [drake_config()].
#'
#' @param layout `config$layout`, where `config` is the return value
#'   from a prior call to `drake_config()`. If your plan or environment
#'   have changed since the last `make()`, do not supply a `layout` argument.
#'   Otherwise, supplying one could save time.
#'
#' @param lock_envir Logical, whether to lock `config$envir` during `make()`.
#'   If `TRUE`, `make()` quits in error whenever a command in your
#'   `drake` plan (or `prework`) tries to add, remove, or modify
#'   non-hidden variables in your environment/workspace/R session.
#'   This is extremely important for ensuring the purity of your functions
#'   and the reproducibility/credibility/trust you can place in your project.
#'   `lock_envir` will be set to a default of `TRUE` in `drake` version
#'   7.0.0 and higher.
#'
#' @param history Logical, whether to record the build history
#'   of your targets. You can also supply a
#'   [`txtq`](https://github.com/wlandau/txtq), which is
#'   how `drake` records history.
#'   Must be `TRUE` for [drake_history()] to work later.
#'
#' @param recover Logical, whether to activate automated data recovery.
#'   The default is `FALSE` because
#'
#'   1. Automated data recovery is still experimental.
#'   2. It has reproducibility issues.
#'   Targets recovered from the distant past may have been generated
#'   with earlier versions of R and earlier package environments
#'   that no longer exist.
#'
#'   How it works: if `recover` is `TRUE`,
#'   `drake` tries to salvage old target values from the cache
#'   instead of running commands from the plan.
#'   A target is recoverable if
#'
#'   1. There is an old value somewhere in the cache that
#'      shares the command, dependencies, etc.
#'      of the target about to be built.
#'   2. The old value was generated with `make(recoverable = TRUE)`.
#'
#'   If both conditions are met, `drake` will
#'
#'   1. Assign the most recently-generated admissible data to the target, and
#'   2. skip the target's command.
#'
#'   Functions [recoverable()] and [r_recoverable()] show the most upstream
#'   outdated targets that will be recovered in this way in the next
#'   [make()] or [r_make()].
#'
#' @param recoverable Logical, whether to make target values recoverable
#'   with `make(recover = TRUE)`.
#'   This requires writing extra files to the cache,
#'   and it prevents old metadata from being removed with garbage collection
#'   (`clean(garbage_collection = TRUE)`, `gc()` in `storr`s).
#'   If you need to limit the cache size or the number of files in the cache,
#'   consider `make(recoverable = FALSE, progress = FALSE)`.
#'
#' @param curl_handles A named list of curl handles. Each value is an
#'   object from `curl::new_handle()`, and each name is a URL
#'   (and should start with "http", "https", or "ftp").
#'   Example:
#'   list(
#'     `http://httpbin.org/basic-auth` = curl::new_handle(
#'       username = "user", password = "passwd"
#'     )
#'   )
#'   Then, if your plan has
#'   `file_in("http://httpbin.org/basic-auth/user/passwd")`
#'   `drake` will authenticate using the username and password of the handle
#'   for `http://httpbin.org/basic-auth/`.
#'
#'   `drake` uses partial matching on text to
#'   find the right handle of the `file_in()` URL, so the name of the handle
#'   could be the complete URL (`"http://httpbin.org/basic-auth/user/passwd"`)
#'   or a part of the URL (e.g. `"http://httpbin.org/"` or
#'   `"http://httpbin.org/basic-auth/"`). If you have multiple handles
#'   whose names match your URL, `drake` will choose the closest match.
#'
#' @param max_expand Positive integer, optional.
#'   `max_expand` is the maximum number of targets to generate in each
#'   `map()`, `cross()`, or `combine()` dynamic transform.
#'   Useful if you have a massive number of dynamic sub-targets and you want to
#'   work with only the first few sub-targets before scaling up.
#'   Note: the `max_expand` argument of `make()` and
#'   `drake_config()` is for dynamic branching only.
#'   The static branching `max_expand`
#'   is an argument of `drake_plan()` and `transform_plan()`.
#'
#' @examples
#' \dontrun{
#' isolate_example("Quarantine side effects.", {
#' load_mtcars_example() # Get the code with drake_example("mtcars").
#' # Construct the master internal configuration list.
#' config <- drake_config(my_plan)
#' if (requireNamespace("visNetwork")) {
#'   vis_drake_graph(config) # See the dependency graph.
#'   if (requireNamespace("networkD3")) {
#'     sankey_drake_graph(config) # See the dependency graph.
#'   }
#' }
#' # These functions are faster than otherwise
#' # because they use the configuration list.
#' outdated(config) # Which targets are out of date?
#' missed(config) # Which imports are missing?
#' })
#' }
drake_config <- function(
  plan,
  targets = NULL,
  envir = parent.frame(),
  verbose = 1L,
  hook = NULL,
  cache = drake::drake_cache(),
  fetch_cache = NULL,
  parallelism = "loop",
  jobs = 1L,
  jobs_preprocess = 1L,
  packages = rev(.packages()),
  lib_loc = NULL,
  prework = character(0),
  prepend = NULL,
  command = NULL,
  args = NULL,
  recipe_command = NULL,
  timeout = NULL,
  cpu = Inf,
  elapsed = Inf,
  retries = 0,
  force = FALSE,
  log_progress = TRUE,
  graph = NULL,
  trigger = drake::trigger(),
  skip_targets = FALSE,
  skip_imports = FALSE,
  skip_safety_checks = FALSE,
  lazy_load = "eager",
  session_info = TRUE,
  cache_log_file = NULL,
  seed = NULL,
  caching = c("master", "worker"),
  keep_going = FALSE,
  session = NULL,
  pruning_strategy = NULL,
  makefile_path = NULL,
  console_log_file = NULL,
  ensure_workers = NULL,
  garbage_collection = FALSE,
  template = list(),
  sleep = function(i) 0.01,
  hasty_build = NULL,
  memory_strategy = "speed",
  layout = NULL,
  lock_envir = TRUE,
  history = TRUE,
  recover = FALSE,
  recoverable = TRUE,
  curl_handles = list(),
  max_expand = NULL
) {
  logger <- logger(verbose = verbose, file = console_log_file)
  logger$minor("begin drake_config()")
  deprecate_fetch_cache(fetch_cache)
  deprecate_arg(hook, "hook") # 2018-10-25 # nolint
  # 2018-11-01 # nolint
  deprecate_arg(pruning_strategy, "pruning_strategy", "memory_strategy")
  deprecate_arg(timeout, "timeout", "elapsed and/or cpu")
  deprecate_arg(graph, "graph")
  deprecate_arg(layout, "layout")
  deprecate_arg(hasty_build, "hasty_build")
  deprecate_arg(session, "session")
  deprecate_arg(ensure_workers, "ensure_workers")
  deprecate_arg(command, "command")
  deprecate_arg(args, "args")
  deprecate_arg(recipe_command, "recipe_command")
  deprecate_arg(prepend, "prepend")
  deprecate_arg(makefile_path, "makefile_path")
  memory_strategy <- match.arg(memory_strategy, choices = memory_strategies())
  if (memory_strategy == "memory") {
    memory_strategy <- "preclean"
    warning(
      "make(memory_strategy = \"memory\") is deprecated. ",
      "Use make(memory_strategy = \"preclean\") instead",
      call. = FALSE
      # 2019-06-22 # nolint
    )
  }
  force(envir)
  plan <- sanitize_plan(plan, envir = envir)
  plan_checks(plan)
  targets <- sanitize_targets(targets, plan)
  trigger <- convert_old_trigger(trigger)
  sleep <- `environment<-`(sleep, new.env(parent = globalenv()))
  if (is.null(cache)) {
    cache <- new_cache()
  }
  cache <- decorate_storr(cache)
  cache$set_history(history)
  logger$minor("cache", cache$path)
  seed <- choose_seed(supplied = seed, cache = cache)
  if (identical(force, TRUE)) {
    drake_set_session_info(cache = cache, full = session_info)
  }
  layout <- create_drake_layout(
    plan = plan,
    envir = envir,
    logger = logger,
    jobs = jobs_preprocess,
    trigger = trigger,
    cache = cache
  )
  ht_dynamic_deps <- new_ht_dynamic_deps(layout)
  graph <- create_drake_graph(
    plan = plan,
    layout = layout,
    targets = targets,
    cache = cache,
    jobs = jobs_preprocess,
    logger = logger
  )
  lazy_load <- parse_lazy_arg(lazy_load)
  caching <- match.arg(caching)
  recover <- as.logical(recover)
  recoverable <- as.logical(recoverable)
  envir_targets <- new.env(parent = envir)
  out <- list(
    envir = envir,
    envir_graph = new.env(parent = emptyenv()),
    envir_targets = envir_targets,
    envir_subtargets = new.env(parent = envir_targets),
    cache = cache,
    parallelism = parallelism,
    jobs = jobs,
    jobs_preprocess = jobs_preprocess,
    logger = logger,
    packages = packages,
    lib_loc = lib_loc,
    prework = prework,
    layout = layout,
    graph = graph,
    seed = seed,
    trigger = trigger,
    timeout = timeout,
    cpu = cpu,
    elapsed = elapsed,
    retries = retries,
    skip_targets = skip_targets,
    skip_imports = skip_imports,
    skip_safety_checks = skip_safety_checks,
    log_progress = log_progress,
    lazy_load = lazy_load,
    session_info = session_info,
    cache_log_file = cache_log_file,
    caching = caching,
    keep_going = keep_going,
    memory_strategy = memory_strategy,
    garbage_collection = garbage_collection,
    template = template,
    sleep = sleep,
    hasty_build = hasty_build,
    lock_envir = lock_envir,
    force = force,
    recover = recover,
    recoverable = recoverable,
    curl_handles = curl_handles,
    ht_dynamic_deps = ht_dynamic_deps,
    max_expand = max_expand
  )
  config_checks(out)
  logger$minor("end drake_config()")
  out
}

new_ht_dynamic_deps <- function(layout) {
  ht <- ht_new()
  lapply(layout, log_ht_dynamic_deps, ht = ht)
  ht
}

log_ht_dynamic_deps <- function(layout, ht) {
  ht_set(ht, layout$deps_dynamic)
}

sanitize_targets <- function(targets, plan) {
  if (is.null(try(targets, silent = TRUE))) {
    return(plan$target)
  }
  targets <- make.names(targets, unique = FALSE, allow_ = TRUE)
  not_found <- setdiff(targets, plan$target)
  if (length(not_found)) {
    warning(
      "ignoring targets not in the drake plan:\n",
      multiline_message(not_found),
      call. = FALSE
    )
  }
  out <- unique(intersect(targets, plan$target))
  if (!length(out)) {
    stop("no valid targets specified.", call. = FALSE)
  }
  out
}

memory_strategies <- function() {
  c(
    "speed",
    "autoclean",
    "preclean",
    "lookahead",
    "unload",
    "none",
    "memory" # deprecated on 2019-06-22
  )
}

choose_seed <- function(supplied, cache) {
  supplied %||%
    get_previous_seed(cache = cache) %||%
    0L
}

get_previous_seed <- function(cache) {
  if (cache$exists(key = "seed", namespace = "session")) {
    cache$get(key = "seed", namespace = "session")
  } else {
    NULL
  }
}

# Load an existing drake files system cache if it exists
# or create a new one otherwise.
# TO DO: remove all the arguments when we make recover_cache() defunct.
recover_cache_ <- function(path = NULL, hash_algorithm = NULL) {
  path <- path %||% default_cache_path()
  hash_algorithm <- sanitize_hash_algorithm(hash_algorithm)
  cache <- this_cache_(path = path)
  if (is.null(cache)) {
    cache <- new_cache(path = path, hash_algorithm = hash_algorithm)
  }
  cache
}

plan_checks <- function(plan) {
  stopifnot(is.data.frame(plan))
  plan_check_required_cols(plan)
  plan_check_bad_symbols(plan)
  plan_check_format_col(plan)
}

plan_check_required_cols <- function(plan) {
  if (!all(c("target", "command") %in% colnames(plan))) {
    stop(
      "The columns of your workflow plan data frame ",
      "must include 'target' and 'command'.",
      call. = FALSE
    )
  }
}

plan_check_bad_symbols <- function(plan) {
  if (any(bad_symbols %in% plan$target)) {
    stop(
      "symbols that cannot be target names: \n",
      multiline_message(shQuote(bad_symbols)),
      call. = FALSE
    )
  }
}

plan_check_format_col <- function(plan) {
  if (!("format" %in% colnames(plan))) {
    return()
  }
  format <- plan$format
  format <- format[!is.na(format)]
  formats <- c("fst", "fst_dt", "diskframe", "keras", "rds")
  illegal <- setdiff(unique(format), formats)
  if (!length(illegal)) {
    return()
  }
  formats_str <- paste0("\"", formats, "\"")
  formats_str <- paste(formats_str, collapse = ", ")
  stop(
    "the format column of your drake plan can only have values ",
    formats_str,
    ", or NA. Illegal values found:\n",
    multiline_message(illegal),
    call. = FALSE
  )
}

config_checks <- function(config) {
  if (identical(config$skip_safety_checks, TRUE)) {
    return(invisible())
  }
  check_case_sensitivity(config)
  check_drake_graph(graph = config$graph)
  cache_vers_stop(config$cache)
  check_parallelism(config$parallelism, config$jobs)
  check_jobs(config$jobs)
}

check_case_sensitivity <- function(config) {
  x <- igraph::V(config$graph)$name
  x <- x[!is_encoded_path(x) & !is_encoded_namespaced(x)]
  lower <- tolower(x)
  i <- duplicated(lower)
  if (!any(i)) {
    return()
  }
  dups <- sort(x[which(lower %in% lower[i])])
  warning(
    "Duplicated target/import names when converting to lowercase:\n",
    multiline_message(dups),
    "\nDuplicates cause problems on Windows ",
    "because the file system is case insensitive. Options:\n",
    "  (1) Make your target/import names more unique.\n",
    "  (2) Use a more portable custom cache, ",
    "e.g. make(cache = storr::storr_rds(mangle_key = TRUE))\n",
    "  (3) Avoid Windows.",
    call. = FALSE
  )
}

check_drake_graph <- function(graph) {
  if (is_dag(graph)) {
    return()
  }
  comp <- igraph::components(graph, mode = "strong")
  cycle_component_indices <- which(comp$csize > 1)
  cycles <- lapply(cycle_component_indices, function(i) {
    out <- names(comp$membership[comp$membership == i])
    out <- paste(out, collapse = " ")
  })
  cycles <- unlist(cycles)
  stop(
    "Circular workflow:\n",
    "  at least one target in your drake plan\n",
    "  ultimately depends on itself.\n",
    "If you believe a dependency was detected in error\n",
    "  (example: https://github.com/ropensci/drake/issues/578)\n",
    "  then consider using ignore() to mask sections \n",
    "  of your commands or imported functions.\n",
    "Cycles:\n",
    multiline_message(cycles),
    call. = FALSE
  )
}

check_parallelism <- function(parallelism, jobs) {
  stopifnot(is.character(parallelism) || is.function(parallelism))
  stopifnot(length(parallelism) > 0)
  if (length(parallelism) > 1) {
    stop(
      "The `parallelism` argument of `make()` should be of length 1.",
      call. = FALSE
    )
  }
  if (identical(parallelism, "loop") && jobs > 1L) {
    warning(
      "In make(), `parallelism` should not be \"loop\" if `jobs` > 1",
      call. = FALSE
    )
  }
}

check_jobs <- function(jobs) {
  stopifnot(length(jobs) > 0)
  stopifnot(is.numeric(jobs) || is.integer(jobs))
  stopifnot(all(jobs > 0))
  if (length(jobs) > 1) {
    stop(
      "The `jobs` argument of `make()` should be of length 1. ",
      "Use the `jobs_preprocess` argument to parallelize the imports ",
      "and other preprocessing tasks.",
      call. = FALSE
    )
  }
}
