default:
  just --list

play playbook:
  ansible-playbook -i ./ansible/inventory.yaml ./ansible/{{ playbook }}.yaml --ask-become-pass

[working-directory: 'ansible']
ansible-lint:
  ansible-lint

init:
  pre-commit install -t pre-commit -t pre-push

build:
  nixidy switch .#seraphim
