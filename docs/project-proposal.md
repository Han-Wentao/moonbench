# MoonBench Project Proposal

## Basic Information

- Project name: MoonBench
- Participant: Han-Wentao
- Repository: https://github.com/Han-Wentao/moonbench
- Direction: MoonBit engineering infrastructure / benchmark utility
- Project type: Original MoonBit project
- License: MIT

## Project Summary

MoonBench is a lightweight stopwatch, benchmark reporting, and baseline
comparison toolkit for MoonBit projects. It helps MoonBit developers collect
repeatable micro-benchmark samples, export Markdown or JSON reports, and compare
current results with a historical baseline.

## Why It Matters

MoonBit ecosystem packages need simple and reproducible ways to describe
performance behavior in README files, pull requests, and release notes.
MoonBench provides a focused utility that is easy to test, easy to embed, and
aligned with the contest goal of building reusable MoonBit ecosystem packages.

## Core Scope

- Pure stopwatch state for deterministic manual measurements.
- Benchmark runner with warmup and iteration controls.
- Statistical summaries for min, max, mean, median, and standard deviation.
- JSON and Markdown report output.
- Baseline comparison with faster, stable, and slower statuses.
- Runnable examples and CI checks.

## Deliverables

- Public GitHub repository.
- GitLink synchronized repository.
- README with install, usage, and example instructions.
- MoonBit tests covering core behavior.
- GitHub Actions CI for check, test, and demo.
- Final development report and package publication notes.
