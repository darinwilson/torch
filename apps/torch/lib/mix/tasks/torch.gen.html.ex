defmodule Mix.Tasks.Torch.Gen.Html do
  use Mix.Task

  def run(args) do
    {_opts, [namespace, singular, plural | attrs], _} = OptionParser.parse(args, switches: [])

    namespace_underscore = Macro.underscore(namespace)
    binding = Mix.Torch.inflect(namespace, singular)
    path = namespace_underscore <> "/" <> binding[:path]
    attrs = Mix.Torch.attrs(attrs)
    binding = binding ++ [plural: plural,
                          attrs: attrs,
                          configs: configs(attrs),
                          namespace: namespace,
                          namespace_underscore: namespace_underscore,
                          inputs: inputs(attrs)]

    Mix.Torch.copy_from [:torch], "priv/templates/eex", "", binding, [
      {:eex, "index.html.eex", "web/templates/#{path}/index.html.eex"},
      {:eex, "edit.html.eex", "web/templates/#{path}/edit.html.eex"},
      {:eex, "new.html.eex", "web/templates/#{path}/new.html.eex"},
      {:eex, "_form.html.eex", "web/templates/#{path}/_form.html.eex"},
      {:eex, "_filters.html.eex", "web/templates/#{path}/_filters.html.eex"}
    ]

    Mix.Torch.copy_from [:torch], "priv/templates/elixir", "", binding, [
      {:eex, "controller.ex", "web/controllers/#{path}_controller.ex"},
      {:eex, "view.ex", "web/views/#{path}_view.ex"}
    ]
  end

  defp inputs(attrs) do
    attrs = Enum.reject(attrs, fn({key, _type}) -> key in [:inserted_at, :updated_at] end)
    Enum.map attrs, fn
      {_, {:array, _}} ->
        {nil, nil, nil}
      {_, {:references, _}} ->
        {nil, nil, nil}
      {key, :integer}    ->
        {label(key), ~s(<%= number_input f, #{inspect(key)} %>), error(key)}
      {key, :float}      ->
        {label(key), ~s(<%= number_input f, #{inspect(key)}, step: "any" %>), error(key)}
      {key, :decimal}    ->
        {label(key), ~s(<%= number_input f, #{inspect(key)}, step: "any" %>), error(key)}
      {key, :boolean}    ->
        {label(key), ~s(<%= checkbox f, #{inspect(key)} %>), error(key)}
      {key, :text}       ->
        {label(key), ~s(<%= textarea f, #{inspect(key)} %>), error(key)}
      {key, :date}       ->
        {label(key), ~s(<%= date_select f, #{inspect(key)} %>), error(key)}
      {key, :time}       ->
        {label(key), ~s(<%= time_select f, #{inspect(key)} %>), error(key)}
      {key, :datetime}   ->
        {label(key), ~s(<%= datetime_select f, #{inspect(key)} %>), error(key)}
      {key, _}           ->
        {label(key), ~s(<%= text_input f, #{inspect(key)} %>), error(key)}
    end
  end

  defp configs(attrs) do
    attrs
    |> Enum.group_by(&group_key/1, &elem(&1, 0))
    |> Enum.map(&config/1)
  end

  defp config({:text, fields}) do
    "%Config{type: :text, keys: ~w(#{Enum.join(fields, " ")})}"
  end
  defp config({:date, fields}) do
    "%Config{type: :date, keys: ~w(#{Enum.join(fields, " ")}), options: %{format: \"{YYYY}-{0M}-{0D}\"}}"
  end

  defp group_key({_key, :string}), do: :text
  defp group_key({_key, type}), do: type

  defp label(key) do
    ~s(<%= label f, #{inspect(key)} %>)
  end

  defp error(field) do
    ~s(<%= error_tag f, #{inspect(field)} %>)
  end
end
