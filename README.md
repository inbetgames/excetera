Excetera
==========

Bindings for [etcd][1]'s HTTP API.

  [1]: https://github.com/coreos/etcd


## Usage

Add Excetera as a dependency to your project and modify the `:etcd_url`
config parameter to point to the location of your etcd instance:

```elixir
config :excetera, etcd_url: "http://my.host.name:4001/v2/keys"
```

Now you can fetch and set values:

```
:ok = Excetera.set "key", %{any: "elixir term", is: 'supported'}

Excetera.get "key", "default"
#=> %{any: "elixir term", is: 'supported'}

:ok = Excetera.delete "key"

Excetera.get "key", "default"
#=> "default"
```

You can also wait for new changes to arrive:

```elixir
{:error, :timeout} = Excetera.wait "non-existent", timeout: 1000
"default" = Excetera.wait "non-existent", "default", timeout: 1000
```
