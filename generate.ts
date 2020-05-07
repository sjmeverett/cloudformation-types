import Handlebars from 'handlebars';
import { readFileSync, writeFileSync } from 'fs';

export function transform(spec: any) {
  const typeNames = new Set(Object.keys(spec.PropertyTypes));
  const propertyTypes = transformTypes(spec.PropertyTypes, { typeNames });

  const resourceTypes = transformTypes(spec.ResourceTypes, { typeNames });

  const attributeTypes = transformTypes(spec.ResourceTypes, {
    key: 'Attributes',
    typeNames,
  });

  return {
    propertyTypes,
    resourceTypes,
    attributeTypes,
  };
}

interface TransformTypesOptions {
  key?: string;
  typeNames: Set<string>;
}

function transformTypes(types: any, options: TransformTypesOptions) {
  const key = options?.key || 'Properties';

  return mapObject(types, (type, typeName) => {
    return {
      name: sanitiseName(typeName),
      type: typeName,
      documentation: type.Documentation,
      properties: mapObject(type[key] || {}, (property, propertyName) => {
        return {
          name: propertyName,
          type: getType(property, getNamespace(typeName), options.typeNames),
          documentation: property.Documentation,
          optional: property.Required === false,
        };
      }),
    };
  });
}

function getNamespace(name: string) {
  const index = name.lastIndexOf('.');
  return index > -1 ? name.substring(0, index) : name;
}

function mapObject<T>(
  obj: Record<string, any>,
  fn: (value: any, key: string) => T,
): T[] {
  return Object.keys(obj).map((key) => fn(obj[key], key));
}

function sanitiseName(name: string) {
  if (name.startsWith('AWS::')) {
    name = name.substring('AWS::'.length);
  }
  return name.replace(/[:.]/g, '');
}

function primitiveType(type: string) {
  switch (type) {
    case 'Boolean':
      return 'boolean';
    case 'Double':
    case 'Integer':
    case 'Long':
      return 'number';
    case 'Json':
      return 'object';
    case 'Timestamp':
    case 'String':
      return 'string';
    default:
      return null;
  }
}

function getType(spec: any, namespace: string, typeNames: Set<string>): string {
  const primitive = primitiveType(spec.PrimitiveType || spec.Type);

  if (primitive) {
    return primitive;
  } else if (spec.Type === 'List' || spec.Type === 'Map') {
    const type = getType(itemTypeToRegularType(spec), namespace, typeNames);
    return spec.Type === 'List' ? `${type}[]` : `Record<string, ${type}>`;
  } else if (typeNames.has(namespace + '.' + spec.Type)) {
    return sanitiseName(namespace + spec.Type);
  } else if (typeNames.has(spec.Type)) {
    return sanitiseName(spec.Type);
  } else {
    throw new Error(
      `Unknown type "${spec.Type}" or "${namespace}.${spec.Type}"`,
    );
  }
}

function itemTypeToRegularType(spec: any) {
  const { PrimitiveItemType, ItemType, ...rest } = spec;
  return { ...rest, PrimitiveType: PrimitiveItemType, Type: ItemType };
}

const spec = transform(require('./src/spec.json'));

const template = Handlebars.compile(readFileSync('./template.hb', 'utf8'), {
  noEscape: true,
});

const output = template(spec);
writeFileSync('./src/index.ts', output);
