defmodule Taper.View do
  use Phoenix.HTML

  def taper_meta_tag(conn, session_id \\ nil) do
    session_id =
      if session_id != nil,
        do: session_id,
        else: Base.encode64(:crypto.strong_rand_bytes(16), padding: false)

    token = Phoenix.Token.sign(conn, "taper-token", session_id)

    tag(:meta, name: "taper-token", content: token, charset: "utf-8")
  end

  def taper_render(module, template, assigns, opts \\ []) do
    content_tag(:div, module.render(template, assigns), Keyword.put_new(opts, :id, "taper"))
  end

  def taper_script() do
    content_tag(:script, "", type: "text/javascript", src: "/js/app.js")
  end
end
