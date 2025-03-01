# Understanding `JSON.parse` in Motoko

## Core Type

The JSON library in Motoko represents JSON values using this variant type:

```motoko
public type Json = {
    #object_ : [(Text, Json)];  // JSON objects are arrays of key-value tuples
    #array : [Json];            // JSON arrays
    #string : Text;             // JSON strings
    #number : {                 // JSON numbers
        #int : Int;
        #float : Float;
    };
    #bool : Bool;               // JSON booleans
    #null_;                     // JSON null
};
```

Let's break down each variant:

1. `#object_ : [(Text, Json)]`

   - JSON objects (like `{"name": "John"}`) are stored as arrays of tuples
   - Each tuple has a Text key and a Json value
   - Example: `{"a": 1, "b": "hello"}` becomes `#object_([("a", #number(#int(1))), ("b", #string("hello"))])`

2. `#array : [Json]`

   - JSON arrays (`[1, "hello", true]`) are stored as arrays of Json values
   - Example: `[1, "hello"]` becomes `#array([#number(#int(1)), #string("hello")])`

3. `#string : Text`

   - JSON strings (`"hello"`) are stored as Motoko Text
   - Example: `"hello"` becomes `#string("hello")`

4. `#number : { #int : Int; #float : Float }`

   - JSON numbers can be either integers or floating point
   - Example: `42` becomes `#number(#int(42))`
   - Example: `3.14` becomes `#number(#float(3.14))`

5. `#bool : Bool`

   - JSON booleans (`true`/`false`) are stored as Motoko Bool
   - Example: `true` becomes `#bool(true)`

6. `#null_`
   - JSON null value is represented as a variant with no value
   - Example: `null` becomes `#null_`

This recursive type allows representing any valid JSON structure by combining these basic types.

## Parsing JSON

When you parse a JSON string:

```motoko
switch (JSON.parse(jsonText)) {
    case (#err(err)) { /* handle error */ };
    case (#ok(parsed)) { /* handle successful parse */ };
}
```

## Structure Example

Given this JSON:

```json
{
  "error": [],
  "result": {
    "ICPUSD": [[1737486000, "10.102", "10.102", "10.010", "10.025", "10.052", "996.92401218", 82]]
  }
}
```

It becomes this Motoko structure:

```motoko
#object_([  // Top-level object
    ("error", #array([])),  // Empty error array
    ("result", #object_([  // Result object
        ("ICPUSD", #array([  // ICPUSD array
            #array([  // First price entry
                #number(#int(1737486000)),
                #string("10.102"),
                #string("10.102"),
                #string("10.010"),
                #string("10.025"),
                #string("10.052"),
                #string("996.92401218"),
                #number(#int(82))
            ])
        ]))
    ]))
])
```

## Accessing Data

To access nested data, you need to:

1. Pattern match on each level.
2. Access array elements or tuple fields.
3. Handle each variant type appropriately.

### Example:

```motoko
switch (JSON.parse(jsonText)) {
    case (#err(err)) { "Parse error" };
    case (#ok(#object_(fields))) {
        let result_tuple = fields[1];  // Get ("result", ...)
        switch (result_tuple.1) {
            case (#object_(result_fields)) {
                let icpusd_tuple = result_fields[0];  // Get ICPUSD array
                switch (icpusd_tuple.1) {
                    case (#array(entries)) {
                        if (entries.size() > 0) {
                            debug_show(entries[0])  // Show first entry
                        } else { "No entries" };
                    };
                    case (_) { "Not an array" };
                };
            };
            case (_) { "Not an object" };
        };
    };
    case (#ok(_)) { "Not an object" };
}
```

## Note on Variant Syntax

The `#` prefix used in Motoko variants (like `#object_`, `#string`, etc.) is a unique feature of Motoko's type system. While the concept of tagged unions exists in other languages, the syntax is different:

```typescript
// Motoko variant
#object_([("name", #string("John"))])

// TypeScript equivalent (closest approximation)
{ type: 'object', value: [['name', { type: 'string', value: 'John' }]] }
```

In TypeScript/JavaScript, we typically use string literals, enums, or objects with type fields to achieve similar functionality. The `#` syntax in Motoko is a language-specific way to denote variant constructors, making the code more concise and the types more explicit at the syntax level.

### Variant Features in Motoko

1. Variant Injection: The syntax is `# <id> <exp>` or just `# <id>` for unit variants:

```motoko
let jsonString = #string("Hello");  // with value
let jsonNull = #null_;              // unit variant
```

2. Type Definition: Variants are defined using the same `#` syntax:

```motoko
type Color = {
    #Black;
    #White;
};
```

3. Variants with Associated Types: Each variant can have different associated types:

```motoko
type OsConfig = {
    #Mac;
    #Windows : Nat;
    #Linux : Text;
};
```

4. Pattern Matching: The `#` syntax enables powerful pattern matching:

```motoko
switch (jsonValue) {
    case (#string(text)) { /* handle string */ };
    case (#number(#int(n))) { /* handle integer */ };
    case (#object_(fields)) { /* handle object */ };
};
```

This variant system is a core feature of the Motoko language, not a library feature, and is used extensively in the JSON library and throughout Motoko programming.
