from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.plugins.lookup import LookupBase
from ansible.errors import AnsibleError
from ansible.plugins.loader import lookup_loader

class LookupModule(LookupBase):

  def run(self, terms, variables=None, **kwargs):
    if len(terms) != 2:
      raise AnsibleError("secret lookup requires exactly two arguments: path and key")

    path, key = terms

    project_id = '64853e11f7a9ba1c4ac21cfd'
    env_slug = 'prod'

    plugin = lookup_loader.get('infisical.vault.read_secrets')

    result = plugin.run(
      terms=[],
      variables=variables,
      project_id=project_id,
      env_slug=env_slug,
      path=path
    )

    if not result or not isinstance(result[0], dict):
      raise AnsibleError("Expected list of dicts from infisical.vault.read_secrets")

    secrets = {item['key']: item['value'] for item in result}

    if key not in secrets:
      raise AnsibleError(f"Key '{key}' not found in secrets at path '{path}'")

    return [secrets[key]]
