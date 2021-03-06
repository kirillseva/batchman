context('batch')

batched_toupper <- batch(toupper, 'x',
  combination_strategy = paste, size = 1, batchman.verbose = FALSE)

batched_identity <- batch(identity, 'x',
   combination_strategy = c, size = 1, batchman.verbose = FALSE)

record_last_arg <- list()
record_first_arg <- list()

check_for_batch_length_of <- function(len) {
  batch_length <- 0
  batch_check <- function(x) { if (batch_length == 0) batch_length <<- length(x) }
  batch_check(seq(1:10))
  expect_equal(10, batch_length)
  batch_length <- 0
  batch_run <- batch(batch_check, 'x',
    combination_strategy = paste0, size = len, batchman.verbose = FALSE
  )
  batch_run(seq(1:10))
  expect_equal(len, batch_length)
}

for (i in seq(1:5)) {
  test_that(paste('it sends things in batches of size', i), {
    check_for_batch_length_of(i)
  })
}

test_that('it can recombine', {
  o <- batched_toupper(c('hi', 'hello', 'how are you'))
  expect_equal('HI HELLO HOW ARE YOU', o)
})

test_that('it errors with no matching keys', {
  batched_reverse <- batch(reverse, 'w',
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  expect_error(batched_reverse(c(1, 2, 3), c(4, 5, 6)), 'Bad keys')
})

test_that('it can batch twice by two keys', {
  batched_reverse <- batch(reverse, c('x', 'y'),
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  o <- batched_reverse(c(1, 2, 3), c(4, 5, 6))
  expect_equal(c(4, 1, 5, 2, 6, 3), o)
})

test_that('it can batch by two keys and include two nonbatched params', {
  record_last_arg <- list()
  add_first_and_second_arg <- function(w, x, y, z) {
    record_last_arg <<- z
    w + x
  }
  batched_add <- batch(add_first_and_second_arg, c('w', 'x'),
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  o <- batched_add(c(1, 2, 3), c(4, 5, 6), c(7, 8, 9), c(10, 11, 12))
  expect_equal(c(10, 11, 12), record_last_arg)
  expect_equal(c(5, 7, 9), o)
})

test_that('it can batch by two keys and include a nonbatched param as the first param', {
  add_second_and_third_arg <- function(x, y, z) {
    record_first_arg <<- x
    y + z
  }
  batched_add <- batch(add_second_and_third_arg, c('y', 'z'),
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  o <- batched_add(c(1, 2, 3), c(4, 5, 6), c(7, 8, 9))
  expect_equal(c(1, 2, 3), record_first_arg)
  expect_equal(c(11, 13, 15), o)
})

test_that('it can batch by two keys, surrounded by nonbatched params', {
  add_middle_args <- function(w, x, y, z) {
    record_first_arg <<- w
    record_last_arg <<- z
    x + y
  }
  batched_add <- batch(add_middle_args, c('x', 'y'),
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  o <- batched_add(c(10, 11, 12), c(13, 14, 15), c(16, 17, 18), c(19, 20, 21))
  expect_equal(c(10, 11, 12), record_first_arg)
  expect_equal(c(19, 20, 21), record_last_arg)
  expect_equal(c(29, 31, 33), o)
})

test_that('it can batch by an existant key and a nonexistant key', {
  batched_identity <- batch(identity, c('x', 'y'),
    combination_strategy = paste0, size = 1, batchman.verbose = FALSE
  )
  expect_equal('abc', batched_identity(c('a', 'b', 'c')))
})

test_that('it can batch by an existant key and a nonexistant key (the other way)', {
  batched_identity <- batch(identity, c('y', 'x'),
    combination_strategy = paste0, size = 1, batchman.verbose = FALSE
  )
  expect_equal('def', batched_identity(c('d', 'e', 'f')))
})

test_that('it can batch by either one or the other key provided', {
  apple_or_banana_fn <- function(apples = NULL, bananas = NULL) {
    if (!is.null(apples))
      paste('apples!', paste(apples, collapse=''))
    else
      paste('bananas!', paste(bananas, collapse=''))
  }
  batched_aob <- batch(apple_or_banana_fn, c('apples', 'bananas'),
    combination_strategy = c, size = 3, batchman.verbose = FALSE
  )
  a <- batched_aob(apples = c(1, 2, 3, 4, 5))
  expect_equal(c('apples! 123', 'apples! 45'), a)
  b <- batched_aob(bananas = c('a', 'b', 'c', 'd', 'e'))
  expect_equal(c('bananas! abc', 'bananas! de'), b)
})

test_that('it can handle functions with splats', {
  fruit_fn <- function(...) {
    if ('apples' %in% names(list(...))) return('apples!')
    if ('bananas' %in% names(list(...))) return('bananas!')
    if ('pears' %in% names(list(...))) return('pears!')
  }
  batched_fruit <- batch(fruit_fn, c('apples', 'bananas', 'pears'),
    combination_strategy = paste, size = 3, batchman.verbose = FALSE
  )
  expect_equal('apples! apples!', batched_fruit(apples = c(1,2,3,4,5)))
  expect_equal('bananas! bananas!', batched_fruit(bananas = c(1,2,3,4,5)))
  expect_equal('pears! pears!', batched_fruit(pears = c(1,2,3,4,5)))
})

test_that('it can handle functions with splats and no keys', {
  splat_fn <- function(...) { list(...) }
  batched_splat <- batch(splat_fn, '...', combination_strategy = c,
    size = 1, batchman.verbose = FALSE)
  o = batched_splat(c(1, 2, 3), c(5, 6, 7), c(8, 9, 0))
  expect_equal(list(1, 5, 8, 2, 6, 9, 3, 7, 0), o)
})

test_that('it must not evaluate unneeded arguments', {
  fn <- function(x, y) x
  batched_fn <- batch(fn, 'x',
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  expect_equal(1, batched_fn(1, identity()))  # If identity() were evaluated, it would error.
})

test_that('it can batch an argument that is pre-defined', {
  pre_defined_vars <- c('hi', 'hello', 'how are you')
  o <- batched_toupper(pre_defined_vars)
  expect_equal('HI HELLO HOW ARE YOU', o)
})

test_that('it returns NULL on a batch of NULL', {
  expect_null(batched_identity(NULL))
})

test_that('it returns NULL on a batch multiple NULLs', {
  expect_null(batched_identity(c(NULL, NULL, NULL)))
})

test_that('it returns NULL when batching a function that evaluates to NULL', {
  nuller <- function(...) NULL
  batched_nuller <- batch(nuller, keys = '...',
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  expect_null(batched_nuller(c(1, 2, 3)))
})

test_that('it ignores NULLs and still returns with mixed NULL / not NULL inputs', {
  expect_equal(c(1,2), batched_identity(c(NULL, 1, NULL, 2, NULL)))
})

test_that('it works with function calls', {
  fn2 <- function(x, y) x + y
  batched_fn <- batch(fn2, c('x', 'y'),
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  o <- batched_fn(identity(seq(1:10)), identity(seq(1:10)))
  expect_equal(seq(2, 20, by = 2), o)
})

test_that('it caches function calls', {
  sleep_time <- 0.01; length <- 10
  lengthy_function <- function(x) { Sys.sleep(sleep_time); x }
  speed <- system.time(batched_identity(lengthy_function(seq(1:length))))
  expect_true(speed['elapsed'] < sleep_time * length)
})

test_that('it can batch an argument that is a pre-defined function call', {
  pre_defined_vars <- identity(c('hi', 'hello', 'how are you'))
  o <- batched_toupper(pre_defined_vars)
  expect_equal('HI HELLO HOW ARE YOU', o)
})

test_that('it can batch a batched function', {
  pre_defined_vars <- c(1, 2, 3)
  nested_identity <- function(x) { batched_identity(x) }
  batched_nested <- batch(nested_identity, 'x',
    combination_strategy = c, size = 1, batchman.verbose = FALSE)
  expect_equal(c(1, 2, 3), batched_nested(pre_defined_vars))
})

test_that('it must be more efficient to batch than to execute an O(x^2) function directly', {
  # Simulate an O(x^2) function
  sleep_square <- function(input) Sys.sleep(length(input) ^ 2 * 10^-11)
  batched_sleep_square <- batch(sleep_square, 'input',
    combination_strategy = c, size = 2000, batchman.verbose = FALSE)
  require(microbenchmark)
  speeds <- summary(microbenchmark(times = 1,
    sleep_square(seq(1:10^5)),
    batched_sleep_square(seq(1:10^5))
  ))
  expect_true(speeds$median[[2]] < speeds$median[[1]])
})

test_that('it keeps processing with an error if trycatch is TRUE and stop is FALSE', {
  b_fn <- get_expect_error_fn(trycatch = TRUE, stop = FALSE)
  rbomb$reset()
  expect_equal(c(1, 1, 1, NA, 1), b_fn(c(fn1, fn1, fn1, rbomb$detonate, fn1)))
})

test_that('it stops with an error if trycatch is TRUE and stop is TRUE', {
  b_fn <- get_expect_error_fn(trycatch = TRUE, stop = TRUE)
  rbomb$reset()
  expect_error(b_fn(c(fn1, fn1, fn1, fn1, rbomb$detonate)))
})

test_that('it does not batch a bached function', {
  expect_identical(get_before_fn(batch(batch(identity, 'x'), 'x')), identity)
})

test_that('it does not overwrite verbose', {
  fn <- function(x, verbose = TRUE) {
    if(isTRUE(verbose)) cat('words')
    x
  }
  b_fn <- batch(fn, 'x', combination_strategy = c, size = 1, batchman.verbose = FALSE)
  expect_equal(b_fn(2, verbose = FALSE), 2)
})
