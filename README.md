Excetera
========

Bindings for [etcd][1]'s HTTP API.

  [1]: https://github.com/coreos/etcd


## Usage

Add Excetera as a dependency to your project and modify the `:etcd_url`
config parameter to point to the location of your etcd instance:

```elixir
config :excetera, etcd_url: "http://my.host.name:4001/v2/keys"
```

Now you can fetch and set values:

```elixir
Excetera.set!("/test/key", "value")
Excetera.fetch!("/test/key")
#=> "value"

Excetera.delete!("/test/key")
Excetera.get("/test/key", "default")
#=> "default"
```

Apart from strings and values convertible to strings, Excetera supports some
other types:

```elixir
map = %{any: "elixir term", can: {'be', 'encoded'}}
Excetera.set!("/test/term", map, type: :term)
Excetera.fetch!("/test/term", type: :term)
#=> %{any: "elixir term", can: {'be', 'encoded'}}
```

You can also wait for new changes to arrive:

```elixir
spawn_link(fn ->
  IO.inspect Excetera.fetch!("/test/nokey", wait: true)
end)
Excetera.set!("/test/nokey", "hello")

# "hello" is printed to the console
```

## Documentation

The source code in `lib/excetera.ex` contains inline documentation of the API.
