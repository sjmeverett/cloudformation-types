export const nameSymbol = Symbol('name');

/**
 * Represents a CloudFormation resource.
 */
export interface ResourceDescription<
  TType extends string,
  TProps,
  TAttributes
> {
  Type: TType;
  Properties: TProps;
  DependsOn?: string[];
}

function createResource<TType extends string, TProps, TAttributes>(
  type: TType,
  name: string,
  properties: TProps,
): ResourceDescription<TType, TProps, TAttributes> {
  const description = {
    Type: type,
    Properties: properties,
  };

  Object.defineProperty(description, nameSymbol, {
    enumerable: false,
    value: name,
  });

  return description;
}

{{#each propertyTypes}}
/**
 * The `{{type}}` property type.
 * @see {{documentation}}
 */
export interface {{name}} {
  {{#each properties}}
  /**
    * @see {{documentation}}
    */
  {{name}}{{#if optional}}?{{/if}}: {{type}};
  {{/each}}
}

{{/each}}

{{#each attributeTypes}}
/**
 * Attributes for the `{{type}}` resource type.
 */
export interface {{name}}Attributes {
  {{#each properties}}
  "{{name}}"{{#if optional}}?{{/if}}: {{type}};
  {{/each}}
}
{{/each}}

{{#each resourceTypes}}
/**
 * Properties for the `{{type}}` resource type.
 * @see {{documentation}}
 */
export interface {{name}}Properties {
  {{#each properties}}
  /**
    * @see {{documentation}}
    */
  {{name}}{{#if optional}}?{{/if}}: {{type}};
  {{/each}}
}

/**
 * Creates a `{{type}}` resource.
 */
export function create{{name}}(
  name: string,
  properties: {{name}}Properties
): ResourceDescription<
  "{{type}}",
  {{name}}Properties,
  {{name}}Attributes
> {
  return createResource("{{type}}", name, properties);
}

{{/each}}


/**
 * Gets the instance name for the given resource.
 * @param resource The resource to get the name of
 */
export function getName(
  resource: ResourceDescription<string, unknown, unknown>,
): string {
  return (resource as any)[nameSymbol] as string;
}

/**
 * Declares that the resource is dependent on one or more other resources.
 * @param resource The resource to add dependencies to
 * @param dependencies The resource(s) on which the resource is dependent
 */
export function dependsOn(
  resource: ResourceDescription<string, unknown, unknown>,
  ...dependencies: ResourceDescription<string, unknown, unknown>[]
) {
  if (!resource.DependsOn) {
    resource.DependsOn = [];
  }

  resource.DependsOn.push(...dependencies.map(getName));
}

/**
 * Returns the ref for a resource.
 * @param resource
 */
export function getRef(
  resource: ResourceDescription<string, unknown, unknown>,
): string {
  return { Ref: getName(resource) } as any;
}

/**
 * Gets the attribute value.
 * @param resource The resource to get the attribute for.
 * @param name The name of the attribute to get.
 */
export function getAttribute<TAttributes, TName extends keyof TAttributes>(
  resource: ResourceDescription<string, unknown, TAttributes>,
  name: TName,
): TAttributes[TName] {
  return { 'Fn:GetAtt': [getName(resource), name] } as any;
}

/**
 * Gets the Resources map for your CloudFormation template from an array of resources.
 * @param resources the resources that make up the template, as created by any `create...` function
 */
export function getResources(
  resources: ResourceDescription<string, unknown, unknown>[],
) {
  const obj = {} as Record<
    string,
    ResourceDescription<string, unknown, unknown>
  >;

  resources.forEach((resource) => {
    obj[getName(resource)] = resource;
  });

  return resources;
}
