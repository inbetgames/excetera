Diamorfosi
==========

Bindings for [etcd][1]'s HTTP API.

  [1]: https://github.com/coreos/etcd


## Usage

Add Diamorfosi as a dependency to your project and modify the `:etcd_url`
config parameter to point to the location of your etcd instance:

```elixir
config :diamorfosi, etcd_url: "http://my.host.name:4001/v2/keys"
```

Now you can fetch and set values:

```
:ok = Diamorfosi.set "key", %{any: "elixir term", is: 'supported'}

Diamorfosi.get "key", "default"
#=> %{any: "elixir term", is: 'supported'}

:ok = Diamorfosi.delete "key"

Diamorfosi.get "key", "default"
#=> "default"
```

You can also wait for new changes to arrive:

```elixir
{:error, :timeout} = Diamorfosi.wait "non-existent", timeout: 1000
"default" = Diamorfosi.wait "non-existent", "default", timeout: 1000
```
