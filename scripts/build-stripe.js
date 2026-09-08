// Test connection metadata. Secret principal values are populated in Salesforce, never here.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const md = path.join(root, 'force-app/main/default');
const ns = 'http://soap.sforce.com/2006/04/metadata';
function write(relative, type, body) {
    const file = path.join(md, relative);
    fs.mkdirSync(path.dirname(file), {recursive: true});
    fs.writeFileSync(file, `<?xml version="1.0" encoding="UTF-8"?>\n<${type} xmlns="${ns}">\n${body}\n</${type}>\n`);
}
write('externalCredentials/NTE_Stripe_Test.externalCredential-meta.xml', 'ExternalCredential', `    <authenticationProtocol>Custom</authenticationProtocol>
    <description>Stripe test account. Populate the ApiKey authentication parameter securely on the NTEApplication principal.</description>
    <externalCredentialParameters>
        <parameterName>NTEApplication</parameterName>
        <parameterType>NamedPrincipal</parameterType>
        <sequenceNumber>1</sequenceNumber>
    </externalCredentialParameters>
    <externalCredentialParameters>
        <parameterName>Authorization</parameterName>
        <parameterType>AuthHeader</parameterType>
        <parameterValue>{!'Bearer ' &amp; $Credential.NTE_Stripe_Test.ApiKey}</parameterValue>
        <sequenceNumber>1</sequenceNumber>
    </externalCredentialParameters>
    <label>NTE Stripe Test</label>`);
write('namedCredentials/NTE_Stripe_Test.namedCredential-meta.xml', 'NamedCredential', `    <allowMergeFieldsInBody>false</allowMergeFieldsInBody>
    <allowMergeFieldsInHeader>true</allowMergeFieldsInHeader>
    <calloutStatus>Enabled</calloutStatus>
    <generateAuthorizationHeader>false</generateAuthorizationHeader>
    <label>NTE Stripe Test</label>
    <namedCredentialParameters>
        <parameterName>Url</parameterName>
        <parameterType>Url</parameterType>
        <parameterValue>https://api.stripe.com</parameterValue>
    </namedCredentialParameters>
    <namedCredentialParameters>
        <externalCredential>NTE_Stripe_Test</externalCredential>
        <parameterName>ExternalCredential</parameterName>
        <parameterType>Authentication</parameterType>
    </namedCredentialParameters>
    <namedCredentialType>SecuredEndpoint</namedCredentialType>`);
write('permissionsets/NTE_Stripe_Test_Operator.permissionset-meta.xml', 'PermissionSet', `    <classAccesses><apexClass>NTEStripeClient</apexClass><enabled>true</enabled></classAccesses>
    <description>Allows an authorised sandbox operator to use the secure NTE Stripe test principal.</description>
    <externalCredentialPrincipalAccesses><enabled>true</enabled><externalCredentialPrincipal>NTE_Stripe_Test-NTEApplication</externalCredentialPrincipal></externalCredentialPrincipalAccesses>
    <label>NTE Stripe Test Operator</label>`);

const components = {
    ApexClass: ['NTEStripeClient', 'NTEStripeClientTest'],
    ExternalCredential: ['NTE_Stripe_Test'], NamedCredential: ['NTE_Stripe_Test'],
    PermissionSet: ['NTE_Stripe_Test_Operator']
};
const file = path.join(root, 'manifest/production-package.xml');
let manifest = fs.readFileSync(file, 'utf8');
for (const [type, names] of Object.entries(components)) {
    const block = (manifest.match(/<types>[\s\S]*?<\/types>/g) || []).find(value => value.includes(`<name>${type}</name>`));
    const additions = names.filter(name => !block?.includes(`<members>${name}</members>`));
    if (!additions.length) continue;
    const members = additions.map(name => `        <members>${name}</members>`).join('\n');
    if (block) manifest = manifest.replace(block, block.replace(`        <name>${type}</name>`, `${members}\n        <name>${type}</name>`));
    else manifest = manifest.replace('    <version>', `    <types>\n${members}\n        <name>${type}</name>\n    </types>\n    <version>`);
}
fs.writeFileSync(file, manifest);
