# Instructions for installing Elixir

Running Elixir requires installing Erlang too.

We find [asdf](https://github.com/asdf-vm/asdf) to be the easiest way to get started.

1. [Install ASDF](https://github.com/asdf-vm/asdf) using instructions on [this page](https://asdf-vm.com/guide/getting-started.html)
2. [Install ASDF Erlang](https://github.com/asdf-vm/asdf-erlang)
3. [Install ASDF Elixir](https://github.com/asdf-vm/asdf-elixir)

Once you have asdf installed, add erlang and elixir:

```bash
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git

asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
```

And then install. You can use whichever versions you want, as long as Elixir version is 1.14 or greater. To
install the versions we've tested with (from `.tool-versions`):

```bash
asdf install
```

## Additional Resources

The [Phoenix Installation documentation](https://hexdocs.pm/phoenix/installation.html) is also a good resource to start with.

