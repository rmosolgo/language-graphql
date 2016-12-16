path = require 'path'
grammarTest = require 'atom-grammar-test'

describe 'Grammar', ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-graphql')

  grammarTest path.join(__dirname, '../fixtures/example.graphql')
