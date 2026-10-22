# Declaratively configures the jellyfin-plugin-sso OIDC provider by editing the
# plugin's XML config before Jellyfin starts. The file is merged rather than
# overwritten so state the plugin stores alongside it (CanonicalLinks, other
# providers, SAML configs) survives restarts.
import os
import xml.etree.ElementTree as ET

PATH = "/config/plugins/configurations/SSO-Auth.xml"
PROVIDER = "pocket-id"

ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
ET.register_namespace("xsd", "http://www.w3.org/2001/XMLSchema")

# Fields managed by this script; anything else in the provider config is left alone
settings = {
    "OidEndpoint": os.environ["issuer_url"],
    "OidClientId": os.environ["client_id"],
    "OidSecret": os.environ["client_secret"],
    "Enabled": True,
    "EnableAuthorization": True,
    "EnableAllFolders": True,
    "Roles": ["jellyfin-user"],
    "AdminRoles": ["jellyfin-admin"],
    "RoleClaim": "groups",
    "OidScopes": ["groups"],
    "DefaultUsernameClaim": "preferred_username",
    "AvatarUrlFormat": "@{picture}",
    "SchemeOverride": "https",
    "NewPath": True,
}

# Array fields the plugin expects to be non-null, initialized only if missing
defaults = ["EnabledFolders", "LiveTvRoles", "LiveTvManagementRoles", "FolderRoleMappings"]


def child(parent, tag):
    element = parent.find(tag)
    if element is None:
        element = ET.SubElement(parent, tag)
    return element


if os.path.exists(PATH):
    root = ET.parse(PATH).getroot()
else:
    root = ET.Element("PluginConfiguration")
    ET.SubElement(root, "SamlConfigs")

oid_configs = child(root, "OidConfigs")

config = None
for item in oid_configs.findall("item"):
    if item.findtext("key/string") == PROVIDER:
        config = item.find("value/PluginConfiguration")
        break

if config is None:
    item = ET.SubElement(oid_configs, "item")
    ET.SubElement(ET.SubElement(item, "key"), "string").text = PROVIDER
    config = ET.SubElement(ET.SubElement(item, "value"), "PluginConfiguration")

for tag, value in settings.items():
    element = child(config, tag)
    if isinstance(value, list):
        for existing in list(element):
            element.remove(existing)
        for v in value:
            ET.SubElement(element, "string").text = v
    elif isinstance(value, bool):
        element.text = "true" if value else "false"
    else:
        element.text = value

for tag in defaults:
    child(config, tag)

os.makedirs(os.path.dirname(PATH), exist_ok=True)
ET.indent(root)
ET.ElementTree(root).write(PATH + ".tmp", encoding="utf-8", xml_declaration=True)
os.replace(PATH + ".tmp", PATH)
print(f"Configured SSO provider '{PROVIDER}' in {PATH}")
