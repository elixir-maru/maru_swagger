# Used by "mix format"
[
  inputs: [
    ".formatter.exs",
    "mix.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  import_deps: [:maru],
  locals_without_parens: [
    swagger: 1
  ]
]
