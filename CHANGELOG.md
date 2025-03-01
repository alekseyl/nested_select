## [0.4.1] - 2025-03-01
- Appraisal added as a development dependency
- added github CI 

## [0.4.0] - 2025-02-09
- through relations are now also supported and allowed to partial selection via reverse nested_selection tree
- README updated with more examples and corner cases
- nested_select will prevent multiple partial instantiation with different attributes

## [0.3.0] - 2025-01-25

- nested_select belongs_to limitation now prevents accidental foreign_key absence 
- primary keys are no longer need to be nested_selected
- nested selects will combine all selections on multiple select invocations like the usual select values does 
- tests restructured 
- test/README added
- removed biolerplates for basic selection ( you don't need to specify "table.*" in the root collection seletc )

## [0.2.0] - 2025-01-25

- Tests are now a part of this repo 
- Readme cleared out
- ABOUT_NESTED_SELECT md added.

## [0.1.0] - 2025-01-11

- Initial release
