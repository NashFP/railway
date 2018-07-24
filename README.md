# railway

FP experiments in railway oriented programming

## Background

On his blog and in talks, Scott Wlaschinn describes a software pattern for dealing with errors that he calls "railway oriented programming".
Blog here: "[F# for Fun and Profit](https://fsharpforfunandprofit.com/rop/)"

Two versions of his talk "Railway oriented programming: Error handling in functional languages" are below: 
* NDC London - https://vimeo.com/113707214
* NDC Oslo - https://vimeo.com/97344498

The abstract is...
> When you build real world applications, you are not always on the "happy path". You must deal with validation, logging, network and service errors, and other annoyances.
> How do you manage all this within a functional paradigm, when you can't use exceptions, or do early returns, and when you have no stateful data?
> This talk will demonstrate a common approach to this challenge, using a fun and easy-to-understand "railway oriented programming" analogy. You'll come away with insight into a powerful technique that handles errors in an elegant way using a simple, self-documenting design.

## Our task

Implement the pattern in your functional language of choice. 

### Checklist of tests

* Chain a series of functions that you own and that always return a good result
* Add a function in the middle of the chain that returns an error. 

### Contribute

Contribute your solution by creating a directory in this repo such as bryan_hunter+elixir

