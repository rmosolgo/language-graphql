makeTokenWithScopes = (value, scopes...) ->
  {
    value: value,
    scopes: ["source.graphql"].concat(scopes)
  }

makeNestedTokens = (nestedScopes...) ->
  (value, scopes...) ->
    allScopes = nestedScopes.concat(scopes)
    makeTokenWithScopes(value, allScopes...)

logTokens = (tokens) ->
  for t, idx in tokens
    console.log("#{idx}: #{t.value} (#{t.scopes.join(", ")})")


describe "GraphQL grammar", ->
  grammar = null

  getTokens = (line) ->
    {tokens} = grammar.tokenizeLine(line)
    tokens

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-graphql")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.graphql")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.graphql"

  it "tokenizes fragment definitions", ->
    tokens = getTokens('fragment myFragment on User')
    makeFragmentToken = makeNestedTokens("meta.fragment")
    expect(tokens[0]).toEqual makeFragmentToken("fragment", "storage.type")
    expect(tokens[2]).toEqual makeFragmentToken("myFragment", "variable.other")
    expect(tokens[4]).toEqual makeFragmentToken("on", "keyword.operator")
    expect(tokens[6]).toEqual makeFragmentToken("User", "support.class")

  it "tokenizes operation definitions", ->
    tokens = getTokens('mutation wreckStuff')
    makeOperationToken = makeNestedTokens("meta.operation")
    expect(tokens[0]).toEqual makeOperationToken("mutation", "storage.type")
    expect(tokens[2]).toEqual makeOperationToken("wreckStuff", "variable.other")

  it "tokenizes argument lists", ->
    tokens = getTokens('(str: "abc", bool: true, var: $myVar, int: 123, float: 12.3e15, enum: MY_ENUM)')
    makeArgToken = makeNestedTokens("meta.arguments")
    expect(tokens[1]).toEqual makeArgToken("str:", 'variable.parameter')
    expect(tokens[4]).toEqual makeArgToken('abc', 'string.quoted.double')
    expect(tokens[9]).toEqual makeArgToken('true', 'constant.language.boolean')
    expect(tokens[13]).toEqual makeArgToken('$myVar', 'constant.other.symbol')
    expect(tokens[17]).toEqual makeArgToken('123', 'constant.numeric')
    expect(tokens[21]).toEqual makeArgToken('12.3e15', 'constant.numeric')
    expect(tokens[25]).toEqual makeArgToken('MY_ENUM', 'support.constant.enum')

  it "tokenizes selection sets", ->
    tokens = getTokens("{ id @skip(if: false), ... myFields, ... on User { name } }")
    makeToken = makeNestedTokens("meta.selections")
    makeArgToken = makeNestedTokens("meta.selections", "meta.arguments")
    expect(tokens[2]).toEqual makeToken("@skip", 'storage.modifier')
    expect(tokens[4]).toEqual makeArgToken("if:", "variable.parameter")
    expect(tokens[9]).toEqual makeToken("...", 'keyword.operator')
    expect(tokens[11]).toEqual makeToken("myFields", 'variable.other')
    expect(tokens[15]).toEqual makeToken("on", 'keyword.operator')
    expect(tokens[17]).toEqual makeToken("User", 'support.class')
    expect(tokens[20]).toEqual makeToken(" name ", "meta.selections")

  it "tokenizes unnamed queries", ->
    tokens = getTokens("{ __schema { types { name }}}")
    makeToken = makeNestedTokens("meta.selections")
    expect(tokens[2]).toEqual makeToken("__schema", "keyword.other.graphql")

  it "tokenizes strings with escaped characters", ->
    tokens = getTokens('{ field(str: "my\\"Str\\u0025")}')
    makeToken = makeNestedTokens("meta.selections", "meta.arguments", "string.quoted.double")
    expect(tokens[6]).toEqual makeToken('my')
    expect(tokens[7]).toEqual makeToken('\\"', 'constant.character.escape.graphql')
    expect(tokens[8]).toEqual makeToken('Str')
    expect(tokens[9]).toEqual makeToken('\\u0025', 'constant.character.escape.graphql')

  it "tokenizes field aliases", ->
    tokens = getTokens('{ myAlias: field}')
    makeToken = makeNestedTokens("meta.selections")
    expect(tokens[2]).toEqual makeToken("myAlias:", "variable.other.alias.graphql")
