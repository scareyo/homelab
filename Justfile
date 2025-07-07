default:
  just --list

play playbook:
  ansible-playbook -i ./ansible/inventory.yaml ./ansible/{{ playbook }}.yaml --ask-become-pass

[working-directory: 'ansible']
ansible-lint:
  ansible-lint
