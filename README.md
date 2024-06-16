# Compiler Project

This repository contains the source code and documentation for a compiler developed as part of a series of projects for a Compiler class. The projects cover various aspects of compiler construction, including grammar definition, semantic analysis, intermediate code generation, and more.

## Project Structure

The repository is organized into several key files and directories:

- `subc.l`: Lexical analyzer definition
- `subc.y`: Grammar and parser definition
- `subc.h`: Header file for the compiler
- `hash.c`: Functions related to hash table implementation
- `table.c`: Functions related to scope and symbol table management
- `check.c`: Functions for type checking and function formals validation
- `Makefile`: Build script for the project
- `README.md`: This documentation file

## Project 2: Grammar and Operator Precedence

### Summary

I defined the grammar and operator precedence for the `subc` compiler. We identified and resolved several shift/reduce conflicts that arose due to ambiguous operator precedence rules.

### Key Points

- Defined grammar rules and operator precedence for unary operators (`-`, `!`, `&`, `*`) and the operators `(`, `[`.
- Resolved 9 shift/reduce conflicts by adjusting precedence rules.
- Implemented precedence rules to resolve conflicts between `IF` statements with and without `ELSE`.

## Project 3: Semantic Analysis

### Summary

This project involved implementing semantic analysis for the compiler, ensuring that the correct semantic values are assigned to various types and declarations.

### Key Points

- Implemented semantic actions for grammar productions.
- Managed symbol tables and scopes using stack-based structures.
- Handled `NULL` keyword with a special `NIL` token.
- Implemented type checking and error handling for semantic analysis.

## Project 4: Intermediate Code Generation

### Summary

Building on the previous project, this phase focused on generating intermediate code for the compiler using specific reduction semantic actions.

### Key Points

- Implemented printing of intermediate code during specific reductions.
- Managed variable offsets and scope properties for memory allocation.
- Ensured proper handling of function calls and returns using mid-rule actions.
- Implemented `IF` statements with epsilon reductions to avoid conflicts.
- Handled struct and array type declarations with appropriate size calculations.

## Building the Project

To build the project, use the provided `Makefile`. Simply run:

```sh
make
```

## Running the Compiler

Once built, you can run the compiler using:

```sh
./subc <source_file>
```

Replace <source_file> with the path to the source file you want to compile.