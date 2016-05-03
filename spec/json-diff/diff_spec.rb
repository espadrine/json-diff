require 'spec_helper'

describe JsonDiff do
  it "should be able to diff two empty arrays" do
    diff = JsonDiff.diff([], [])
    expect(diff).to eql([])
  end

  it "should be able to diff an empty array with a filled one" do
    diff = JsonDiff.diff([], [1, 2, 3])
    expect(diff).to eql([
      {op: :add, path: "/0", value: 1},
      {op: :add, path: "/1", value: 2},
      {op: :add, path: "/2", value: 3},
    ])
  end

  it "should be able to diff a filled array with an empty one" do
    diff = JsonDiff.diff([1, 2, 3], [])
    expect(diff).to eql([
      {op: :remove, path: "/0", value: 1},
      {op: :remove, path: "/0", value: 2},
      {op: :remove, path: "/0", value: 3},
    ])
  end

  it "should be able to diff a 1-array with a filled one" do
    diff = JsonDiff.diff([0], [1, 2, 3])
    expect(diff).to eql([
      {op: :remove, path: "/0", value: 0},
      {op: :add, path: "/0", value: 1},
      {op: :add, path: "/1", value: 2},
      {op: :add, path: "/2", value: 3},
    ])
  end

  it "should be able to diff a filled array with a 1-array" do
    diff = JsonDiff.diff([1, 2, 3], [0])
    expect(diff).to eql([
      {op: :remove, path: "/2", value: 3},
      {op: :remove, path: "/1", value: 2},
      {op: :remove, path: "/0", value: 1},
      {op: :add, path: "/0", value: 0},
    ])
  end

  it "should be able to diff two integer arrays" do
    diff = JsonDiff.diff([1, 2, 3, 4, 5], [6, 4, 3, 2])
    expect(diff).to eql([
      {op: :remove, path: "/4", value: 5},
      {op: :remove, path: "/0", value: 1},
      {op: :move, from: "/0", path: "/2"},
      {op: :move, from: "/1", path: "/0"},
      {op: :add, path: "/0", value: 6},
    ])
  end
end
