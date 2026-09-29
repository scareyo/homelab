default:
  @just --list

mod omni

init:
  pre-commit install -t pre-commit -t pre-push
